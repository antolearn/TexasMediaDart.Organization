CREATE PROCEDURE [dbo].[sp_OrganizationUser_Update]
    @OrganizationUserId BIGINT,
    @OrganizationId UNIQUEIDENTIFIER,
    @IsActive BIT,
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
        THROW 53301, 'OrganizationUserId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 53302, 'OrganizationId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 53303, 'Authenticated user email is required.', 1;
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
        THROW 53304,
            'The organization user does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Update user
    --
    -- Approval state is intentionally NOT modified here.
    ------------------------------------------------------------

    UPDATE [dbo].[OrganizationUsers]
    SET
        [IsActive] = @IsActive,
        [ModifiedBy] = @AuditEmail,
        [ModifiedUtc] = SYSUTCDATETIME()
    WHERE [Id] = @OrganizationUserId
      AND [OrganizationId] = @OrganizationId;

    ------------------------------------------------------------
    -- Return updated organization user
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