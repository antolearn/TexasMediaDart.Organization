CREATE PROCEDURE [dbo].[sp_UserGroup_Search]
    @OrganizationId UNIQUEIDENTIFIER,
    @SearchText NVARCHAR(100) = NULL,
    @IsActive BIT = NULL,
    @IsApproved BIT = NULL,
    @IncludeDeleted BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 25
AS
BEGIN
    SET NOCOUNT ON;

    IF @OrganizationId IS NULL
        THROW 55201, 'OrganizationId is required.', 1;

    IF @PageNumber < 1
        THROW 55202, 'PageNumber must be greater than or equal to 1.', 1;

    IF @PageSize < 1 OR @PageSize > 200
        THROW 55203, 'PageSize must be between 1 and 200.', 1;

    SET @SearchText = NULLIF(LTRIM(RTRIM(@SearchText)), '');

    DECLARE @Offset INT =
        (@PageNumber - 1) * @PageSize;

    SELECT
        [Id] AS [UserGroupId],
        [OrganizationId],
        [Name],
        [Description],
        [IsActive],
        [IsDeleted],
        [IsApproved],
        [CreatedBy],
        [CreatedUtc],
        [ModifiedBy],
        [ModifiedUtc],
        [ApprovedBy],
        [ApprovedUtc]
    FROM [dbo].[UserGroups]
    WHERE [OrganizationId] = @OrganizationId
      AND
      (
          @IncludeDeleted = 1
          OR [IsDeleted] = 0
      )
      AND
      (
          @SearchText IS NULL
          OR [Name] LIKE '%' + @SearchText + '%'
          OR [Description] LIKE '%' + @SearchText + '%'
      )
      AND
      (
          @IsActive IS NULL
          OR [IsActive] = @IsActive
      )
      AND
      (
          @IsApproved IS NULL
          OR [IsApproved] = @IsApproved
      )
    ORDER BY
        [Name],
        [Id]
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    SELECT
        COUNT_BIG(1) AS [TotalCount]
    FROM [dbo].[UserGroups]
    WHERE [OrganizationId] = @OrganizationId
      AND
      (
          @IncludeDeleted = 1
          OR [IsDeleted] = 0
      )
      AND
      (
          @SearchText IS NULL
          OR [Name] LIKE '%' + @SearchText + '%'
          OR [Description] LIKE '%' + @SearchText + '%'
      )
      AND
      (
          @IsActive IS NULL
          OR [IsActive] = @IsActive
      )
      AND
      (
          @IsApproved IS NULL
          OR [IsApproved] = @IsApproved
      );
END;
GO