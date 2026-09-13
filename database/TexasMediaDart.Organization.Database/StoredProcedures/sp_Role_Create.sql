CREATE PROCEDURE [dbo].[sp_Role_Create]
    @RoleId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500) = NULL,
    @CreatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);
    DECLARE @RoleName NVARCHAR(100);

    ------------------------------------------------------------
    -- Normalize input
    ------------------------------------------------------------

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@CreatedBy)));

    SET @RoleName =
        NULLIF(LTRIM(RTRIM(@Name)), '');

    SET @Description =
        NULLIF(LTRIM(RTRIM(@Description)), '');

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @RoleId IS NULL
    BEGIN
        THROW 54001, 'RoleId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 54002, 'OrganizationId is required.', 1;
    END;

    IF @RoleName IS NULL
    BEGIN
        THROW 54003, 'Role name is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 54004, 'Authenticated user email is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify organization
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Organizations]
        WHERE [Id] = @OrganizationId
          AND [IsActive] = 1
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 54005,
            'The organization does not exist or is inactive.',
            1;
    END;

    ------------------------------------------------------------
    -- Protect reserved system role name
    ------------------------------------------------------------

    IF UPPER(@RoleName) = 'OWNER'
    BEGIN
        THROW 54006,
            'Owner is a reserved system role name.',
            1;
    END;

    ------------------------------------------------------------
    -- Role name must be unique within organization
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [OrganizationId] = @OrganizationId
          AND [Name] = @RoleName
    )
    BEGIN
        THROW 54007,
            'A role with this name already exists in the organization.',
            1;
    END;

    ------------------------------------------------------------
    -- RoleId must not already exist
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [Id] = @RoleId
    )
    BEGIN
        THROW 54008,
            'A role with this RoleId already exists.',
            1;
    END;

    ------------------------------------------------------------
    -- Create role
    --
    -- Custom roles:
    --   IsSystemRole = 0
    --   IsApproved   = 0
    ------------------------------------------------------------

    BEGIN TRY

        INSERT INTO [dbo].[Roles]
        (
            [Id],
            [OrganizationId],
            [Name],
            [Description],

            [IsSystemRole],
            [IsActive],
            [IsDeleted],
            [IsApproved],

            [CreatedBy]
        )
        VALUES
        (
            @RoleId,
            @OrganizationId,
            @RoleName,
            @Description,

            0,
            1,
            0,
            0,

            @AuditEmail
        );

    END TRY
    BEGIN CATCH

        --------------------------------------------------------
        -- Handle unique-name/PK race conditions
        --------------------------------------------------------

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 54007,
                'A role with this name already exists in the organization.',
                1;
        END;

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Return created role
    ------------------------------------------------------------

    SELECT
        [Id] AS [RoleId],
        [OrganizationId],

        [Name],
        [Description],

        [IsSystemRole],
        [IsActive],
        [IsDeleted],
        [IsApproved],

        [CreatedBy],
        [CreatedUtc],

        [ModifiedBy],
        [ModifiedUtc],

        [ApprovedBy],
        [ApprovedUtc]

    FROM [dbo].[Roles]

    WHERE [Id] = @RoleId
      AND [OrganizationId] = @OrganizationId;
END;
GO