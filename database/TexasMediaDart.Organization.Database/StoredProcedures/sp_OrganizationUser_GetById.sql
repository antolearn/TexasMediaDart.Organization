CREATE PROCEDURE [dbo].[sp_OrganizationUser_GetById]
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
        THROW 53101, 'OrganizationUserId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 53102, 'OrganizationId is required.', 1;
    END;

    ------------------------------------------------------------
    -- Return organization user
    --
    -- OrganizationId is intentionally part of the WHERE clause
    -- to enforce tenant isolation.
    ------------------------------------------------------------

    SELECT
        OU.[Id] AS [OrganizationUserId],
        OU.[OrganizationId],
        OU.[IdentityUserId],

        OU.[IsActive],
        OU.[IsApproved],

        OU.[CreatedBy],
        OU.[CreatedUtc],

        OU.[ModifiedBy],
        OU.[ModifiedUtc],

        OU.[ApprovedBy],
        OU.[ApprovedUtc]

    FROM [dbo].[OrganizationUsers] OU

    WHERE OU.[Id] = @OrganizationUserId
      AND OU.[OrganizationId] = @OrganizationId;
END;
GO