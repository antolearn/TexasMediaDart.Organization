CREATE PROCEDURE [dbo].[sp_User_GetEffectiveModulePermissions]
(
    @IdentityUserId UNIQUEIDENTIFIER
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ou.OrganizationId,
        ou.Id AS OrganizationUserId,

        m.Id AS ModuleId,
        m.Code AS ModuleCode,
        m.Name AS ModuleName,
        m.Description,
        m.Route,
        m.IconKey,
        m.MenuGroup,
        m.DisplayOrder,
        m.ShowInMenu,

        CAST(MAX(
            CASE
                WHEN lm.DefaultCanCreate = 1
                 AND rp.CanCreate = 1
                THEN 1 ELSE 0
            END
        ) AS bit) AS CanCreate,

        CAST(MAX(
            CASE
                WHEN lm.DefaultCanUpdate = 1
                 AND rp.CanUpdate = 1
                THEN 1 ELSE 0
            END
        ) AS bit) AS CanUpdate,

        CAST(MAX(
            CASE
                WHEN lm.DefaultCanDelete = 1
                 AND rp.CanDelete = 1
                THEN 1 ELSE 0
            END
        ) AS bit) AS CanDelete,

        CAST(MAX(
            CASE
                WHEN lm.DefaultCanRead = 1
                 AND rp.CanRead = 1
                THEN 1 ELSE 0
            END
        ) AS bit) AS CanRead

    FROM dbo.OrganizationUsers ou

    INNER JOIN dbo.UserRoles ur
        ON ur.OrganizationUserId = ou.Id

    INNER JOIN dbo.Roles r
        ON r.Id = ur.RoleId
        AND r.OrganizationId = ou.OrganizationId
        AND r.IsActive = 1
        AND r.IsDeleted = 0

    INNER JOIN dbo.RolePermissions rp
        ON rp.RoleId = r.Id

    INNER JOIN dbo.Modules m
        ON m.Id = rp.ModuleId
        AND m.IsActive = 1

    INNER JOIN dbo.OrganizationLicenses ol
        ON ol.OrganizationId = ou.OrganizationId
        AND ol.IsActive = 1
        AND ol.StartUtc <= SYSUTCDATETIME()
        AND (
            ol.EndUtc IS NULL
            OR ol.EndUtc > SYSUTCDATETIME()
        )

    INNER JOIN dbo.Licenses l
        ON l.Id = ol.LicenseId
        AND l.IsActive = 1

    INNER JOIN dbo.LicenseModules lm
        ON lm.LicenseId = l.Id
        AND lm.ModuleId = m.Id

    WHERE
        ou.IdentityUserId = @IdentityUserId
        AND ou.IsActive = 1
        AND ou.IsApproved = 1

    GROUP BY
        ou.OrganizationId,
        ou.Id,
        m.Id,
        m.Code,
        m.Name,
        m.Description,
        m.Route,
        m.IconKey,
        m.MenuGroup,
        m.DisplayOrder,
        m.ShowInMenu

    ORDER BY
        m.DisplayOrder,
        m.Name;
END;
GO