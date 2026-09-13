CREATE PROCEDURE [dbo].[sp_OrganizationUser_Delete]
    @OrganizationUserId BIGINT,
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

    IF @OrganizationUserId IS NULL
    BEGIN
        THROW 53401, 'OrganizationUserId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 53402, 'OrganizationId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 53403, 'Authenticated user email is required.', 1;
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
        THROW 53404,
            'The organization user does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Do not delete the organization Owner
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[UserRoles] UR
        INNER JOIN [dbo].[Roles] R
            ON R.[Id] = UR.[RoleId]
        WHERE UR.[OrganizationUserId] = @OrganizationUserId
          AND R.[OrganizationId] = @OrganizationId
          AND R.[IsSystemRole] = 1
          AND R.[Name] = 'Owner'
    )
    BEGIN
        THROW 53405,
            'The organization Owner cannot be deleted.',
            1;
    END;

    ------------------------------------------------------------
    -- Logical delete by deactivation
    --
    -- OrganizationUsers currently has no IsDeleted column,
    -- so deletion is represented by IsActive = 0.
    ------------------------------------------------------------

    UPDATE [dbo].[OrganizationUsers]
    SET
        [IsActive] = 0,
        [ModifiedBy] = @AuditEmail,
        [ModifiedUtc] = SYSUTCDATETIME()
    WHERE [Id] = @OrganizationUserId
      AND [OrganizationId] = @OrganizationId;

    ------------------------------------------------------------
    -- Return resulting state
    ------------------------------------------------------------

    SELECT
        [Id] AS [OrganizationUserId],
        [OrganizationId],
        [IdentityUserId],

        [IsActive],
        [IsApproved],

        [CreatedBy],
        [CreatedUtc],

        [ModifiedBy],
        [ModifiedUtc],

        [ApprovedBy],
        [ApprovedUtc]

    FROM [dbo].[OrganizationUsers]
    WHERE [Id] = @OrganizationUserId
      AND [OrganizationId] = @OrganizationId;
END;
GO