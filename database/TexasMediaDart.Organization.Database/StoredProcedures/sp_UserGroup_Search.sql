CREATE PROCEDURE [dbo].[sp_UserGroup_Search]
    @OrganizationId UNIQUEIDENTIFIER,
    @SearchText NVARCHAR(100) = NULL,
    @IsActive BIT = NULL,
    @IsApproved BIT = NULL,
    @IncludeDeleted BIT = 0,

    @SortBy NVARCHAR(50) = NULL,
    @SortDirection NVARCHAR(4) = NULL,

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
        THROW 55201, 'OrganizationId is required.', 1;
    END;

    IF @PageNumber < 1
    BEGIN
        THROW 55202, 'PageNumber must be greater than or equal to 1.', 1;
    END;

    IF @PageSize < 1 OR @PageSize > 200
    BEGIN
        THROW 55203, 'PageSize must be between 1 and 200.', 1;
    END;

    ------------------------------------------------------------
    -- Normalize search input
    ------------------------------------------------------------

    SET @SearchText =
        NULLIF(LTRIM(RTRIM(@SearchText)), '');

    ------------------------------------------------------------
    -- Normalize sorting input
    ------------------------------------------------------------

    SET @SortBy =
        LOWER(NULLIF(LTRIM(RTRIM(@SortBy)), ''));

    SET @SortDirection =
        LOWER(NULLIF(LTRIM(RTRIM(@SortDirection)), ''));

    ------------------------------------------------------------
    -- Validate sorting input
    ------------------------------------------------------------

    IF @SortBy IS NOT NULL
       AND @SortBy NOT IN ('name', 'description', 'createdutc')
    BEGIN
        THROW 55204, 'SortBy must be name, description, or createdUtc.', 1;
    END;

    IF @SortDirection IS NOT NULL
       AND @SortDirection NOT IN ('asc', 'desc')
    BEGIN
        THROW 55205, 'SortDirection must be asc or desc.', 1;
    END;

    ------------------------------------------------------------
    -- Sorting defaults
    ------------------------------------------------------------

    IF @SortBy IS NOT NULL
       AND @SortDirection IS NULL
    BEGIN
        SET @SortDirection =
            CASE
                WHEN @SortBy = 'createdutc' THEN 'desc'
                ELSE 'asc'
            END;
    END;

    ------------------------------------------------------------
    -- Pagination
    ------------------------------------------------------------

    DECLARE @Offset INT =
        (@PageNumber - 1) * @PageSize;

    ------------------------------------------------------------
    -- Result set 1:
    -- Paged user groups
    ------------------------------------------------------------

    SELECT
        UG.[Id] AS [UserGroupId],
        UG.[OrganizationId],
        UG.[Name],
        UG.[Description],
        UG.[IsActive],
        UG.[IsDeleted],
        UG.[IsApproved],
        UG.[CreatedBy],
        UG.[CreatedUtc],
        UG.[ModifiedBy],
        UG.[ModifiedUtc],
        UG.[ApprovedBy],
        UG.[ApprovedUtc]

    FROM [dbo].[UserGroups] UG

    WHERE UG.[OrganizationId] = @OrganizationId

      AND
      (
          @IncludeDeleted = 1
          OR UG.[IsDeleted] = 0
      )

      AND
      (
          @SearchText IS NULL
          OR UG.[Name] LIKE '%' + @SearchText + '%'
          OR UG.[Description] LIKE '%' + @SearchText + '%'
      )

      AND
      (
          @IsActive IS NULL
          OR UG.[IsActive] = @IsActive
      )

      AND
      (
          @IsApproved IS NULL
          OR UG.[IsApproved] = @IsApproved
      )

    ORDER BY

        --------------------------------------------------------
        -- Name
        --------------------------------------------------------

        CASE
            WHEN @SortBy = 'name'
             AND @SortDirection = 'asc'
            THEN UG.[Name]
        END ASC,

        CASE
            WHEN @SortBy = 'name'
             AND @SortDirection = 'desc'
            THEN UG.[Name]
        END DESC,

        --------------------------------------------------------
        -- Description
        --------------------------------------------------------

        CASE
            WHEN @SortBy = 'description'
             AND @SortDirection = 'asc'
            THEN UG.[Description]
        END ASC,

        CASE
            WHEN @SortBy = 'description'
             AND @SortDirection = 'desc'
            THEN UG.[Description]
        END DESC,

        --------------------------------------------------------
        -- CreatedUtc
        --------------------------------------------------------

        CASE
            WHEN @SortBy = 'createdutc'
             AND @SortDirection = 'asc'
            THEN UG.[CreatedUtc]
        END ASC,

        CASE
            WHEN @SortBy = 'createdutc'
             AND @SortDirection = 'desc'
            THEN UG.[CreatedUtc]
        END DESC,

        --------------------------------------------------------
        -- Existing default ordering
        --------------------------------------------------------

        CASE
            WHEN @SortBy IS NULL
            THEN UG.[Name]
        END ASC,

        --------------------------------------------------------
        -- Deterministic tie-breaker for pagination
        --------------------------------------------------------

        UG.[Id] ASC

    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    ------------------------------------------------------------
    -- Result set 2:
    -- Total matching row count
    ------------------------------------------------------------

    SELECT
        COUNT_BIG(1) AS [TotalCount]

    FROM [dbo].[UserGroups] UG

    WHERE UG.[OrganizationId] = @OrganizationId

      AND
      (
          @IncludeDeleted = 1
          OR UG.[IsDeleted] = 0
      )

      AND
      (
          @SearchText IS NULL
          OR UG.[Name] LIKE '%' + @SearchText + '%'
          OR UG.[Description] LIKE '%' + @SearchText + '%'
      )

      AND
      (
          @IsActive IS NULL
          OR UG.[IsActive] = @IsActive
      )

      AND
      (
          @IsApproved IS NULL
          OR UG.[IsApproved] = @IsApproved
      );
END;
GO