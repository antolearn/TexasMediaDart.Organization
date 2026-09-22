CREATE PROCEDURE [dbo].[sp_Organization_GetCurrent]
    @IdentityUserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF @IdentityUserId IS NULL
    BEGIN
        THROW 52001, 'IdentityUserId is required.', 1;
    END;

    SELECT
        O.[Id] AS [OrganizationId],
        O.[Name],

        O.[IsActive],
        O.[IsDeleted],

        O.[CreatedBy],
        O.[CreatedUtc],
        O.[ModifiedBy],
        O.[ModifiedUtc],

        OU.[Id] AS [OrganizationUserId],
        OU.[IdentityUserId],

        OU.[IsActive] AS [UserIsActive],
        OU.[IsApproved] AS [UserIsApproved],

        OU.[CreatedBy] AS [UserCreatedBy],
        OU.[CreatedUtc] AS [UserCreatedUtc],

        OU.[ApprovedBy] AS [UserApprovedBy],
        OU.[ApprovedUtc] AS [UserApprovedUtc]

    FROM [dbo].[OrganizationUsers] OU

    INNER JOIN [dbo].[Organizations] O
        ON O.[Id] = OU.[OrganizationId]

    WHERE OU.[IdentityUserId] = @IdentityUserId
      AND O.[IsDeleted] = 0;
END;
GO