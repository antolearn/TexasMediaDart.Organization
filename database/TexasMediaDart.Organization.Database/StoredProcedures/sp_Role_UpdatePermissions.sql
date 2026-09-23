CREATE PROCEDURE [dbo].[sp_Role_UpdatePermissions]
    @RoleId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @Permissions [dbo].[RolePermissionInputType] READONLY,
    @ModifiedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @AuditEmail NVARCHAR(100),
        @NowUtc DATETIME2(7) = SYSUTCDATETIME(),
        @HasApprovalFeature BIT = 0;

    ------------------------------------------------------------
    -- Normalize audit email
    ------------------------------------------------------------

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@ModifiedBy)));

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @RoleId IS NULL
    BEGIN
        THROW 54601, 'RoleId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 54602, 'OrganizationId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 54603, 'Authenticated user email is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify role
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [Id] = @RoleId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 54604,
            'The role does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Protect Owner and other system roles
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [Id] = @RoleId
          AND [OrganizationId] = @OrganizationId
          AND [IsSystemRole] = 1
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 54605,
            'Permissions for system roles cannot be modified through ordinary role management.',
            1;
    END;

    BEGIN TRY

        BEGIN TRANSACTION;

        ------------------------------------------------------------
        -- Build current organization entitlement matrix
        --
        -- Create / Update / Delete / Read are derived from the
        -- organization's active license/module entitlements.
        --
        -- Approval is intentionally handled separately because
        -- approval requires the WORKFLOW / APPROVALS capability.
        ------------------------------------------------------------

        DECLARE @Entitlements TABLE
        (
            [ModuleId] INT NOT NULL PRIMARY KEY,

            [AllowedCanCreate] BIT NOT NULL,
            [AllowedCanUpdate] BIT NOT NULL,
            [AllowedCanDelete] BIT NOT NULL,
            [AllowedCanRead]   BIT NOT NULL
        );

        INSERT INTO @Entitlements
        (
            [ModuleId],
            [AllowedCanCreate],
            [AllowedCanUpdate],
            [AllowedCanDelete],
            [AllowedCanRead]
        )
        SELECT
            LM.[ModuleId],

            CAST(MAX(CAST(LM.[DefaultCanCreate] AS TINYINT)) AS BIT),
            CAST(MAX(CAST(LM.[DefaultCanUpdate] AS TINYINT)) AS BIT),
            CAST(MAX(CAST(LM.[DefaultCanDelete] AS TINYINT)) AS BIT),
            CAST(MAX(CAST(LM.[DefaultCanRead] AS TINYINT)) AS BIT)

        FROM [dbo].[OrganizationLicenses] OL

        INNER JOIN [dbo].[Licenses] L
            ON L.[Id] = OL.[LicenseId]

        INNER JOIN [dbo].[LicenseModules] LM
            ON LM.[LicenseId] = OL.[LicenseId]

        INNER JOIN [dbo].[Modules] M
            ON M.[Id] = LM.[ModuleId]

        WHERE OL.[OrganizationId] = @OrganizationId
          AND OL.[IsActive] = 1
          AND L.[IsActive] = 1
          AND M.[IsActive] = 1
          AND OL.[StartUtc] <= @NowUtc
          AND
          (
              OL.[EndUtc] IS NULL
              OR OL.[EndUtc] > @NowUtc
          )

        GROUP BY
            LM.[ModuleId];

        ------------------------------------------------------------
        -- Determine whether organization has approval capability
        --
        -- Approval requires:
        --
        --   1. Active WORKFLOW license
        --   2. Active APPROVALS module
        --   3. APPROVALS mapped to WORKFLOW
        --
        -- This enables approval functionality at the organization
        -- level. It does NOT by itself grant approval permission
        -- to any role.
        ------------------------------------------------------------

        IF EXISTS
        (
            SELECT 1

            FROM [dbo].[OrganizationLicenses] OL

            INNER JOIN [dbo].[Licenses] L
                ON L.[Id] = OL.[LicenseId]

            INNER JOIN [dbo].[LicenseModules] LM
                ON LM.[LicenseId] = L.[Id]

            INNER JOIN [dbo].[Modules] M
                ON M.[Id] = LM.[ModuleId]

            WHERE OL.[OrganizationId] = @OrganizationId

              AND L.[Code] = N'WORKFLOW'
              AND L.[IsActive] = 1

              AND OL.[IsActive] = 1
              AND OL.[StartUtc] <= @NowUtc
              AND
              (
                  OL.[EndUtc] IS NULL
                  OR OL.[EndUtc] > @NowUtc
              )

              AND M.[Code] = N'APPROVALS'
              AND M.[IsActive] = 1
        )
        BEGIN
            SET @HasApprovalFeature = 1;
        END;

        ------------------------------------------------------------
        -- Every supplied ModuleId must be entitled
        ------------------------------------------------------------

        IF EXISTS
        (
            SELECT 1

            FROM @Permissions P

            LEFT JOIN @Entitlements E
                ON E.[ModuleId] = P.[ModuleId]

            WHERE E.[ModuleId] IS NULL
        )
        BEGIN
            THROW 54606,
                'One or more modules are not licensed for this organization.',
                1;
        END;

        ------------------------------------------------------------
        -- Requested CRUD/read permissions cannot exceed the
        -- organization's license entitlement.
        ------------------------------------------------------------

        IF EXISTS
        (
            SELECT 1

            FROM @Permissions P

            INNER JOIN @Entitlements E
                ON E.[ModuleId] = P.[ModuleId]

            WHERE
                   (P.[CanCreate] = 1 AND E.[AllowedCanCreate] = 0)
                OR (P.[CanUpdate] = 1 AND E.[AllowedCanUpdate] = 0)
                OR (P.[CanDelete] = 1 AND E.[AllowedCanDelete] = 0)
                OR (P.[CanRead]   = 1 AND E.[AllowedCanRead]   = 0)
        )
        BEGIN
            THROW 54607,
                'One or more requested permissions exceed the organization license entitlement.',
                1;
        END;

        ------------------------------------------------------------
        -- Requested permissions must also be supported by module.
        --
        -- License entitlement and module capability are separate:
        --
        -- License = organization may use the feature
        -- Supports* = action makes sense for this module
        ------------------------------------------------------------

        IF EXISTS
        (
            SELECT 1

            FROM @Permissions P

            INNER JOIN [dbo].[Modules] M
                ON M.[Id] = P.[ModuleId]

            WHERE
                   (P.[CanCreate]  = 1 AND M.[SupportsCreate]  = 0)
                OR (P.[CanUpdate]  = 1 AND M.[SupportsUpdate]  = 0)
                OR (P.[CanDelete]  = 1 AND M.[SupportsDelete]  = 0)
                OR (P.[CanRead]    = 1 AND M.[SupportsRead]    = 0)
                OR (P.[CanApprove] = 1 AND M.[SupportsApprove] = 0)
        )
        BEGIN
            THROW 54608,
                'One or more requested permissions are not supported by the module.',
                1;
        END;

        ------------------------------------------------------------
        -- Approval requires WORKFLOW / APPROVALS entitlement.
        --
        -- Example:
        --
        -- ORDER.SupportsApprove = 1
        -- SALES licensed        = 1
        -- WORKFLOW licensed     = 1
        -- APPROVALS available   = 1
        --
        -- Only then may ORDER.CanApprove be assigned to a role.
        ------------------------------------------------------------

        IF @HasApprovalFeature = 0
           AND EXISTS
           (
               SELECT 1
               FROM @Permissions
               WHERE [CanApprove] = 1
           )
        BEGIN
            THROW 54609,
                'Approval permission requires the Workflow approval feature for this organization.',
                1;
        END;

        ------------------------------------------------------------
        -- Remove role permissions omitted from submitted matrix.
        --
        -- @Permissions represents the complete desired permission
        -- state for this role.
        ------------------------------------------------------------

        DELETE RP

        FROM [dbo].[RolePermissions] RP

        WHERE RP.[RoleId] = @RoleId

          AND NOT EXISTS
          (
              SELECT 1
              FROM @Permissions P
              WHERE P.[ModuleId] = RP.[ModuleId]
          );

        ------------------------------------------------------------
        -- Update existing permission rows
        ------------------------------------------------------------

        UPDATE RP
        SET
            RP.[CanCreate]   = P.[CanCreate],
            RP.[CanUpdate]   = P.[CanUpdate],
            RP.[CanDelete]   = P.[CanDelete],
            RP.[CanRead]     = P.[CanRead],
            RP.[CanApprove]  = P.[CanApprove],

            RP.[ModifiedBy]  = @AuditEmail,
            RP.[ModifiedUtc] = @NowUtc

        FROM [dbo].[RolePermissions] RP

        INNER JOIN @Permissions P
            ON P.[ModuleId] = RP.[ModuleId]

        WHERE RP.[RoleId] = @RoleId;

        ------------------------------------------------------------
        -- Insert new permission rows
        ------------------------------------------------------------

        INSERT INTO [dbo].[RolePermissions]
        (
            [RoleId],
            [ModuleId],

            [CanCreate],
            [CanUpdate],
            [CanDelete],
            [CanRead],
            [CanApprove],

            [CreatedBy]
        )
        SELECT
            @RoleId,
            P.[ModuleId],

            P.[CanCreate],
            P.[CanUpdate],
            P.[CanDelete],
            P.[CanRead],
            P.[CanApprove],

            @AuditEmail

        FROM @Permissions P

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM [dbo].[RolePermissions] RP
            WHERE RP.[RoleId] = @RoleId
              AND RP.[ModuleId] = P.[ModuleId]
        );

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Return complete resulting role permission matrix
    --
    -- Keep PUT response consistent with
    -- GET /api/roles/{roleId}/permissions.
    ------------------------------------------------------------

    EXEC [dbo].[sp_Role_GetPermissions]
        @RoleId = @RoleId,
        @OrganizationId = @OrganizationId;

END;
GO