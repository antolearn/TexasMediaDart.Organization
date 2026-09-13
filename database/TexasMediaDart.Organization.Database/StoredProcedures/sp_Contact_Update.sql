CREATE PROCEDURE [dbo].[sp_Contact_Update]
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

    @IsActive BIT,

    @ModifiedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NormalizedEmail NVARCHAR(320) = NULL;
    DECLARE @AuditEmail NVARCHAR(100);

    ------------------------------------------------------------
    -- Normalize input
    ------------------------------------------------------------

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@ModifiedBy)));

    IF NULLIF(LTRIM(RTRIM(@Email)), '') IS NOT NULL
    BEGIN
        SET @Email = LTRIM(RTRIM(@Email));
        SET @NormalizedEmail = LOWER(@Email);
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
        THROW 51201, 'ContactId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 51202, 'OrganizationId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 51203, 'Authenticated user email is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify contact belongs to organization
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Contacts]
        WHERE [Id] = @ContactId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 51204,
            'The contact does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Friendly duplicate email check
    ------------------------------------------------------------

    IF @NormalizedEmail IS NOT NULL
       AND EXISTS
       (
           SELECT 1
           FROM [dbo].[Contacts]
           WHERE [OrganizationId] = @OrganizationId
             AND [NormalizedEmail] = @NormalizedEmail
             AND [Id] <> @ContactId
       )
    BEGIN
        THROW 51205,
            'A contact with this email already exists in the organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Update
    ------------------------------------------------------------

    BEGIN TRY

        UPDATE [dbo].[Contacts]
        SET
            [FirstName] =
                NULLIF(LTRIM(RTRIM(@FirstName)), ''),

            [MiddleName] =
                NULLIF(LTRIM(RTRIM(@MiddleName)), ''),

            [LastName] =
                NULLIF(LTRIM(RTRIM(@LastName)), ''),

            [CompanyName] =
                NULLIF(LTRIM(RTRIM(@CompanyName)), ''),

            [Email] =
                @Email,

            [NormalizedEmail] =
                @NormalizedEmail,

            [Phone] =
                NULLIF(LTRIM(RTRIM(@Phone)), ''),

            [MobilePhone] =
                NULLIF(LTRIM(RTRIM(@MobilePhone)), ''),

            [AddressLine1] =
                NULLIF(LTRIM(RTRIM(@AddressLine1)), ''),

            [AddressLine2] =
                NULLIF(LTRIM(RTRIM(@AddressLine2)), ''),

            [City] =
                NULLIF(LTRIM(RTRIM(@City)), ''),

            [StateProvince] =
                NULLIF(LTRIM(RTRIM(@StateProvince)), ''),

            [PostalCode] =
                NULLIF(LTRIM(RTRIM(@PostalCode)), ''),

            [Country] =
                NULLIF(LTRIM(RTRIM(@Country)), ''),

            [Notes] =
                NULLIF(LTRIM(RTRIM(@Notes)), ''),

            [IsActive] =
                @IsActive,

            [ModifiedBy] =
                @AuditEmail,

            [ModifiedUtc] =
                SYSUTCDATETIME()

        WHERE [Id] = @ContactId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0;

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 51205,
                'A contact with this email already exists in the organization.',
                1;
        END;

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Return updated contact
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
    WHERE [Id] = @ContactId
      AND [OrganizationId] = @OrganizationId;
END;
GO