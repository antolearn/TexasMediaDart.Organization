CREATE PROCEDURE [dbo].[sp_Contact_Create]
    @ContactId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,

    @FirstName NVARCHAR(100) = NULL,
    @MiddleName NVARCHAR(100) = NULL,
    @LastName NVARCHAR(100) = NULL,
    @CompanyName NVARCHAR(200) = NULL,

    @Email NVARCHAR(320) = NULL,

    @Phone NVARCHAR(32) = NULL,
    @MobilePhone NVARCHAR(32) = NULL,

    @AddressLine1 NVARCHAR(200) = NULL,
    @AddressLine2 NVARCHAR(200) = NULL,
    @City NVARCHAR(100) = NULL,
    @StateProvince NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(16) = NULL,
    @Country NVARCHAR(32) = NULL,

    @Notes NVARCHAR(512) = NULL,

    @CreatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    ------------------------------------------------------------
    -- Normalized values
    ------------------------------------------------------------

    DECLARE @NormalizedEmail NVARCHAR(320) = NULL;
    DECLARE @AuditEmail NVARCHAR(100);

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@CreatedBy)));

    IF NULLIF(LTRIM(RTRIM(@Email)), '') IS NOT NULL
    BEGIN
        SET @Email =
            LTRIM(RTRIM(@Email));

        SET @NormalizedEmail =
            LOWER(@Email);
    END
    ELSE
    BEGIN
        SET @Email = NULL;
        SET @NormalizedEmail = NULL;
    END;

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @ContactId IS NULL
    BEGIN
        THROW 51001, 'ContactId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 51002, 'OrganizationId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 51003, 'Authenticated user email is required.', 1;
    END;

    ------------------------------------------------------------
    -- Organization validation
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
        THROW 51004,
            'The organization does not exist or is inactive.',
            1;
    END;

    ------------------------------------------------------------
    -- Contact ID validation
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Contacts]
        WHERE [Id] = @ContactId
    )
    BEGIN
        THROW 51005,
            'A contact with this ContactId already exists.',
            1;
    END;

    ------------------------------------------------------------
    -- Friendly duplicate email validation
    --
    -- Database unique index remains the final protection.
    ------------------------------------------------------------

    IF @NormalizedEmail IS NOT NULL
       AND EXISTS
       (
           SELECT 1
           FROM [dbo].[Contacts]
           WHERE [OrganizationId] = @OrganizationId
             AND [NormalizedEmail] = @NormalizedEmail
       )
    BEGIN
        THROW 51006,
            'A contact with this email already exists in the organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Insert
    ------------------------------------------------------------

    BEGIN TRY

        INSERT INTO [dbo].[Contacts]
        (
            [Id],
            [OrganizationId],

            [FirstName],
            [MiddleName],
            [LastName],
            [CompanyName],

            [Email],
            [NormalizedEmail],

            [Phone],
            [MobilePhone],

            [AddressLine1],
            [AddressLine2],
            [City],
            [StateProvince],
            [PostalCode],
            [Country],

            [Notes],

            [IsActive],
            [IsDeleted],

            [CreatedBy]
        )
        VALUES
        (
            @ContactId,
            @OrganizationId,

            NULLIF(LTRIM(RTRIM(@FirstName)), ''),
            NULLIF(LTRIM(RTRIM(@MiddleName)), ''),
            NULLIF(LTRIM(RTRIM(@LastName)), ''),
            NULLIF(LTRIM(RTRIM(@CompanyName)), ''),

            @Email,
            @NormalizedEmail,

            NULLIF(LTRIM(RTRIM(@Phone)), ''),
            NULLIF(LTRIM(RTRIM(@MobilePhone)), ''),

            NULLIF(LTRIM(RTRIM(@AddressLine1)), ''),
            NULLIF(LTRIM(RTRIM(@AddressLine2)), ''),
            NULLIF(LTRIM(RTRIM(@City)), ''),
            NULLIF(LTRIM(RTRIM(@StateProvince)), ''),
            NULLIF(LTRIM(RTRIM(@PostalCode)), ''),
            NULLIF(LTRIM(RTRIM(@Country)), ''),

            NULLIF(LTRIM(RTRIM(@Notes)), ''),

            1,
            0,

            @AuditEmail
        );

    END TRY
    BEGIN CATCH

        --------------------------------------------------------
        -- Unique-index race condition protection
        --------------------------------------------------------

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 51006,
                'A contact with this email already exists in the organization.',
                1;
        END;

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Return created contact
    ------------------------------------------------------------

    SELECT
        [Id],
        [OrganizationId],

        [FirstName],
        [MiddleName],
        [LastName],
        [CompanyName],

        [Email],
        [NormalizedEmail],

        [Phone],
        [MobilePhone],

        [AddressLine1],
        [AddressLine2],
        [City],
        [StateProvince],
        [PostalCode],
        [Country],

        [Notes],

        [IsActive],
        [IsDeleted],

        [CreatedBy],
        [CreatedUtc],
        [ModifiedBy],
        [ModifiedUtc]

    FROM [dbo].[Contacts]
    WHERE [Id] = @ContactId;

END;
GO