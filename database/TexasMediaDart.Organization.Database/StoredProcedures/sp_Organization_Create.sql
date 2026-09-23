CREATE PROCEDURE [dbo].[sp_Organization_Create]
    @OrganizationId UNIQUEIDENTIFIER,
    @Name             NVARCHAR(200),
    @IdentityUserId   UNIQUEIDENTIFIER,
    @UserEmail        NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @NowUtc              DATETIME2(7) = SYSUTCDATETIME(),
        @AuditEmail          NVARCHAR(100),
        @OrganizationName    NVARCHAR(200),
        @CoreLicenseId       INT,
        @OrganizationUserId  BIGINT,
        @OwnerRoleId         UNIQUEIDENTIFIER = NEWID();

    -------------------------------------------------------------------------
    -- Normalize input
    -------------------------------------------------------------------------

    SET @OrganizationName = LTRIM(RTRIM(@Name));
    SET @AuditEmail = LOWER(LTRIM(RTRIM(@UserEmail)));

    -------------------------------------------------------------------------
    -- Validate input
    -------------------------------------------------------------------------

    IF @OrganizationId IS NULL
        OR @OrganizationId = '00000000-0000-0000-0000-000000000000'
    BEGIN
        THROW 51000, 'OrganizationId is required.', 1;
    END;

    IF @IdentityUserId IS NULL
        OR @IdentityUserId = '00000000-0000-0000-0000-000000000000'
    BEGIN
        THROW 51000, 'IdentityUserId is required.', 1;
    END;

    IF NULLIF(@OrganizationName, '') IS NULL
    BEGIN
        THROW 51000, 'Organization name is required.', 1;
    END;

    IF NULLIF(@AuditEmail, '') IS NULL
    BEGIN
        THROW 51000, 'User email is required.', 1;
    END;

    -------------------------------------------------------------------------
    -- Business validation
    --
    -- 51001 = Identity user already belongs to an organization
    -- 51002 = Organization name already exists
    -------------------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[OrganizationUsers]
        WHERE [IdentityUserId] = @IdentityUserId
    )
    BEGIN
        THROW 51001,
            'The authenticated user already belongs to an organization.',
            1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Organizations]
        WHERE [Name] = @OrganizationName
    )
    BEGIN
        THROW 51002,
            'An organization with this name already exists.',
            1;
    END;

    -------------------------------------------------------------------------
    -- Get CORE license
    -------------------------------------------------------------------------

    SELECT
        @CoreLicenseId = [Id]
    FROM [dbo].[Licenses]
    WHERE [Code] = N'CORE'
      AND [IsActive] = 1;

    IF @CoreLicenseId IS NULL
    BEGIN
        THROW 51003,
            'The CORE license is not configured.',
            1;
    END;

    BEGIN TRY

        BEGIN TRANSACTION;

        ---------------------------------------------------------------------
        -- Recheck business rules inside the transaction.
        --
        -- These checks reduce race-condition exposure. The unique
        -- constraints remain the final database-level protection.
        ---------------------------------------------------------------------

        IF EXISTS
        (
            SELECT 1
            FROM [dbo].[OrganizationUsers] WITH (UPDLOCK, HOLDLOCK)
            WHERE [IdentityUserId] = @IdentityUserId
        )
        BEGIN
            THROW 51001,
                'The authenticated user already belongs to an organization.',
                1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM [dbo].[Organizations] WITH (UPDLOCK, HOLDLOCK)
            WHERE [Name] = @OrganizationName
        )
        BEGIN
            THROW 51002,
                'An organization with this name already exists.',
                1;
        END;

        ---------------------------------------------------------------------
        -- Create Organization
        ---------------------------------------------------------------------

        INSERT INTO [dbo].[Organizations]
        (
            [Id],
            [Name],
            [IsActive],
            [IsDeleted],
            [CreatedBy],
            [CreatedUtc]
        )
        VALUES
        (
            @OrganizationId,
            @OrganizationName,
            1,
            0,
            @AuditEmail,
            @NowUtc
        );

        ---------------------------------------------------------------------
        -- Create Organization User
        --
        -- The organization creator becomes the initial Owner, so the user
        -- is automatically approved during bootstrap.
        ---------------------------------------------------------------------

        INSERT INTO [dbo].[OrganizationUsers]
        (
            [OrganizationId],
            [IdentityUserId],
            [IsActive],
            [IsApproved],
            [CreatedBy],
            [CreatedUtc],
            [ApprovedBy],
            [ApprovedUtc]
        )
        VALUES
        (
            @OrganizationId,
            @IdentityUserId,
            1,
            1,
            @AuditEmail,
            @NowUtc,
            @AuditEmail,
            @NowUtc
        );

        SET @OrganizationUserId = SCOPE_IDENTITY();

        ---------------------------------------------------------------------
        -- Assign CORE license
        ---------------------------------------------------------------------

        INSERT INTO [dbo].[OrganizationLicenses]
        (
            [OrganizationId],
            [LicenseId],
            [IsActive],
            [StartUtc],
            [EndUtc],
            [CreatedBy],
            [CreatedUtc]
        )
        VALUES
        (
            @OrganizationId,
            @CoreLicenseId,
            1,
            @NowUtc,
            NULL,
            @AuditEmail,
            @NowUtc
        );

        ---------------------------------------------------------------------
        -- Create system Owner role
        ---------------------------------------------------------------------

        INSERT INTO [dbo].[Roles]
        (
            [Id],
            [OrganizationId],
            [Name],
            [Description],
            [IsSystemRole],
            [IsActive],
            [IsDeleted],
            [IsApproved],
            [CreatedBy],
            [CreatedUtc],
            [ApprovedBy],
            [ApprovedUtc]
        )
        VALUES
        (
            @OwnerRoleId,
            @OrganizationId,
            N'Owner',
            N'Organization owner system role.',
            1,
            1,
            0,
            1,
            @AuditEmail,
            @NowUtc,
            @AuditEmail,
            @NowUtc
        );

        ---------------------------------------------------------------------
        -- Seed Owner permissions from CORE license entitlement
        --
        -- CRUD/read permissions are initialized from LicenseModules.
        --
        -- Approval is intentionally initialized to 0 because a newly
        -- created organization receives only the CORE license.
        --
        -- Approval requires:
        --
        --   Module.SupportsApprove = 1
        --       +
        --   active WORKFLOW / APPROVALS entitlement
        --       +
        --   RolePermissions.CanApprove = 1
        --
        -- When WORKFLOW or another license is assigned later, the
        -- license-assignment process is responsible for expanding the
        -- Owner role permissions for newly entitled modules/actions.
        ---------------------------------------------------------------------

        INSERT INTO [dbo].[RolePermissions]
        (
            [RoleId],
            [ModuleId],
            [CanCreate],
            [CanUpdate],
            [CanDelete],
            [CanRead],
            [CanApprove],
            [CreatedBy],
            [CreatedUtc]
        )
        SELECT
            @OwnerRoleId,
            LM.[ModuleId],
            LM.[DefaultCanCreate],
            LM.[DefaultCanUpdate],
            LM.[DefaultCanDelete],
            LM.[DefaultCanRead],

            -- CORE does not enable approval functionality.
            CAST(0 AS BIT) AS [CanApprove],

            @AuditEmail,
            @NowUtc

        FROM [dbo].[LicenseModules] LM

        INNER JOIN [dbo].[Modules] M
            ON M.[Id] = LM.[ModuleId]

        WHERE LM.[LicenseId] = @CoreLicenseId
          AND M.[IsActive] = 1;

        ---------------------------------------------------------------------
        -- Assign Owner role to organization creator
        ---------------------------------------------------------------------

        INSERT INTO [dbo].[UserRoles]
        (
            [OrganizationUserId],
            [RoleId],
            [CreatedBy],
            [CreatedUtc]
        )
        VALUES
        (
            @OrganizationUserId,
            @OwnerRoleId,
            @AuditEmail,
            @NowUtc
        );

        COMMIT TRANSACTION;

        ---------------------------------------------------------------------
        -- Return bootstrap result
        --
        -- Column names intentionally match CreateOrganizationResultDto.
        ---------------------------------------------------------------------

        SELECT
            @OrganizationId       AS [OrganizationId],
            @OrganizationName     AS [Name],
            @OrganizationUserId   AS [OrganizationUserId],
            @IdentityUserId       AS [IdentityUserId],
            @OwnerRoleId          AS [RoleId],
            N'Owner'              AS [RoleName],
            N'CORE'               AS [LicenseCode],
            @AuditEmail           AS [CreatedBy];

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        ---------------------------------------------------------------------
        -- Preserve our explicit business error numbers.
        ---------------------------------------------------------------------

        IF ERROR_NUMBER() BETWEEN 51000 AND 51099
        BEGIN
            THROW;
        END;

        ---------------------------------------------------------------------
        -- Handle unique-constraint race conditions.
        --
        -- 2601 = duplicate key in unique index
        -- 2627 = unique constraint violation
        ---------------------------------------------------------------------

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM [dbo].[OrganizationUsers]
                WHERE [IdentityUserId] = @IdentityUserId
            )
            BEGIN
                THROW 51001,
                    'The authenticated user already belongs to an organization.',
                    1;
            END;

            IF EXISTS
            (
                SELECT 1
                FROM [dbo].[Organizations]
                WHERE [Name] = @OrganizationName
            )
            BEGIN
                THROW 51002,
                    'An organization with this name already exists.',
                    1;
            END;

            THROW 51004,
                'The organization could not be created because of a data conflict.',
                1;
        END;

        THROW;

    END CATCH;
END;
GO