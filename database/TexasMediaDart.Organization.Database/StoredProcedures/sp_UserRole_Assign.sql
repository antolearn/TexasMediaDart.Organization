CREATE PROCEDURE [dbo].[sp_UserRole_Assign]
    @OrganizationUserId BIGINT,
    @RoleId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @CreatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@CreatedBy)));

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationUserId IS NULL
    BEGIN
        THROW 56501, 'OrganizationUserId is required.', 1;
    END;

    IF @RoleId IS NULL
    BEGIN
        THROW 56502, 'RoleId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 56503, 'OrganizationId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 56504, 'Authenticated user email is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify organization user belongs to organization
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[OrganizationUsers]
        WHERE [Id] = @OrganizationUserId
          AND [OrganizationId] = @OrganizationId
    )
    BEGIN
        THROW 56505,
            'The organization user does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Verify role belongs to same organization
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [Id] = @RoleId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 56506,
            'The role does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Role must be active
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [Id] = @RoleId
          AND [OrganizationId] = @OrganizationId
          AND [IsActive] = 1
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 56507,
            'The role is inactive and cannot be assigned.',
            1;
    END;

    ------------------------------------------------------------
    -- Role must be approved
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [Id] = @RoleId
          AND [OrganizationId] = @OrganizationId
          AND [IsApproved] = 1
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 56508,
            'The role is not approved and cannot be assigned.',
            1;
    END;

    ------------------------------------------------------------
    -- Prevent duplicate assignment
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[UserRoles]
        WHERE [OrganizationUserId] = @OrganizationUserId
          AND [RoleId] = @RoleId
    )
    BEGIN
        THROW 56509,
            'The role is already assigned to this user.',
            1;
    END;

    ------------------------------------------------------------
    -- Assign role
    ------------------------------------------------------------

    BEGIN TRY

        INSERT INTO [dbo].[UserRoles]
        (
            [OrganizationUserId],
            [RoleId],
            [CreatedBy]
        )
        VALUES
        (
            @OrganizationUserId,
            @RoleId,
            @AuditEmail
        );

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 56509,
                'The role is already assigned to this user.',
                1;
        END;

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Return assignment
    ------------------------------------------------------------

    SELECT
        UR.[OrganizationUserId],
        OU.[IdentityUserId],

        UR.[RoleId],
        R.[Name] AS [RoleName],
        R.[Description] AS [RoleDescription],
        R.[IsSystemRole],

        UR.[CreatedBy],
        UR.[CreatedUtc]

    FROM [dbo].[UserRoles] UR

    INNER JOIN [dbo].[OrganizationUsers] OU
        ON OU.[Id] = UR.[OrganizationUserId]

    INNER JOIN [dbo].[Roles] R
        ON R.[Id] = UR.[RoleId]

    WHERE UR.[OrganizationUserId] = @OrganizationUserId
      AND UR.[RoleId] = @RoleId;
END;
GO