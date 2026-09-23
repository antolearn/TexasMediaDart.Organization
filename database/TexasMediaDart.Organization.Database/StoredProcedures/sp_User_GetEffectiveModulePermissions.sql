CREATE PROCEDURE [dbo].[sp_User_GetEffectiveModulePermissions]
(
    @IdentityUserId UNIQUEIDENTIFIER
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @NowUtc DATETIME2(7) = SYSUTCDATETIME();

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @IdentityUserId IS NULL
    BEGIN
        THROW 56501, 'IdentityUserId is required.', 1;
    END;

    ------------------------------------------------------------
    -- Build effective module permissions.
    --
    -- Permission model:
    --
    -- CRUD / Read:
    --
    --   Active organization license
    --       AND module entitlement
    --       AND module Supports*
    --       AND active + approved role permission
    --
    -- Approve:
    --
    --   Business module entitlement
    --       AND module SupportsApprove
    --       AND active WORKFLOW / APPROVALS feature
    --       AND active + approved role CanApprove
    ------------------------------------------------------------

    ;WITH EntitledModules AS
    (
        --------------------------------------------------------
        -- Determine modules entitled to each organization.
        --
        -- Multiple licenses may theoretically contain the same
        -- module, so aggregate the maximum allowed permission.
        --------------------------------------------------------

        SELECT
            OL.[OrganizationId],
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

        WHERE OL.[IsActive] = 1
          AND L.[IsActive] = 1
          AND M.[IsActive] = 1

          AND OL.[StartUtc] <= @NowUtc

          AND
          (
              OL.[EndUtc] IS NULL
              OR OL.[EndUtc] > @NowUtc
          )

        GROUP BY
            OL.[OrganizationId],
            LM.[ModuleId]
    ),

    ApprovalFeatures AS
    (
        --------------------------------------------------------
        -- Organizations with active WORKFLOW / APPROVALS.
        --
        -- One row per organization.
        --------------------------------------------------------

        SELECT DISTINCT
            OL.[OrganizationId]

        FROM [dbo].[OrganizationLicenses] OL

        INNER JOIN [dbo].[Licenses] L
            ON L.[Id] = OL.[LicenseId]

        INNER JOIN [dbo].[LicenseModules] LM
            ON LM.[LicenseId] = L.[Id]

        INNER JOIN [dbo].[Modules] M
            ON M.[Id] = LM.[ModuleId]

        WHERE L.[Code] = N'WORKFLOW'
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
    ),

    UserRolePermissions AS
    (
        --------------------------------------------------------
        -- Aggregate permissions from every active + approved
        -- role assigned to the organization user.
        --
        -- Roles are additive.
        --------------------------------------------------------

        SELECT
            OU.[OrganizationId],
            OU.[Id] AS [OrganizationUserId],
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

        FROM [dbo].[OrganizationUsers] OU

        INNER JOIN [dbo].[UserRoles] UR
            ON UR.[OrganizationUserId] = OU.[Id]

        INNER JOIN [dbo].[Roles] R
            ON R.[Id] = UR.[RoleId]
           AND R.[OrganizationId] = OU.[OrganizationId]

        INNER JOIN [dbo].[RolePermissions] RP
            ON RP.[RoleId] = R.[Id]

        WHERE OU.[IdentityUserId] = @IdentityUserId

          AND OU.[IsActive] = 1
          AND OU.[IsApproved] = 1

          AND R.[IsActive] = 1
          AND R.[IsDeleted] = 0
          AND R.[IsApproved] = 1

        GROUP BY
            OU.[OrganizationId],
            OU.[Id],
            RP.[ModuleId]
    )

    ------------------------------------------------------------
    -- Final effective module permission matrix
    ------------------------------------------------------------

    SELECT
        OU.[OrganizationId],
        OU.[Id] AS [OrganizationUserId],

        M.[Id] AS [ModuleId],
        M.[Code] AS [ModuleCode],
        M.[Name] AS [ModuleName],
        M.[Description],
        M.[Route],
        M.[IconKey],
        M.[MenuGroup],
        M.[DisplayOrder],
        M.[ShowInMenu],

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
        -- It requires:
        --
        --   business module entitlement
        --       +
        --   SupportsApprove
        --       +
        --   WORKFLOW / APPROVALS
        --       +
        --   role CanApprove
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN M.[SupportsApprove] = 1
                 AND AF.[OrganizationId] IS NOT NULL
                 AND ISNULL(URP.[RoleCanApprove], 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanApprove]

    FROM [dbo].[OrganizationUsers] OU

    INNER JOIN EntitledModules E
        ON E.[OrganizationId] = OU.[OrganizationId]

    INNER JOIN [dbo].[Modules] M
        ON M.[Id] = E.[ModuleId]
       AND M.[IsActive] = 1

    LEFT JOIN UserRolePermissions URP
        ON URP.[OrganizationId] = OU.[OrganizationId]
       AND URP.[OrganizationUserId] = OU.[Id]
       AND URP.[ModuleId] = M.[Id]

    LEFT JOIN ApprovalFeatures AF
        ON AF.[OrganizationId] = OU.[OrganizationId]

    WHERE OU.[IdentityUserId] = @IdentityUserId
      AND OU.[IsActive] = 1
      AND OU.[IsApproved] = 1

    ORDER BY
        M.[DisplayOrder],
        M.[Name];
END;
GO