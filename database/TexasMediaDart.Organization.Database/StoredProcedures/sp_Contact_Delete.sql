CREATE PROCEDURE [dbo].[sp_Contact_Delete]
    @ContactId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER,
    @ModifiedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@ModifiedBy)));

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @ContactId IS NULL
    BEGIN
        THROW 51301, 'ContactId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 51302, 'OrganizationId is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 51303, 'Authenticated user email is required.', 1;
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
        THROW 51304,
            'The contact does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Soft delete
    ------------------------------------------------------------

    UPDATE [dbo].[Contacts]
    SET
        [IsDeleted] = 1,
        [IsActive] = 0,
        [ModifiedBy] = @AuditEmail,
        [ModifiedUtc] = SYSUTCDATETIME()
    WHERE [Id] = @ContactId
      AND [OrganizationId] = @OrganizationId
      AND [IsDeleted] = 0;

    ------------------------------------------------------------
    -- Return deleted record state
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