CREATE PROCEDURE [dbo].[sp_Contact_GetById]
    @ContactId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF @ContactId IS NULL
    BEGIN
        THROW 51101, 'ContactId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 51102, 'OrganizationId is required.', 1;
    END;

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
      AND [OrganizationId] = @OrganizationId
      AND [IsDeleted] = 0;
END;
GO