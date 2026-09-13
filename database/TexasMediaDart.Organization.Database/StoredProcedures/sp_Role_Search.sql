CREATE PROCEDURE [dbo].[sp_Role_Search]
    @OrganizationId UNIQUEIDENTIFIER,

    @SearchText NVARCHAR(100) = NULL,
    @IsSystemRole BIT = NULL,
    @IsActive BIT = NULL,
    @IsApproved BIT = NULL,

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
        THROW 54201, 'OrganizationId is required.', 1;
    END;

    IF @PageNumber < 1
    BEGIN
        THROW 54202, 'PageNumber must be greater than or equal to 1.', 1;
    END;

    IF @PageSize < 1 OR @PageSize > 200
    BEGIN
        THROW 54203, 'PageSize must be between 1 and 200.', 1;
    END;

    ------------------------------------------------------------
    -- Normalize search input
    ------------------------------------------------------------

    SET @SearchText =
        NULLIF(LTRIM(RTRIM(@SearchText)), '');

    DECLARE @Offset INT =
        (@PageNumber - 1) * @PageSize;

    ------------------------------------------------------------
    -- Result set 1:
    -- Paged roles
    ------------------------------------------------------------

    SELECT
        R.[Id] AS [RoleId],
        R.[OrganizationId],

        R.[Name],
        R.[Description],

        R.[IsSystemRole],
        R.[IsActive],
        R.[IsDeleted],
        R.[IsApproved],

        R.[CreatedBy],
        R.[CreatedUtc],

        R.[ModifiedBy],
        R.[ModifiedUtc],

        R.[ApprovedBy],
        R.[ApprovedUtc]

    FROM [dbo].[Roles] R

    WHERE R.[OrganizationId] = @OrganizationId
      AND R.[IsDeleted] = 0

      AND
      (
          @SearchText IS NULL
          OR R.[Name] LIKE '%' + @SearchText + '%'
          OR R.[Description] LIKE '%' + @SearchText + '%'
      )

      AND
      (
          @IsSystemRole IS NULL
          OR R.[IsSystemRole] = @IsSystemRole
      )

      AND
      (
          @IsActive IS NULL
          OR R.[IsActive] = @IsActive
      )

      AND
      (
          @IsApproved IS NULL
          OR R.[IsApproved] = @IsApproved
      )

    ORDER BY
        R.[IsSystemRole] DESC,
        R.[Name],
        R.[Id]

    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    ------------------------------------------------------------
    -- Result set 2:
    -- Total matching row count
    ------------------------------------------------------------

    SELECT
        COUNT_BIG(1) AS [TotalCount]

    FROM [dbo].[Roles] R

    WHERE R.[OrganizationId] = @OrganizationId
      AND R.[IsDeleted] = 0

      AND
      (
          @SearchText IS NULL
          OR R.[Name] LIKE '%' + @SearchText + '%'
          OR R.[Description] LIKE '%' + @SearchText + '%'
      )

      AND
      (
          @IsSystemRole IS NULL
          OR R.[IsSystemRole] = @IsSystemRole
      )

      AND
      (
          @IsActive IS NULL
          OR R.[IsActive] = @IsActive
      )

      AND
      (
          @IsApproved IS NULL
          OR R.[IsApproved] = @IsApproved
      );
END;
GO