CREATE PROCEDURE [dbo].[sp_OrganizationUser_Create]
    @OrganizationId UNIQUEIDENTIFIER,
    @IdentityUserId UNIQUEIDENTIFIER,
    @CreatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);
    DECLARE @OrganizationUserId BIGINT;

    ------------------------------------------------------------
    -- Normalize audit email
    ------------------------------------------------------------

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@CreatedBy)));

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 53001, 'OrganizationId is required.', 1;
    END;

    IF @IdentityUserId IS NULL
    BEGIN
        THROW 53002, 'IdentityUserId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 53003, 'Authenticated user email is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify organization exists and is active
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
        THROW 53004,
            'The organization does not exist or is inactive.',
            1;
    END;

    ------------------------------------------------------------
    -- Enforce:
    -- one Identity user can belong to only one organization
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[OrganizationUsers]
        WHERE [IdentityUserId] = @IdentityUserId
    )
    BEGIN
        THROW 53005,
            'The identity user already belongs to an organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Create pending organization user
    ------------------------------------------------------------

    BEGIN TRY

        INSERT INTO [dbo].[OrganizationUsers]
        (
            [OrganizationId],
            [IdentityUserId],
            [IsActive],
            [IsApproved],
            [CreatedBy]
        )
        VALUES
        (
            @OrganizationId,
            @IdentityUserId,
            1,
            0,
            @AuditEmail
        );

        SET @OrganizationUserId = SCOPE_IDENTITY();

    END TRY
    BEGIN CATCH

        --------------------------------------------------------
        -- Final protection for UNIQUE(IdentityUserId)
        --------------------------------------------------------

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 53005,
                'The identity user already belongs to an organization.',
                1;
        END;

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Return created user
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
    WHERE [Id] = @OrganizationUserId;
END;
GO