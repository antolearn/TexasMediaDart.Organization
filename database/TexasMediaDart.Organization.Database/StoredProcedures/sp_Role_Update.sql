CREATE PROCEDURE [dbo].[sp_Role_Update]
    @RoleId UNIQUEIDENTIFIER,
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
    DECLARE @RoleName NVARCHAR(100);

    ------------------------------------------------------------
    -- Normalize input
    ------------------------------------------------------------

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@ModifiedBy)));

    SET @RoleName =
        NULLIF(LTRIM(RTRIM(@Name)), '');

    SET @Description =
        NULLIF(LTRIM(RTRIM(@Description)), '');

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @RoleId IS NULL
    BEGIN
        THROW 54301, 'RoleId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 54302, 'OrganizationId is required.', 1;
    END;

    IF @RoleName IS NULL
    BEGIN
        THROW 54303, 'Role name is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 54304, 'Authenticated user email is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify role belongs to organization
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
        THROW 54305,
            'The role does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Protect system roles
    --
    -- Owner and future system roles should not be renamed,
    -- disabled, or otherwise edited by ordinary role management.
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [Id] = @RoleId
          AND [OrganizationId] = @OrganizationId
          AND [IsSystemRole] = 1
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 54306,
            'System roles cannot be modified through ordinary role management.',
            1;
    END;

    ------------------------------------------------------------
    -- Protect reserved Owner role name
    ------------------------------------------------------------

    IF UPPER(@RoleName) = 'OWNER'
    BEGIN
        THROW 54307,
            'Owner is a reserved system role name.',
            1;
    END;

    ------------------------------------------------------------
    -- Role name must remain unique within organization
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [OrganizationId] = @OrganizationId
          AND [Name] = @RoleName
          AND [Id] <> @RoleId
    )
    BEGIN
        THROW 54308,
            'A role with this name already exists in the organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Update role
    --
    -- Approval state is intentionally not changed here.
    ------------------------------------------------------------

    BEGIN TRY

        UPDATE [dbo].[Roles]
        SET
            [Name] = @RoleName,
            [Description] = @Description,
            [IsActive] = @IsActive,
            [ModifiedBy] = @AuditEmail,
            [ModifiedUtc] = SYSUTCDATETIME()
        WHERE [Id] = @RoleId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0;

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 54308,
                'A role with this name already exists in the organization.',
                1;
        END;

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Return updated role
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