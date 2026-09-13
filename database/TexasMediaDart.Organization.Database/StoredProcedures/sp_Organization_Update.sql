CREATE PROCEDURE [dbo].[sp_Organization_Update]
    @OrganizationId UNIQUEIDENTIFIER,
    @Name NVARCHAR(200),
    @ModifiedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AuditEmail NVARCHAR(100);
    DECLARE @NormalizedName NVARCHAR(200);

    ------------------------------------------------------------
    -- Normalize input
    ------------------------------------------------------------

    SET @AuditEmail =
        LOWER(LTRIM(RTRIM(@ModifiedBy)));

    SET @NormalizedName =
        NULLIF(LTRIM(RTRIM(@Name)), '');

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 52101, 'OrganizationId is required.', 1;
    END;

    IF @NormalizedName IS NULL
    BEGIN
        THROW 52102, 'Organization name is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 52103, 'Authenticated user email is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify organization exists
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Organizations]
        WHERE [Id] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 52104,
            'The organization does not exist.',
            1;
    END;

    ------------------------------------------------------------
    -- Enforce global organization-name uniqueness
    ------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Organizations]
        WHERE [Name] = @NormalizedName
          AND [Id] <> @OrganizationId
    )
    BEGIN
        THROW 52105,
            'An organization with this name already exists.',
            1;
    END;

    ------------------------------------------------------------
    -- Update
    ------------------------------------------------------------

    BEGIN TRY

        UPDATE [dbo].[Organizations]
        SET
            [Name] = @NormalizedName,
            [ModifiedBy] = @AuditEmail,
            [ModifiedUtc] = SYSUTCDATETIME()
        WHERE [Id] = @OrganizationId
          AND [IsDeleted] = 0;

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 52105,
                'An organization with this name already exists.',
                1;
        END;

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Return updated organization
    ------------------------------------------------------------

    SELECT
        [Id] AS [OrganizationId],
        [Name],
        [IsActive],
        [IsDeleted],
        [CreatedBy],
        [CreatedUtc],
        [ModifiedBy],
        [ModifiedUtc]
    FROM [dbo].[Organizations]
    WHERE [Id] = @OrganizationId;
END;
GO