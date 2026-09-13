CREATE PROCEDURE [dbo].[sp_OrganizationEntitlement_GetModuleByCode]
    @OrganizationId UNIQUEIDENTIFIER,
    @ModuleCode NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NormalizedModuleCode NVARCHAR(50);

    SET @NormalizedModuleCode =
        UPPER(NULLIF(LTRIM(RTRIM(@ModuleCode)), ''));

    IF @OrganizationId IS NULL
        THROW 56201, 'OrganizationId is required.', 1;

    IF @NormalizedModuleCode IS NULL
        THROW 56202, 'ModuleCode is required.', 1;

    ------------------------------------------------------------
    -- Return effective entitlement for one module
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

      AND UPPER(M.[Code]) = @NormalizedModuleCode

      AND OL.[StartUtc] <= SYSUTCDATETIME()

      AND
      (
          OL.[EndUtc] IS NULL
          OR OL.[EndUtc] > SYSUTCDATETIME()
      )

    GROUP BY
        M.[Id],
        M.[Code],
        M.[Name];
END;
GO