CREATE PROCEDURE [dbo].[sp_UserGroup_GetById]
    @UserGroupId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF @UserGroupId IS NULL
        THROW 55101, 'UserGroupId is required.', 1;

    IF @OrganizationId IS NULL
        THROW 55102, 'OrganizationId is required.', 1;

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
    WHERE [Id] = @UserGroupId
      AND [OrganizationId] = @OrganizationId
      AND [IsDeleted] = 0;
END;
GO