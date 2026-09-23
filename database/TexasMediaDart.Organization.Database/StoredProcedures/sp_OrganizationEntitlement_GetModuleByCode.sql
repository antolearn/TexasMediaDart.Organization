CREATE PROCEDURE [dbo].[sp_OrganizationEntitlement_GetModuleByCode]
    @OrganizationId UNIQUEIDENTIFIER,
    @ModuleCode NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @NormalizedModuleCode NVARCHAR(100),
        @NowUtc DATETIME2(7) = SYSUTCDATETIME(),
        @HasApprovalFeature BIT = 0;

    ------------------------------------------------------------
    -- Normalize
    ------------------------------------------------------------

    SET @NormalizedModuleCode =
        UPPER(NULLIF(LTRIM(RTRIM(@ModuleCode)), ''));

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 56201, 'OrganizationId is required.', 1;
    END;

    IF @NormalizedModuleCode IS NULL
    BEGIN
        THROW 56202, 'ModuleCode is required.', 1;
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
        THROW 56203,
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
    -- Build entitlement for requested module.
    --
    -- Multiple licenses may theoretically contain the same
    -- module, so take the union of their allowed actions.
    ------------------------------------------------------------

    ;WITH ModuleEntitlement AS
    (
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

            M.[SupportsCreate],
            M.[SupportsRead],
            M.[SupportsUpdate],
            M.[SupportsDelete],
            M.[SupportsApprove],

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

          AND UPPER(M.[Code]) = @NormalizedModuleCode

          AND OL.[StartUtc] <= @NowUtc

          AND
          (
              OL.[EndUtc] IS NULL
              OR OL.[EndUtc] > @NowUtc
          )

        GROUP BY
            M.[Id],
            M.[Code],
            M.[Name],
            M.[Description],
            M.[Route],
            M.[IconKey],
            M.[MenuGroup],
            M.[DisplayOrder],
            M.[ShowInMenu],
            M.[SupportsCreate],
            M.[SupportsRead],
            M.[SupportsUpdate],
            M.[SupportsDelete],
            M.[SupportsApprove]
    )

    ------------------------------------------------------------
    -- Return effective organization entitlement
    ------------------------------------------------------------

    SELECT
        E.[ModuleId],
        E.[ModuleCode],
        E.[ModuleName],

        E.[Description],
        E.[Route],
        E.[IconKey],
        E.[MenuGroup],
        E.[DisplayOrder],
        E.[ShowInMenu],

        --------------------------------------------------------
        -- Module capability metadata
        --------------------------------------------------------

        E.[SupportsCreate],
        E.[SupportsRead],
        E.[SupportsUpdate],
        E.[SupportsDelete],
        E.[SupportsApprove],

        --------------------------------------------------------
        -- Effective CRUD/read entitlement
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN E.[AllowedCanCreate] = 1
                 AND E.[SupportsCreate] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanCreate],

        CAST
        (
            CASE
                WHEN E.[AllowedCanUpdate] = 1
                 AND E.[SupportsUpdate] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanUpdate],

        CAST
        (
            CASE
                WHEN E.[AllowedCanDelete] = 1
                 AND E.[SupportsDelete] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanDelete],

        CAST
        (
            CASE
                WHEN E.[AllowedCanRead] = 1
                 AND E.[SupportsRead] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanRead],

        --------------------------------------------------------
        -- Effective approval entitlement
        --
        -- Approval is a cross-license capability:
        --
        -- requested business module is licensed
        --     +
        -- module SupportsApprove
        --     +
        -- WORKFLOW / APPROVALS active
        --------------------------------------------------------

        CAST
        (
            CASE
                WHEN E.[SupportsApprove] = 1
                 AND @HasApprovalFeature = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanApprove]

    FROM ModuleEntitlement E;
END;
GO