CREATE PROCEDURE [dbo].[sp_UserGroupMember_Remove]
    @UserGroupId UNIQUEIDENTIFIER,
    @OrganizationUserId BIGINT,
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @UserGroupId IS NULL
        THROW 55601, 'UserGroupId is required.', 1;

    IF @OrganizationUserId IS NULL
        THROW 55602, 'OrganizationUserId is required.', 1;

    IF @OrganizationId IS NULL
        THROW 55603, 'OrganizationId is required.', 1;

    ------------------------------------------------------------
    -- Tenant validation
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[UserGroups]
        WHERE [Id] = @UserGroupId
          AND [OrganizationId] = @OrganizationId
    )
    BEGIN
        THROW 55604,
            'The user group does not exist in this organization.',
            1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[OrganizationUsers]
        WHERE [Id] = @OrganizationUserId
          AND [OrganizationId] = @OrganizationId
    )
    BEGIN
        THROW 55605,
            'The organization user does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Membership validation
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[UserGroupMembers]
        WHERE [UserGroupId] = @UserGroupId
          AND [OrganizationUserId] = @OrganizationUserId
    )
    BEGIN
        THROW 55606,
            'The user is not a member of this user group.',
            1;
    END;

    DELETE FROM [dbo].[UserGroupMembers]
    WHERE [UserGroupId] = @UserGroupId
      AND [OrganizationUserId] = @OrganizationUserId;
END;
GO