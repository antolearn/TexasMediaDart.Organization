CREATE PROCEDURE [dbo].[sp_UserGroup_Delete]
    @UserGroupId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @ModifiedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@ModifiedBy)));

    IF @UserGroupId IS NULL
        THROW 55401, 'UserGroupId is required.', 1;

    IF @OrganizationId IS NULL
        THROW 55402, 'OrganizationId is required.', 1;

    IF NULLIF(@AuditEmail, '') IS NULL
        THROW 55403, 'Authenticated user email is required.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[UserGroups]
        WHERE [Id] = @UserGroupId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 55404,
            'The user group does not exist in this organization.',
            1;
    END;

    UPDATE [dbo].[UserGroups]
    SET
        [IsDeleted] = 1,
        [IsActive] = 0,
        [ModifiedBy] = @AuditEmail,
        [ModifiedUtc] = SYSUTCDATETIME()
    WHERE [Id] = @UserGroupId
      AND [OrganizationId] = @OrganizationId
      AND [IsDeleted] = 0;

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
      AND [OrganizationId] = @OrganizationId;
END;
GO