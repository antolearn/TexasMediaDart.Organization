CREATE PROCEDURE [dbo].[sp_OrganizationUser_Search]
    @OrganizationId UNIQUEIDENTIFIER,

    @IdentityUserId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT = NULL,
    @IsApproved BIT = NULL,

    @FilterByIdentityUserIds BIT = 0,
    @IdentityUserIds [dbo].[GuidList] READONLY,

    @SortBy NVARCHAR(50) = N'createdUtc',
    @SortDirection NVARCHAR(4) = N'desc',

    @PageNumber INT = 1,
    @PageSize INT = 25
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Normalize
    ------------------------------------------------------------

    SET @SortBy = LOWER(LTRIM(RTRIM(@SortBy)));
    SET @SortDirection = LOWER(LTRIM(RTRIM(@SortDirection)));

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 53201, 'OrganizationId is required.', 1;
    END;

    IF @PageNumber < 1
    BEGIN
        THROW 53202, 'PageNumber must be greater than or equal to 1.', 1;
    END;

    IF @PageSize < 1 OR @PageSize > 200
    BEGIN
        THROW 53203, 'PageSize must be between 1 and 200.', 1;
    END;

    IF @SortBy NOT IN (N'createdutc')
    BEGIN
        THROW 53204, 'SortBy must be createdUtc.', 1;
    END;

    IF @SortDirection NOT IN (N'asc', N'desc')
    BEGIN
        THROW 53205, 'SortDirection must be asc or desc.', 1;
    END;

    DECLARE @Offset INT =
        (@PageNumber - 1) * @PageSize;

    ------------------------------------------------------------
    -- Result set 1:
    -- Paged organization users
    ------------------------------------------------------------

    SELECT
        OU.[Id] AS [OrganizationUserId],
        OU.[OrganizationId],
        OU.[IdentityUserId],

        OU.[IsActive],
        OU.[IsApproved],

        OU.[CreatedBy],
        OU.[CreatedUtc],

        OU.[ModifiedBy],
        OU.[ModifiedUtc],

        OU.[ApprovedBy],
        OU.[ApprovedUtc]

    FROM [dbo].[OrganizationUsers] OU

    WHERE OU.[OrganizationId] = @OrganizationId

      AND
      (
          @IdentityUserId IS NULL
          OR OU.[IdentityUserId] = @IdentityUserId
      )

      AND
      (
          @IsActive IS NULL
          OR OU.[IsActive] = @IsActive
      )

      AND
      (
          @IsApproved IS NULL
          OR OU.[IsApproved] = @IsApproved
      )

      AND
      (
          @FilterByIdentityUserIds = 0
          OR EXISTS
          (
              SELECT 1
              FROM @IdentityUserIds I
              WHERE I.[Id] = OU.[IdentityUserId]
          )
      )

    ORDER BY
        CASE
            WHEN @SortBy = N'createdutc'
             AND @SortDirection = N'asc'
            THEN OU.[CreatedUtc]
        END ASC,

        CASE
            WHEN @SortBy = N'createdutc'
             AND @SortDirection = N'desc'
            THEN OU.[CreatedUtc]
        END DESC,

        CASE
            WHEN @SortDirection = N'asc'
            THEN OU.[Id]
        END ASC,

        CASE
            WHEN @SortDirection = N'desc'
            THEN OU.[Id]
        END DESC

    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    ------------------------------------------------------------
    -- Result set 2:
    -- Total matching row count
    ------------------------------------------------------------

    SELECT
        COUNT_BIG(1) AS [TotalCount]

    FROM [dbo].[OrganizationUsers] OU

    WHERE OU.[OrganizationId] = @OrganizationId

      AND
      (
          @IdentityUserId IS NULL
          OR OU.[IdentityUserId] = @IdentityUserId
      )

      AND
      (
          @IsActive IS NULL
          OR OU.[IsActive] = @IsActive
      )

      AND
      (
          @IsApproved IS NULL
          OR OU.[IsApproved] = @IsApproved
      )

      AND
      (
          @FilterByIdentityUserIds = 0
          OR EXISTS
          (
              SELECT 1
              FROM @IdentityUserIds I
              WHERE I.[Id] = OU.[IdentityUserId]
          )
      );
END;
GO