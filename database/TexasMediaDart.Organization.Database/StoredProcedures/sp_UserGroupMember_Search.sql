CREATE PROCEDURE [dbo].[sp_UserGroupMember_Search]
    @UserGroupId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @IsActive BIT = NULL,
    @IsApproved BIT = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 25
AS
BEGIN
    SET NOCOUNT ON;

    IF @UserGroupId IS NULL
        THROW 55701, 'UserGroupId is required.', 1;

    IF @OrganizationId IS NULL
        THROW 55702, 'OrganizationId is required.', 1;

    IF @PageNumber < 1
        THROW 55703, 'PageNumber must be greater than or equal to 1.', 1;

    IF @PageSize < 1 OR @PageSize > 200
        THROW 55704, 'PageSize must be between 1 and 200.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[UserGroups]
        WHERE [Id] = @UserGroupId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 55705,
            'The user group does not exist in this organization.',
            1;
    END;

    DECLARE @Offset INT =
        (@PageNumber - 1) * @PageSize;

    SELECT
        UGM.[UserGroupId],
        UGM.[OrganizationUserId],

        OU.[IdentityUserId],
        OU.[IsActive],
        OU.[IsApproved],

        UGM.[CreatedBy] AS [MembershipCreatedBy],
        UGM.[CreatedUtc] AS [MembershipCreatedUtc]

    FROM [dbo].[UserGroupMembers] UGM

    INNER JOIN [dbo].[OrganizationUsers] OU
        ON OU.[Id] = UGM.[OrganizationUserId]

    WHERE UGM.[UserGroupId] = @UserGroupId
      AND OU.[OrganizationId] = @OrganizationId

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
        UGM.[CreatedUtc] DESC,
        UGM.[OrganizationUserId]

    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    SELECT
        COUNT_BIG(1) AS [TotalCount]

    FROM [dbo].[UserGroupMembers] UGM

    INNER JOIN [dbo].[OrganizationUsers] OU
        ON OU.[Id] = UGM.[OrganizationUserId]

    WHERE UGM.[UserGroupId] = @UserGroupId
      AND OU.[OrganizationId] = @OrganizationId

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