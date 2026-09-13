CREATE PROCEDURE [dbo].[sp_Role_UpdatePermissions]
    @RoleId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @Permissions [dbo].[RolePermissionInputType] READONLY,
    @ModifiedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);

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
        -- Build current entitlement matrix
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

          AND OL.[StartUtc] <= SYSUTCDATETIME()

          AND
          (
              OL.[EndUtc] IS NULL
              OR OL.[EndUtc] > SYSUTCDATETIME()
          )

        GROUP BY
            LM.[ModuleId];

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
        -- Requested permissions cannot exceed license entitlement
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
            RP.[CanCreate] = P.[CanCreate],
            RP.[CanUpdate] = P.[CanUpdate],
            RP.[CanDelete] = P.[CanDelete],
            RP.[CanRead] = P.[CanRead],

            RP.[ModifiedBy] = @AuditEmail,
            RP.[ModifiedUtc] = SYSUTCDATETIME()

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

            [CreatedBy]
        )
        SELECT
            @RoleId,
            P.[ModuleId],

            P.[CanCreate],
            P.[CanUpdate],
            P.[CanDelete],
            P.[CanRead],

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
    -- Return resulting role permission matrix
    ------------------------------------------------------------

    SELECT
        RP.[RoleId],

        M.[Id] AS [ModuleId],
        M.[Code] AS [ModuleCode],
        M.[Name] AS [ModuleName],

        RP.[CanCreate],
        RP.[CanUpdate],
        RP.[CanDelete],
        RP.[CanRead],

        RP.[CreatedBy],
        RP.[CreatedUtc],
        RP.[ModifiedBy],
        RP.[ModifiedUtc]

    FROM [dbo].[RolePermissions] RP

    INNER JOIN [dbo].[Modules] M
        ON M.[Id] = RP.[ModuleId]

    WHERE RP.[RoleId] = @RoleId

    ORDER BY
        M.[Name],
        M.[Code];
END;
GO