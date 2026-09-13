CREATE PROCEDURE [dbo].[sp_UserRole_GetByUser]
    @OrganizationUserId BIGINT,
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationUserId IS NULL
    BEGIN
        THROW 56701, 'OrganizationUserId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 56702, 'OrganizationId is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify user belongs to organization
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[OrganizationUsers]
        WHERE [Id] = @OrganizationUserId
          AND [OrganizationId] = @OrganizationId
    )
    BEGIN
        THROW 56703,
            'The organization user does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Return assigned roles
    ------------------------------------------------------------

    SELECT
        UR.[OrganizationUserId],

        OU.[IdentityUserId],

        R.[Id] AS [RoleId],
        R.[Name] AS [RoleName],
        R.[Description] AS [RoleDescription],

        R.[IsSystemRole],
        R.[IsActive],
        R.[IsDeleted],
        R.[IsApproved],

        UR.[CreatedBy] AS [AssignedBy],
        UR.[CreatedUtc] AS [AssignedUtc]

    FROM [dbo].[UserRoles] UR

    INNER JOIN [dbo].[OrganizationUsers] OU
        ON OU.[Id] = UR.[OrganizationUserId]

    INNER JOIN [dbo].[Roles] R
        ON R.[Id] = UR.[RoleId]

    WHERE UR.[OrganizationUserId] = @OrganizationUserId
      AND OU.[OrganizationId] = @OrganizationId
      AND R.[OrganizationId] = @OrganizationId

    ORDER BY
        R.[IsSystemRole] DESC,
        R.[Name],
        R.[Id];
END;
GO