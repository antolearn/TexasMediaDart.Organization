CREATE PROCEDURE [dbo].[sp_OrganizationLicense_GetAll]
    @OrganizationId UNIQUEIDENTIFIER,
    @IncludeInactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @OrganizationId IS NULL
        THROW 56001, 'OrganizationId is required.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Organizations]
        WHERE [Id] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 56002,
            'The organization does not exist.',
            1;
    END;

    SELECT
        OL.[Id] AS [OrganizationLicenseId],
        OL.[OrganizationId],

        L.[Id] AS [LicenseId],
        L.[Code] AS [LicenseCode],
        L.[Name] AS [LicenseName],

        OL.[IsActive],
        OL.[StartUtc],
        OL.[EndUtc],

        CAST
        (
            CASE
                WHEN OL.[IsActive] = 1
                 AND L.[IsActive] = 1
                 AND OL.[StartUtc] <= SYSUTCDATETIME()
                 AND
                 (
                     OL.[EndUtc] IS NULL
                     OR OL.[EndUtc] > SYSUTCDATETIME()
                 )
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [IsCurrentlyEffective],

        OL.[CreatedBy],
        OL.[CreatedUtc],
        OL.[ModifiedBy],
        OL.[ModifiedUtc]

    FROM [dbo].[OrganizationLicenses] OL

    INNER JOIN [dbo].[Licenses] L
        ON L.[Id] = OL.[LicenseId]

    WHERE OL.[OrganizationId] = @OrganizationId
      AND
      (
          @IncludeInactive = 1
          OR
          (
              OL.[IsActive] = 1
              AND L.[IsActive] = 1
              AND OL.[StartUtc] <= SYSUTCDATETIME()
              AND
              (
                  OL.[EndUtc] IS NULL
                  OR OL.[EndUtc] > SYSUTCDATETIME()
              )
          )
      )

    ORDER BY
        L.[Name],
        L.[Code];
END;
GO