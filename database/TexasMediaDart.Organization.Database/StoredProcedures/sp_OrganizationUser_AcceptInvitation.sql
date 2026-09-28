CREATE PROCEDURE [dbo].[sp_OrganizationUser_AcceptInvitation]
    @OrganizationId UNIQUEIDENTIFIER,
    @IdentityUserId UNIQUEIDENTIFIER,
    @CreatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);
    DECLARE @OrganizationUserId BIGINT;
    DECLARE @ExistingOrganizationId UNIQUEIDENTIFIER;

    ------------------------------------------------------------
    -- Normalize audit value
    ------------------------------------------------------------

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@CreatedBy)));

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 53101, 'OrganizationId is required.', 1;
    END;

    IF @IdentityUserId IS NULL
    BEGIN
        THROW 53102, 'IdentityUserId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 53103, 'CreatedBy is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify target organization exists and is active
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
        THROW 53104,
            'The organization does not exist or is inactive.',
            1;
    END;

    ------------------------------------------------------------
    -- Create or recover invitation membership atomically
    ------------------------------------------------------------

    BEGIN TRANSACTION;

    BEGIN TRY

        --------------------------------------------------------
        -- Serialize membership creation for this Identity user.
        --
        -- IdentityUserId is globally unique in OrganizationUsers.
        --------------------------------------------------------

        SELECT
            @OrganizationUserId = [Id],
            @ExistingOrganizationId = [OrganizationId]
        FROM [dbo].[OrganizationUsers] WITH (UPDLOCK, HOLDLOCK)
        WHERE [IdentityUserId] = @IdentityUserId;

        --------------------------------------------------------
        -- Existing membership
        --------------------------------------------------------

        IF @OrganizationUserId IS NOT NULL
        BEGIN
            IF @ExistingOrganizationId <> @OrganizationId
            BEGIN
                THROW 53105,
                    'The identity user already belongs to another organization.',
                    1;
            END;

            ----------------------------------------------------
            -- Same organization.
            -- Treat as successful idempotent retry.
            ----------------------------------------------------

            COMMIT TRANSACTION;

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

            RETURN;
        END;

        --------------------------------------------------------
        -- No membership exists. Create pending membership.
        --------------------------------------------------------

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

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        --------------------------------------------------------
        -- Final protection for UNIQUE(IdentityUserId)
        --------------------------------------------------------

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 53105,
                'The identity user already belongs to an organization.',
                1;
        END;

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Return newly created membership
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