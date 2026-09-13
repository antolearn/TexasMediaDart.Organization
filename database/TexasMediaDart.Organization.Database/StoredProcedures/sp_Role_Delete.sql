CREATE PROCEDURE [dbo].[sp_Role_Delete]
    @RoleId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @ModifiedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);

    ------------------------------------------------------------
    -- Normalize audit email
    ------------------------------------------------------------

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@ModifiedBy)));

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @RoleId IS NULL
    BEGIN
        THROW 54401, 'RoleId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 54402, 'OrganizationId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 54403, 'Authenticated user email is required.', 1;
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
        THROW 54404,
            'The role does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Protect system roles
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
        THROW 54405,
            'System roles cannot be deleted.',
            1;
    END;

    ------------------------------------------------------------
    -- Do not delete a role that is assigned to users
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[UserRoles] UR
        WHERE UR.[RoleId] = @RoleId
    )
    BEGIN
        THROW 54406,
            'The role cannot be deleted because it is assigned to one or more users.',
            1;
    END;

    ------------------------------------------------------------
    -- Soft delete
    ------------------------------------------------------------

    UPDATE [dbo].[Roles]
    SET
        [IsDeleted] = 1,
        [IsActive] = 0,
        [ModifiedBy] = @AuditEmail,
        [ModifiedUtc] = SYSUTCDATETIME()
    WHERE [Id] = @RoleId
      AND [OrganizationId] = @OrganizationId
      AND [IsDeleted] = 0;

    ------------------------------------------------------------
    -- Return resulting role state
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