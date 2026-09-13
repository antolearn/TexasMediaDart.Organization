CREATE PROCEDURE [dbo].[sp_UserGroup_Update]
    @UserGroupId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500) = NULL,
    @IsActive BIT,
    @ModifiedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);
    DECLARE @GroupName NVARCHAR(100);

    SET @AuditEmail = LOWER(LTRIM(RTRIM(@ModifiedBy)));
    SET @GroupName = NULLIF(LTRIM(RTRIM(@Name)), '');
    SET @Description = NULLIF(LTRIM(RTRIM(@Description)), '');

    IF @UserGroupId IS NULL
        THROW 55301, 'UserGroupId is required.', 1;

    IF @OrganizationId IS NULL
        THROW 55302, 'OrganizationId is required.', 1;

    IF @GroupName IS NULL
        THROW 55303, 'User group name is required.', 1;

    IF NULLIF(@AuditEmail, '') IS NULL
        THROW 55304, 'Authenticated user email is required.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[UserGroups]
        WHERE [Id] = @UserGroupId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 55305,
            'The user group does not exist in this organization.',
            1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[UserGroups]
        WHERE [OrganizationId] = @OrganizationId
          AND [Name] = @GroupName
          AND [Id] <> @UserGroupId
    )
    BEGIN
        THROW 55306,
            'A user group with this name already exists in the organization.',
            1;
    END;

    BEGIN TRY

        UPDATE [dbo].[UserGroups]
        SET
            [Name] = @GroupName,
            [Description] = @Description,
            [IsActive] = @IsActive,
            [ModifiedBy] = @AuditEmail,
            [ModifiedUtc] = SYSUTCDATETIME()
        WHERE [Id] = @UserGroupId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0;

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 55306,
                'A user group with this name already exists in the organization.',
                1;
        END;

        THROW;

    END CATCH;

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