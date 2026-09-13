CREATE PROCEDURE [dbo].[sp_Role_GetById]
    @RoleId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @RoleId IS NULL
    BEGIN
        THROW 54101, 'RoleId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 54102, 'OrganizationId is required.', 1;
    END;

    ------------------------------------------------------------
    -- Return role
    --
    -- OrganizationId is included intentionally for tenant isolation.
    ------------------------------------------------------------

    SELECT
        R.[Id] AS [RoleId],
        R.[OrganizationId],

        R.[Name],
        R.[Description],

        R.[IsSystemRole],
        R.[IsActive],
        R.[IsDeleted],
        R.[IsApproved],

        R.[CreatedBy],
        R.[CreatedUtc],

        R.[ModifiedBy],
        R.[ModifiedUtc],

        R.[ApprovedBy],
        R.[ApprovedUtc]

    FROM [dbo].[Roles] R

    WHERE R.[Id] = @RoleId
      AND R.[OrganizationId] = @OrganizationId
      AND R.[IsDeleted] = 0;
END;
GO