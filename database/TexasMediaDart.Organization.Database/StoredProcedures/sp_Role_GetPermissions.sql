CREATE PROCEDURE [dbo].[sp_Role_GetPermissions]
    @RoleId UNIQUEIDENTIFIER,
    @OrganizationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Validation
    ------------------------------------------------------------

    IF @RoleId IS NULL
    BEGIN
        THROW 54501, 'RoleId is required.', 1;
    END;

    IF @OrganizationId IS NULL
    BEGIN
        THROW 54502, 'OrganizationId is required.', 1;
    END;

    ------------------------------------------------------------
    -- Verify role belongs to organization
    ------------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM [dbo].[Roles]
        WHERE [Id] = @RoleId
          AND [OrganizationId] = @OrganizationId
          AND [IsDeleted] = 0
    )
    BEGIN
        THROW 54503,
            'The role does not exist in this organization.',
            1;
    END;

    ------------------------------------------------------------
    -- Determine modules currently entitled to organization.
    --
    -- A module can theoretically appear in more than one
    -- license, so aggregate by ModuleId.
    ------------------------------------------------------------

    ;WITH EntitledModules AS
    (
        SELECT
            LM.[ModuleId],

            CAST(MAX(CAST(LM.[DefaultCanCreate] AS TINYINT)) AS BIT)
                AS [AllowedCanCreate],

            CAST(MAX(CAST(LM.[DefaultCanUpdate] AS TINYINT)) AS BIT)
                AS [AllowedCanUpdate],

            CAST(MAX(CAST(LM.[DefaultCanDelete] AS TINYINT)) AS BIT)
                AS [AllowedCanDelete],

            CAST(MAX(CAST(LM.[DefaultCanRead] AS TINYINT)) AS BIT)
                AS [AllowedCanRead]

        FROM [dbo].[OrganizationLicenses] OL

        INNER JOIN [dbo].[Licenses] L
            ON L.[Id] = OL.[LicenseId]

        INNER JOIN [dbo].[LicenseModules] LM
            ON LM.[LicenseId] = OL.[LicenseId]

        WHERE OL.[OrganizationId] = @OrganizationId
          AND OL.[IsActive] = 1
          AND L.[IsActive] = 1

          AND OL.[StartUtc] <= SYSUTCDATETIME()

          AND
          (
              OL.[EndUtc] IS NULL
              OR OL.[EndUtc] > SYSUTCDATETIME()
          )

        GROUP BY
            LM.[ModuleId]
    )

    ------------------------------------------------------------
    -- Return every entitled module.
    --
    -- If RolePermissions does not yet contain a row,
    -- role permissions default to 0.
    ------------------------------------------------------------

    SELECT
        @RoleId AS [RoleId],

        M.[Id] AS [ModuleId],
        M.[Code] AS [ModuleCode],
        M.[Name] AS [ModuleName],

        --------------------------------------------------------
        -- Maximum permissions allowed by licensing
        --------------------------------------------------------

        E.[AllowedCanCreate],
        E.[AllowedCanUpdate],
        E.[AllowedCanDelete],
        E.[AllowedCanRead],

        --------------------------------------------------------
        -- Actual role permissions
        --------------------------------------------------------

        CAST(
            CASE
                WHEN RP.[CanCreate] = 1
                 AND E.[AllowedCanCreate] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanCreate],

        CAST(
            CASE
                WHEN RP.[CanUpdate] = 1
                 AND E.[AllowedCanUpdate] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanUpdate],

        CAST(
            CASE
                WHEN RP.[CanDelete] = 1
                 AND E.[AllowedCanDelete] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanDelete],

        CAST(
            CASE
                WHEN RP.[CanRead] = 1
                 AND E.[AllowedCanRead] = 1
                THEN 1
                ELSE 0
            END
            AS BIT
        ) AS [CanRead],

        RP.[CreatedBy],
        RP.[CreatedUtc],
        RP.[ModifiedBy],
        RP.[ModifiedUtc]

    FROM EntitledModules E

    INNER JOIN [dbo].[Modules] M
        ON M.[Id] = E.[ModuleId]

    LEFT JOIN [dbo].[RolePermissions] RP
        ON RP.[RoleId] = @RoleId
       AND RP.[ModuleId] = E.[ModuleId]

    WHERE M.[IsActive] = 1

    ORDER BY
        M.[Name],
        M.[Code];
END;
GO