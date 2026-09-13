CREATE PROCEDURE [dbo].[sp_OrganizationEntitlement_GetModules]
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF @OrganizationId IS NULL
        THROW 56101, 'OrganizationId is required.', 1;

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
    -- Effective entitlement matrix
    --
    -- If multiple active licenses contain the same module,
    -- take the union of the allowed actions.
    ------------------------------------------------------------

    SELECT
        M.[Id] AS [ModuleId],
        M.[Code] AS [ModuleCode],
        M.[Name] AS [ModuleName],

        CAST
        (
            MAX(CAST(LM.[DefaultCanCreate] AS TINYINT))
            AS BIT
        ) AS [CanCreate],

        CAST
        (
            MAX(CAST(LM.[DefaultCanUpdate] AS TINYINT))
            AS BIT
        ) AS [CanUpdate],

        CAST
        (
            MAX(CAST(LM.[DefaultCanDelete] AS TINYINT))
            AS BIT
        ) AS [CanDelete],

        CAST
        (
            MAX(CAST(LM.[DefaultCanRead] AS TINYINT))
            AS BIT
        ) AS [CanRead]

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
        M.[Id],
        M.[Code],
        M.[Name]

    ORDER BY
        M.[Name],
        M.[Code];
END;
GO