CREATE PROCEDURE [dbo].[sp_OrganizationEntitlement_GetModules]
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @NowUtc DATETIME2(7) = SYSUTCDATETIME(),
        @HasApprovalFeature BIT = 0;

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 56101, 'OrganizationId is required.', 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Organizations]
        WHERE [Id] = @OrganizationId
          AND [IsActive] = 1
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 56102,
            'The organization does not exist or is inactive.',
            1;
    END;

    ------------------------------------------------------------
    -- Determine whether organization has approval capability
    --
    -- Approval requires:
    --
    --   Active WORKFLOW license
    --       +
    --   APPROVALS module mapped to WORKFLOW
    --       +
    --   Active APPROVALS module
    --
    -- This enables approval capability for business modules
    -- that have SupportsApprove = 1.
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
    -- Effective organization entitlement matrix
    --
    -- If multiple active licenses contain the same module,
    -- take the union of the allowed actions.
    --
    -- CRUD/read entitlement:
    --
    --   LicenseModules.DefaultCan*
    --       AND
    --   Modules.Supports*
    --
    -- Approval entitlement:
    --
    --   Module is licensed
    --       AND
    --   Modules.SupportsApprove
    --       AND
    --   WORKFLOW / APPROVALS feature is active
    ------------------------------------------------------------

    ;WITH EntitledModules AS
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
    )

    SELECT
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
        -- Module capability metadata
        --------------------------------------------------------

        M.[SupportsCreate],
        M.[SupportsRead],
        M.[SupportsUpdate],
        M.[SupportsDelete],
        M.[SupportsApprove],

        --------------------------------------------------------
        -- Effective organization entitlement
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN E.[AllowedCanCreate] = 1
                 AND M.[SupportsCreate] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanCreate],

        CAST
        (
            CASE
                WHEN E.[AllowedCanUpdate] = 1
                 AND M.[SupportsUpdate] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanUpdate],

        CAST
        (
            CASE
                WHEN E.[AllowedCanDelete] = 1
                 AND M.[SupportsDelete] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanDelete],

        CAST
        (
            CASE
                WHEN E.[AllowedCanRead] = 1
                 AND M.[SupportsRead] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanRead],

        --------------------------------------------------------
        -- Approval is a cross-license entitlement.
        --
        -- Example:
        --
        -- SALES → ORDER
        -- ORDER.SupportsApprove = 1
        -- WORKFLOW → APPROVALS
        --
        -- Therefore ORDER.CanApprove = 1.
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN M.[SupportsApprove] = 1
                 AND @HasApprovalFeature = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanApprove]

    FROM EntitledModules E

    INNER JOIN [dbo].[Modules] M
        ON M.[Id] = E.[ModuleId]

    WHERE M.[IsActive] = 1

    ORDER BY
        M.[DisplayOrder],
        M.[Name];
END;
GO