CREATE PROCEDURE [dbo].[sp_OrganizationUser_GetCandidateIdentityUserIds]
    @OrganizationId UNIQUEIDENTIFIER,
    @IdentityUserId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT = NULL,
    @IsApproved BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 53301, 'OrganizationId is required.', 1;
    END;

    SELECT
        OU.[IdentityUserId]

    FROM [dbo].[OrganizationUsers] OU

    WHERE OU.[OrganizationId] = @OrganizationId

      AND
      (
          @IdentityUserId IS NULL
          OR OU.[IdentityUserId] = @IdentityUserId
      )

      AND
      (
          @IsActive IS NULL
          OR OU.[IsActive] = @IsActive
      )

      AND
      (
          @IsApproved IS NULL
          OR OU.[IsApproved] = @IsApproved
      )

    ORDER BY OU.[IdentityUserId];
END;
GO