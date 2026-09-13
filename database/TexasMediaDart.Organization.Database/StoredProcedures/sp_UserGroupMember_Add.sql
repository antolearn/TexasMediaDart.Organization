CREATE PROCEDURE [dbo].[sp_UserGroupMember_Add]
    @UserGroupId UNIQUEIDENTIFIER,
    @OrganizationUserId BIGINT,
    @OrganizationId UNIQUEIDENTIFIER,
    @CreatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@CreatedBy)));

    IF @UserGroupId IS NULL
        THROW 55501, 'UserGroupId is required.', 1;

    IF @OrganizationUserId IS NULL
        THROW 55502, 'OrganizationUserId is required.', 1;

    IF @OrganizationId IS NULL
        THROW 55503, 'OrganizationId is required.', 1;

    IF NULLIF(@AuditEmail, '') IS NULL
        THROW 55504, 'Authenticated user email is required.', 1;

    ------------------------------------------------------------
    -- Verify group belongs to organization
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[UserGroups]
        WHERE [Id] = @UserGroupId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 55505,
            'The user group does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Verify user belongs to same organization
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[OrganizationUsers]
        WHERE [Id] = @OrganizationUserId
          AND [OrganizationId] = @OrganizationId
    )
    BEGIN
        THROW 55506,
            'The organization user does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Prevent duplicate membership
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[UserGroupMembers]
        WHERE [UserGroupId] = @UserGroupId
          AND [OrganizationUserId] = @OrganizationUserId
    )
    BEGIN
        THROW 55507,
            'The user is already a member of this user group.',
            1;
    END;

    BEGIN TRY

        INSERT INTO [dbo].[UserGroupMembers]
        (
            [UserGroupId],
            [OrganizationUserId],
            [CreatedBy]
        )
        VALUES
        (
            @UserGroupId,
            @OrganizationUserId,
            @AuditEmail
        );

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 55507,
                'The user is already a member of this user group.',
                1;
        END;

        THROW;

    END CATCH;

    SELECT
        UGM.[UserGroupId],
        UGM.[OrganizationUserId],
        OU.[IdentityUserId],
        UGM.[CreatedBy],
        UGM.[CreatedUtc]
    FROM [dbo].[UserGroupMembers] UGM
    INNER JOIN [dbo].[OrganizationUsers] OU
        ON OU.[Id] = UGM.[OrganizationUserId]
    WHERE UGM.[UserGroupId] = @UserGroupId
      AND UGM.[OrganizationUserId] = @OrganizationUserId;
END;
GO