CREATE PROCEDURE [dbo].[sp_Contact_Search]
    @OrganizationId UNIQUEIDENTIFIER,

    @SearchText NVARCHAR(200) = NULL,
    @IsActive BIT = NULL,

    @PageNumber INT = 1,
    @PageSize INT = 25
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 51401, 'OrganizationId is required.', 1;
    END;

    IF @PageNumber < 1
    BEGIN
        THROW 51402, 'PageNumber must be greater than or equal to 1.', 1;
    END;

    IF @PageSize < 1 OR @PageSize > 200
    BEGIN
        THROW 51403, 'PageSize must be between 1 and 200.', 1;
    END;

    ------------------------------------------------------------
    -- Normalize search
    ------------------------------------------------------------

    SET @SearchText =
        NULLIF(LTRIM(RTRIM(@SearchText)), '');

    DECLARE @Offset INT =
        (@PageNumber - 1) * @PageSize;

    ------------------------------------------------------------
    -- Result set 1:
    -- Paged contacts
    ------------------------------------------------------------

    SELECT
        [Id],
        [OrganizationId],

        [FirstName],
        [MiddleName],
        [LastName],
        [CompanyName],

        [Email],
        [NormalizedEmail],

        [Phone],
        [MobilePhone],

        [AddressLine1],
        [AddressLine2],
        [City],
        [StateProvince],
        [PostalCode],
        [Country],

        [Notes],

        [IsActive],
        [IsDeleted],

        [CreatedBy],
        [CreatedUtc],
        [ModifiedBy],
        [ModifiedUtc]

    FROM [dbo].[Contacts]
    WHERE [OrganizationId] = @OrganizationId
      AND [IsDeleted] = 0

      AND
      (
          @IsActive IS NULL
          OR [IsActive] = @IsActive
      )

      AND
      (
          @SearchText IS NULL

          OR [FirstName] LIKE '%' + @SearchText + '%'
          OR [MiddleName] LIKE '%' + @SearchText + '%'
          OR [LastName] LIKE '%' + @SearchText + '%'
          OR [CompanyName] LIKE '%' + @SearchText + '%'
          OR [Email] LIKE '%' + @SearchText + '%'
          OR [Phone] LIKE '%' + @SearchText + '%'
          OR [MobilePhone] LIKE '%' + @SearchText + '%'
          OR [City] LIKE '%' + @SearchText + '%'
          OR [StateProvince] LIKE '%' + @SearchText + '%'
          OR [PostalCode] LIKE '%' + @SearchText + '%'
          OR [Country] LIKE '%' + @SearchText + '%'
      )

    ORDER BY
        [LastName],
        [FirstName],
        [CompanyName],
        [Id]

    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    ------------------------------------------------------------
    -- Result set 2:
    -- Total matching row count
    ------------------------------------------------------------

    SELECT
        COUNT_BIG(1) AS [TotalCount]

    FROM [dbo].[Contacts]
    WHERE [OrganizationId] = @OrganizationId
      AND [IsDeleted] = 0

      AND
      (
          @IsActive IS NULL
          OR [IsActive] = @IsActive
      )

      AND
      (
          @SearchText IS NULL

          OR [FirstName] LIKE '%' + @SearchText + '%'
          OR [MiddleName] LIKE '%' + @SearchText + '%'
          OR [LastName] LIKE '%' + @SearchText + '%'
          OR [CompanyName] LIKE '%' + @SearchText + '%'
          OR [Email] LIKE '%' + @SearchText + '%'
          OR [Phone] LIKE '%' + @SearchText + '%'
          OR [MobilePhone] LIKE '%' + @SearchText + '%'
          OR [City] LIKE '%' + @SearchText + '%'
          OR [StateProvince] LIKE '%' + @SearchText + '%'
          OR [PostalCode] LIKE '%' + @SearchText + '%'
          OR [Country] LIKE '%' + @SearchText + '%'
      );
END;
GO