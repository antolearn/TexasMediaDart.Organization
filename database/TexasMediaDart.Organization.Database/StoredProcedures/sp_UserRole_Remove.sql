CREATE PROCEDURE [dbo].[sp_UserRole_Remove]
    @OrganizationUserId BIGINT,
    @RoleId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationUserId IS NULL
    BEGIN
        THROW 56601, 'OrganizationUserId is required.', 1;
    END;

    IF @RoleId IS NULL
    BEGIN
        THROW 56602, 'RoleId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 56603, 'OrganizationId is required.', 1;
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
        THROW 56604,
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
    )
    BEGIN
        THROW 56605,
            'The role does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Protect Owner assignment
    --
    -- Owner membership must not be removed by ordinary
    -- role assignment maintenance.
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [Id] = @RoleId
          AND [OrganizationId] = @OrganizationId
          AND [IsSystemRole] = 1
          AND UPPER([Name]) = 'OWNER'
    )
    BEGIN
        THROW 56606,
            'The Owner role cannot be removed through ordinary role assignment.',
            1;
    END;

    ------------------------------------------------------------
    -- Verify assignment exists
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[UserRoles]
        WHERE [OrganizationUserId] = @OrganizationUserId
          AND [RoleId] = @RoleId
    )
    BEGIN
        THROW 56607,
            'The role is not assigned to this user.',
            1;
    END;

    ------------------------------------------------------------
    -- Remove assignment
    ------------------------------------------------------------

    DELETE FROM [dbo].[UserRoles]
    WHERE [OrganizationUserId] = @OrganizationUserId
      AND [RoleId] = @RoleId;
END;
GO