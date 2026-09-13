CREATE PROCEDURE [dbo].[sp_Organization_GetById]
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 52201, 'OrganizationId is required.', 1;
    END;

    ------------------------------------------------------------
    -- Return organization
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

    WHERE [Id] = @OrganizationId
      AND [IsDeleted] = 0;
END;
GO