CREATE PROCEDURE [dbo].[sp_UserPermission_GetEffective]
    @OrganizationId UNIQUEIDENTIFIER,
    @IdentityUserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @OrganizationUserId BIGINT,
        @NowUtc DATETIME2(7) = SYSUTCDATETIME(),
        @HasApprovalFeature BIT = 0;

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 56301, 'OrganizationId is required.', 1;
    END;

    IF @IdentityUserId IS NULL
    BEGIN
        THROW 56302, 'IdentityUserId is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify organization
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Organizations]
        WHERE [Id] = @OrganizationId
          AND [IsActive] = 1
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 56303,
            'The organization does not exist or is inactive.',
            1;
    END;

    ------------------------------------------------------------
    -- Resolve OrganizationUser
    --
    -- Effective permissions are available only to an
    -- active and approved organization user.
    ------------------------------------------------------------

    SELECT
        @OrganizationUserId = OU.[Id]
    FROM [dbo].[OrganizationUsers] OU
    WHERE OU.[OrganizationId] = @OrganizationId
      AND OU.[IdentityUserId] = @IdentityUserId
      AND OU.[IsActive] = 1
      AND OU.[IsApproved] = 1;

    IF @OrganizationUserId IS NULL
    BEGIN
        THROW 56304,
            'The user is not an active and approved member of this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Determine whether organization has approval capability.
    --
    -- Approval requires:
    --
    --   1. Active WORKFLOW license
    --   2. APPROVALS module mapped to WORKFLOW
    --   3. APPROVALS module active
    --
    -- This enables approval functionality at organization level.
    -- It does NOT by itself grant CanApprove to the user.
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
    -- Effective organization entitlement
    --
    -- Multiple licenses can contain the same module.
    -- Use MAX to create the organization's maximum entitlement.
    ------------------------------------------------------------

    ;WITH Entitlements AS
    (
        SELECT
            LM.[ModuleId],

            CAST
            (
                MAX(CAST(LM.[DefaultCanCreate] AS TINYINT))
                AS BIT
            ) AS [AllowedCanCreate],

            CAST
            (
                MAX(CAST(LM.[DefaultCanUpdate] AS TINYINT))
                AS BIT
            ) AS [AllowedCanUpdate],

            CAST
            (
                MAX(CAST(LM.[DefaultCanDelete] AS TINYINT))
                AS BIT
            ) AS [AllowedCanDelete],

            CAST
            (
                MAX(CAST(LM.[DefaultCanRead] AS TINYINT))
                AS BIT
            ) AS [AllowedCanRead]

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
            LM.[ModuleId]
    ),

    ------------------------------------------------------------
    -- Combine permissions from all active + approved roles.
    --
    -- Roles are additive:
    --
    -- Role A ORDER.CanRead    = 1
    -- Role B ORDER.CanApprove = 1
    --
    -- Effective role permissions:
    --
    -- ORDER.CanRead    = 1
    -- ORDER.CanApprove = 1
    ------------------------------------------------------------

    UserRolePermissions AS
    (
        SELECT
            RP.[ModuleId],

            CAST
            (
                MAX(CAST(RP.[CanCreate] AS TINYINT))
                AS BIT
            ) AS [RoleCanCreate],

            CAST
            (
                MAX(CAST(RP.[CanUpdate] AS TINYINT))
                AS BIT
            ) AS [RoleCanUpdate],

            CAST
            (
                MAX(CAST(RP.[CanDelete] AS TINYINT))
                AS BIT
            ) AS [RoleCanDelete],

            CAST
            (
                MAX(CAST(RP.[CanRead] AS TINYINT))
                AS BIT
            ) AS [RoleCanRead],

            CAST
            (
                MAX(CAST(RP.[CanApprove] AS TINYINT))
                AS BIT
            ) AS [RoleCanApprove]

        FROM [dbo].[UserRoles] UR

        INNER JOIN [dbo].[Roles] R
            ON R.[Id] = UR.[RoleId]

        INNER JOIN [dbo].[RolePermissions] RP
            ON RP.[RoleId] = R.[Id]

        WHERE UR.[OrganizationUserId] = @OrganizationUserId

          AND R.[OrganizationId] = @OrganizationId

          AND R.[IsActive] = 1
          AND R.[IsDeleted] = 0
          AND R.[IsApproved] = 1

        GROUP BY
            RP.[ModuleId]
    )

    ------------------------------------------------------------
    -- Final effective permission matrix
    --
    -- CRUD/read:
    --
    --   license entitlement
    --       AND module supports action
    --       AND role grants action
    --
    -- Approve:
    --
    --   business module is entitled
    --       AND module supports approval
    --       AND WORKFLOW/APPROVALS is active
    --       AND role grants approval
    ------------------------------------------------------------

    SELECT
        @OrganizationUserId AS [OrganizationUserId],
        @IdentityUserId AS [IdentityUserId],

        M.[Id] AS [ModuleId],
        M.[Code] AS [ModuleCode],
        M.[Name] AS [ModuleName],

        --------------------------------------------------------
        -- Effective Create
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN E.[AllowedCanCreate] = 1
                 AND M.[SupportsCreate] = 1
                 AND ISNULL(URP.[RoleCanCreate], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanCreate],

        --------------------------------------------------------
        -- Effective Update
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN E.[AllowedCanUpdate] = 1
                 AND M.[SupportsUpdate] = 1
                 AND ISNULL(URP.[RoleCanUpdate], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanUpdate],

        --------------------------------------------------------
        -- Effective Delete
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN E.[AllowedCanDelete] = 1
                 AND M.[SupportsDelete] = 1
                 AND ISNULL(URP.[RoleCanDelete], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanDelete],

        --------------------------------------------------------
        -- Effective Read
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN E.[AllowedCanRead] = 1
                 AND M.[SupportsRead] = 1
                 AND ISNULL(URP.[RoleCanRead], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanRead],

        --------------------------------------------------------
        -- Effective Approve
        --
        -- Approval is a cross-license capability.
        -- It is not derived from LicenseModules.
        --
        -- Effective approval requires:
        --
        -- business module entitlement
        --     + SupportsApprove
        --     + WORKFLOW / APPROVALS
        --     + role CanApprove
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN M.[SupportsApprove] = 1
                 AND @HasApprovalFeature = 1
                 AND ISNULL(URP.[RoleCanApprove], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanApprove]

    FROM Entitlements E

    INNER JOIN [dbo].[Modules] M
        ON M.[Id] = E.[ModuleId]

    LEFT JOIN UserRolePermissions URP
        ON URP.[ModuleId] = E.[ModuleId]

    WHERE M.[IsActive] = 1

    ORDER BY
        M.[Name],
        M.[Code];
END;
GO