CREATE PROCEDURE [dbo].[sp_UserPermission_GetEffectiveByModuleCode]
    @OrganizationId UNIQUEIDENTIFIER,
    @IdentityUserId UNIQUEIDENTIFIER,
    @ModuleCode NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OrganizationUserId BIGINT;
    DECLARE @NormalizedModuleCode NVARCHAR(50);

    ------------------------------------------------------------
    -- Normalize
    ------------------------------------------------------------

    SET @NormalizedModuleCode =
        UPPER(NULLIF(LTRIM(RTRIM(@ModuleCode)), ''));

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @OrganizationId IS NULL
    BEGIN
        THROW 56401, 'OrganizationId is required.', 1;
    END;

    IF @IdentityUserId IS NULL
    BEGIN
        THROW 56402, 'IdentityUserId is required.', 1;
    END;

    IF @NormalizedModuleCode IS NULL
    BEGIN
        THROW 56403, 'ModuleCode is required.', 1;
    END;

    ------------------------------------------------------------
    -- Resolve active + approved organization user
    ------------------------------------------------------------

    SELECT
        @OrganizationUserId = OU.[Id]
    FROM [dbo].[OrganizationUsers] OU
    WHERE OU.[OrganizationId] = @OrganizationId
      AND OU.[IdentityUserId] = @IdentityUserId
      AND OU.[IsActive] = 1
      AND OU.[IsApproved] = 1;

    IF @OrganizationUserId IS NULL
    BEGIN
        THROW 56404,
            'The user is not an active and approved member of this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Find requested active module
    ------------------------------------------------------------

    DECLARE @ModuleId INT;

    SELECT
        @ModuleId = M.[Id]
    FROM [dbo].[Modules] M
    WHERE UPPER(M.[Code]) = @NormalizedModuleCode
      AND M.[IsActive] = 1;

    IF @ModuleId IS NULL
    BEGIN
        THROW 56405,
            'The requested module does not exist or is inactive.',
            1;
    END;

    ------------------------------------------------------------
    -- Calculate organization entitlement
    ------------------------------------------------------------

    DECLARE @AllowedCanCreate BIT = 0;
    DECLARE @AllowedCanUpdate BIT = 0;
    DECLARE @AllowedCanDelete BIT = 0;
    DECLARE @AllowedCanRead BIT = 0;

    SELECT
        @AllowedCanCreate =
            CAST(MAX(CAST(LM.[DefaultCanCreate] AS TINYINT)) AS BIT),

        @AllowedCanUpdate =
            CAST(MAX(CAST(LM.[DefaultCanUpdate] AS TINYINT)) AS BIT),

        @AllowedCanDelete =
            CAST(MAX(CAST(LM.[DefaultCanDelete] AS TINYINT)) AS BIT),

        @AllowedCanRead =
            CAST(MAX(CAST(LM.[DefaultCanRead] AS TINYINT)) AS BIT)

    FROM [dbo].[OrganizationLicenses] OL

    INNER JOIN [dbo].[Licenses] L
        ON L.[Id] = OL.[LicenseId]

    INNER JOIN [dbo].[LicenseModules] LM
        ON LM.[LicenseId] = OL.[LicenseId]

    WHERE OL.[OrganizationId] = @OrganizationId
      AND LM.[ModuleId] = @ModuleId

      AND OL.[IsActive] = 1
      AND L.[IsActive] = 1

      AND OL.[StartUtc] <= SYSUTCDATETIME()

      AND
      (
          OL.[EndUtc] IS NULL
          OR OL.[EndUtc] > SYSUTCDATETIME()
      );

    ------------------------------------------------------------
    -- Organization does not have this module licensed
    ------------------------------------------------------------

    IF ISNULL(@AllowedCanCreate, 0) = 0
       AND ISNULL(@AllowedCanUpdate, 0) = 0
       AND ISNULL(@AllowedCanDelete, 0) = 0
       AND ISNULL(@AllowedCanRead, 0) = 0
    BEGIN
        RETURN;
    END;

    ------------------------------------------------------------
    -- Calculate combined role permissions
    ------------------------------------------------------------

    DECLARE @RoleCanCreate BIT = 0;
    DECLARE @RoleCanUpdate BIT = 0;
    DECLARE @RoleCanDelete BIT = 0;
    DECLARE @RoleCanRead BIT = 0;

    SELECT
        @RoleCanCreate =
            CAST(MAX(CAST(RP.[CanCreate] AS TINYINT)) AS BIT),

        @RoleCanUpdate =
            CAST(MAX(CAST(RP.[CanUpdate] AS TINYINT)) AS BIT),

        @RoleCanDelete =
            CAST(MAX(CAST(RP.[CanDelete] AS TINYINT)) AS BIT),

        @RoleCanRead =
            CAST(MAX(CAST(RP.[CanRead] AS TINYINT)) AS BIT)

    FROM [dbo].[UserRoles] UR

    INNER JOIN [dbo].[Roles] R
        ON R.[Id] = UR.[RoleId]

    INNER JOIN [dbo].[RolePermissions] RP
        ON RP.[RoleId] = R.[Id]

    WHERE UR.[OrganizationUserId] = @OrganizationUserId

      AND R.[OrganizationId] = @OrganizationId

      AND R.[IsActive] = 1
      AND R.[IsDeleted] = 0
      AND R.[IsApproved] = 1

      AND RP.[ModuleId] = @ModuleId;

    ------------------------------------------------------------
    -- Return final effective permission
    ------------------------------------------------------------

    SELECT
        @OrganizationUserId AS [OrganizationUserId],
        @IdentityUserId AS [IdentityUserId],

        M.[Id] AS [ModuleId],
        M.[Code] AS [ModuleCode],
        M.[Name] AS [ModuleName],

        CAST
        (
            CASE
                WHEN ISNULL(@AllowedCanCreate, 0) = 1
                 AND ISNULL(@RoleCanCreate, 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanCreate],

        CAST
        (
            CASE
                WHEN ISNULL(@AllowedCanUpdate, 0) = 1
                 AND ISNULL(@RoleCanUpdate, 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanUpdate],

        CAST
        (
            CASE
                WHEN ISNULL(@AllowedCanDelete, 0) = 1
                 AND ISNULL(@RoleCanDelete, 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanDelete],

        CAST
        (
            CASE
                WHEN ISNULL(@AllowedCanRead, 0) = 1
                 AND ISNULL(@RoleCanRead, 0) = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanRead]

    FROM [dbo].[Modules] M
    WHERE M.[Id] = @ModuleId;
END;
GO