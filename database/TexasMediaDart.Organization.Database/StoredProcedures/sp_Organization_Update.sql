CREATE PROCEDURE [dbo].[sp_Organization_Update]
    @IdentityUserId UNIQUEIDENTIFIER,
    @Name           NVARCHAR(200),
    @IsActive       BIT,
    @ModifiedBy     NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @OrganizationId   UNIQUEIDENTIFIER,
        @OrganizationName NVARCHAR(200),
        @AuditEmail       NVARCHAR(100),
        @NowUtc           DATETIME2(7) = SYSUTCDATETIME();

    -------------------------------------------------------------------------
    -- Normalize input
    -------------------------------------------------------------------------

    SET @OrganizationName =
        NULLIF(LTRIM(RTRIM(@Name)), '');

    SET @AuditEmail =
        LOWER(NULLIF(LTRIM(RTRIM(@ModifiedBy)), ''));

    -------------------------------------------------------------------------
    -- Validate input
    -------------------------------------------------------------------------

    IF @IdentityUserId IS NULL
        OR @IdentityUserId = '00000000-0000-0000-0000-000000000000'
    BEGIN
        THROW 52100,
            'IdentityUserId is required.',
            1;
    END;

    IF @OrganizationName IS NULL
    BEGIN
        THROW 52101,
            'Organization name is required.',
            1;
    END;

    IF LEN(@OrganizationName) > 200
    BEGIN
        THROW 52102,
            'Organization name cannot exceed 200 characters.',
            1;
    END;

    IF @AuditEmail IS NULL
    BEGIN
        THROW 52103,
            'Authenticated user email is required.',
            1;
    END;

    -------------------------------------------------------------------------
    -- Resolve organization from authenticated user
    --
    -- Important:
    -- We intentionally do not require the organization to currently be
    -- active here. This allows the procedure to identify the organization
    -- while processing an active/inactive state transition.
    -------------------------------------------------------------------------

    SELECT
        @OrganizationId = OU.[OrganizationId]
    FROM [dbo].[OrganizationUsers] OU
    INNER JOIN [dbo].[Organizations] O
        ON O.[Id] = OU.[OrganizationId]
    WHERE OU.[IdentityUserId] = @IdentityUserId
      AND OU.[IsActive] = 1
      AND O.[IsDeleted] = 0;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 52104,
            'No organization is associated with the authenticated user.',
            1;
    END;

    -------------------------------------------------------------------------
    -- Organization name must remain unique
    -------------------------------------------------------------------------

    IF EXISTS
    (
        SELECT 1
        FROM [dbo].[Organizations]
        WHERE [Name] = @OrganizationName
          AND [Id] <> @OrganizationId
    )
    BEGIN
        THROW 52105,
            'An organization with this name already exists.',
            1;
    END;

    -------------------------------------------------------------------------
    -- Update organization
    -------------------------------------------------------------------------

    BEGIN TRY

        BEGIN TRANSACTION;

        ---------------------------------------------------------------------
        -- Revalidate organization while holding update lock
        ---------------------------------------------------------------------

        IF NOT EXISTS
        (
            SELECT 1
            FROM [dbo].[Organizations] WITH (UPDLOCK, HOLDLOCK)
            WHERE [Id] = @OrganizationId
              AND [IsDeleted] = 0
        )
        BEGIN
            THROW 52104,
                'No organization is associated with the authenticated user.',
                1;
        END;

        ---------------------------------------------------------------------
        -- Recheck organization-name uniqueness inside transaction
        ---------------------------------------------------------------------

        IF EXISTS
        (
            SELECT 1
            FROM [dbo].[Organizations] WITH (UPDLOCK, HOLDLOCK)
            WHERE [Name] = @OrganizationName
              AND [Id] <> @OrganizationId
        )
        BEGIN
            THROW 52105,
                'An organization with this name already exists.',
                1;
        END;

        ---------------------------------------------------------------------
        -- Update
        ---------------------------------------------------------------------

        UPDATE [dbo].[Organizations]
        SET
            [Name] = @OrganizationName,
            [IsActive] = @IsActive,
            [ModifiedBy] = @AuditEmail,
            [ModifiedUtc] = @NowUtc
        WHERE [Id] = @OrganizationId
          AND [IsDeleted] = 0;

        ---------------------------------------------------------------------
        -- Return updated organization
        --
        -- Column aliases intentionally match CurrentOrganizationDto.
        ---------------------------------------------------------------------

        SELECT
            O.[Id] AS [OrganizationId],
            O.[Name],
            O.[IsActive],

            OU.[Id] AS [OrganizationUserId],
            OU.[IdentityUserId],

            OU.[IsActive] AS [UserIsActive],
            OU.[IsApproved] AS [UserIsApproved],

            O.[CreatedBy],
            O.[CreatedUtc],
            O.[ModifiedBy],
            O.[ModifiedUtc]

        FROM [dbo].[Organizations] O

        INNER JOIN [dbo].[OrganizationUsers] OU
            ON OU.[OrganizationId] = O.[Id]

        WHERE O.[Id] = @OrganizationId
          AND OU.[IdentityUserId] = @IdentityUserId;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        ---------------------------------------------------------------------
        -- Preserve explicit business errors
        ---------------------------------------------------------------------

        IF ERROR_NUMBER() BETWEEN 52100 AND 52199
        BEGIN
            THROW;
        END;

        ---------------------------------------------------------------------
        -- Handle unique constraint race condition
        ---------------------------------------------------------------------

        IF ERROR_NUMBER() IN (2601, 2627)
        BEGIN
            THROW 52105,
                'An organization with this name already exists.',
                1;
        END;

        THROW;

    END CATCH;
END;
GO