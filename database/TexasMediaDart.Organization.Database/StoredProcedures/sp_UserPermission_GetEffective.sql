CREATE PROCEDURE [dbo].[sp_UserPermission_GetEffective]
    @OrganizationId UNIQUEIDENTIFIER,
    @IdentityUserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OrganizationUserId BIGINT;

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

          AND OL.[StartUtc] <= SYSUTCDATETIME()

          AND
          (
              OL.[EndUtc] IS NULL
              OR OL.[EndUtc] > SYSUTCDATETIME()
          )

        GROUP BY
            LM.[ModuleId]
    ),

    ------------------------------------------------------------
    -- Combine permissions from all active + approved roles
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
            ) AS [RoleCanRead]

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
    -- Effective permission =
    -- entitlement AND role permission
    ------------------------------------------------------------

    SELECT
        @OrganizationUserId AS [OrganizationUserId],
        @IdentityUserId AS [IdentityUserId],

        M.[Id] AS [ModuleId],
        M.[Code] AS [ModuleCode],
        M.[Name] AS [ModuleName],

        CAST
        (
            CASE
                WHEN E.[AllowedCanCreate] = 1
                 AND ISNULL(URP.[RoleCanCreate], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanCreate],

        CAST
        (
            CASE
                WHEN E.[AllowedCanUpdate] = 1
                 AND ISNULL(URP.[RoleCanUpdate], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanUpdate],

        CAST
        (
            CASE
                WHEN E.[AllowedCanDelete] = 1
                 AND ISNULL(URP.[RoleCanDelete], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanDelete],

        CAST
        (
            CASE
                WHEN E.[AllowedCanRead] = 1
                 AND ISNULL(URP.[RoleCanRead], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanRead]

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