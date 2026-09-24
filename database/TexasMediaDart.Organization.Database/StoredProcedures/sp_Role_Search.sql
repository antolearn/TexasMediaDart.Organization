CREATE PROCEDURE [dbo].[sp_Role_Search]
    @OrganizationId UNIQUEIDENTIFIER,

    @SearchText NVARCHAR(100) = NULL,
    @IsSystemRole BIT = NULL,
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
        THROW 54204, 'SortBy must be name, description, or createdUtc.', 1;
    END;

    IF @SortDirection IS NOT NULL
       AND @SortDirection NOT IN ('asc', 'desc')
    BEGIN
        THROW 54205, 'SortDirection must be asc or desc.', 1;
    END;

    ------------------------------------------------------------
    -- Sorting defaults
    --
    -- No SortBy:
    --   Preserve existing default ordering.
    --
    -- SortBy supplied without direction:
    --   ASC for Name / Description
    --   DESC for CreatedUtc
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

      AND
      (
          @IncludeDeleted = 1
          OR R.[IsDeleted] = 0
      )

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

        --------------------------------------------------------
        -- Name
        --------------------------------------------------------

        CASE
            WHEN @SortBy = 'name'
             AND @SortDirection = 'asc'
            THEN R.[Name]
        END ASC,

        CASE
            WHEN @SortBy = 'name'
             AND @SortDirection = 'desc'
            THEN R.[Name]
        END DESC,

        --------------------------------------------------------
        -- Description
        --------------------------------------------------------

        CASE
            WHEN @SortBy = 'description'
             AND @SortDirection = 'asc'
            THEN R.[Description]
        END ASC,

        CASE
            WHEN @SortBy = 'description'
             AND @SortDirection = 'desc'
            THEN R.[Description]
        END DESC,

        --------------------------------------------------------
        -- CreatedUtc
        --------------------------------------------------------

        CASE
            WHEN @SortBy = 'createdutc'
             AND @SortDirection = 'asc'
            THEN R.[CreatedUtc]
        END ASC,

        CASE
            WHEN @SortBy = 'createdutc'
             AND @SortDirection = 'desc'
            THEN R.[CreatedUtc]
        END DESC,

        --------------------------------------------------------
        -- Existing default ordering.
        -- Used only when SortBy is not supplied.
        --------------------------------------------------------

        CASE
            WHEN @SortBy IS NULL
            THEN R.[IsSystemRole]
        END DESC,

        CASE
            WHEN @SortBy IS NULL
            THEN R.[Name]
        END ASC,

        --------------------------------------------------------
        -- Deterministic tie-breaker for pagination
        --------------------------------------------------------

        R.[Id] ASC

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

      AND
      (
          @IncludeDeleted = 1
          OR R.[IsDeleted] = 0
      )

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