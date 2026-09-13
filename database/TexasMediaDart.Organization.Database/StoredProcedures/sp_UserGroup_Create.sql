CREATE PROCEDURE [dbo].[sp_UserGroup_Create]
    @UserGroupId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500) = NULL,
    @CreatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);
    DECLARE @GroupName NVARCHAR(100);

    SET @AuditEmail = LOWER(LTRIM(RTRIM(@CreatedBy)));
    SET @GroupName = NULLIF(LTRIM(RTRIM(@Name)), '');
    SET @Description = NULLIF(LTRIM(RTRIM(@Description)), '');

    IF @UserGroupId IS NULL
        THROW 55001, 'UserGroupId is required.', 1;

    IF @OrganizationId IS NULL
        THROW 55002, 'OrganizationId is required.', 1;

    IF @GroupName IS NULL
        THROW 55003, 'User group name is required.', 1;

    IF NULLIF(@AuditEmail, '') IS NULL
        THROW 55004, 'Authenticated user email is required.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Organizations]
        WHERE [Id] = @OrganizationId
          AND [IsActive] = 1
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 55005,
            'The organization does not exist or is inactive.',
            1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[UserGroups]
        WHERE [OrganizationId] = @OrganizationId
          AND [Name] = @GroupName
    )
    BEGIN
        THROW 55006,
            'A user group with this name already exists in the organization.',
            1;
    END;

    BEGIN TRY

        INSERT INTO [dbo].[UserGroups]
        (
            [Id],
            [OrganizationId],
            [Name],
            [Description],
            [IsActive],
            [IsDeleted],
            [IsApproved],
            [CreatedBy]
        )
        VALUES
        (
            @UserGroupId,
            @OrganizationId,
            @GroupName,
            @Description,
            1,
            0,
            0,
            @AuditEmail
        );

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 55006,
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