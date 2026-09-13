CREATE PROCEDURE [dbo].[sp_OrganizationUser_Search]
    @OrganizationId UNIQUEIDENTIFIER,

    @IdentityUserId UNIQUEIDENTIFIER = NULL,
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

    ORDER BY
        OU.[CreatedUtc] DESC,
        OU.[Id] DESC

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
      );
END;
GO