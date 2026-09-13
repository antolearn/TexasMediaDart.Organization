MERGE dbo.LicenseModules AS Target
USING
(
    SELECT
        L.Id AS LicenseId,
        M.Id AS ModuleId,
        X.DefaultCanCreate,
        X.DefaultCanUpdate,
        X.DefaultCanDelete,
        X.DefaultCanRead
    FROM
    (
        VALUES
            ('CORE', 'ORGANIZATION',      0, 1, 0, 1),
            ('CORE', 'USERS',             1, 1, 1, 1),
            ('CORE', 'USER_GROUPS',       1, 1, 1, 1),
            ('CORE', 'ROLES',             1, 1, 1, 1),
            ('CORE', 'PERMISSIONS',       1, 1, 1, 1),
            ('CORE', 'LICENSES',          0, 0, 0, 1),
            ('CORE', 'CONTACT',           1, 1, 1, 1),

            ('MEDIA', 'PROPERTY',         1, 1, 1, 1),
            ('MEDIA', 'CHANNEL',          1, 1, 1, 1),
            ('MEDIA', 'STATION',          1, 1, 1, 1),
            ('MEDIA', 'NETWORK',          1, 1, 1, 1),
            ('MEDIA', 'MARKET',           1, 1, 1, 1),

            ('CRM', 'ADVERTISER',         1, 1, 1, 1),
            ('CRM', 'AGENCY',             1, 1, 1, 1),
            ('CRM', 'ACCOUNT_EXECUTIVE',  1, 1, 1, 1),
            ('CRM', 'CRM_CODES',          1, 1, 1, 1),

            ('SALES', 'SALES_CODES',      1, 1, 1, 1),
            ('SALES', 'PROPOSAL',         1, 1, 1, 1),
            ('SALES', 'DEALS',            1, 1, 1, 1),
            ('SALES', 'ORDER',            1, 1, 1, 1),

            ('S_AND_P', 'CLEARANCE',      1, 1, 1, 1),

            ('BILLING', 'INVOICE',        1, 1, 1, 1),
            ('BILLING', 'PAYMENTS',       1, 1, 1, 1),

            ('WORKFLOW', 'TASK',          1, 1, 1, 1),
            ('WORKFLOW', 'NOTIFICATIONS', 1, 1, 1, 1),
            ('WORKFLOW', 'APPROVALS',     1, 1, 1, 1)
    ) AS X
    (
        LicenseCode,
        ModuleCode,
        DefaultCanCreate,
        DefaultCanUpdate,
        DefaultCanDelete,
        DefaultCanRead
    )
    INNER JOIN dbo.Licenses L
        ON L.Code = X.LicenseCode
    INNER JOIN dbo.Modules M
        ON M.Code = X.ModuleCode
) AS Source
ON
    Target.LicenseId = Source.LicenseId
    AND Target.ModuleId = Source.ModuleId

WHEN MATCHED THEN
    UPDATE SET
        Target.DefaultCanCreate = Source.DefaultCanCreate,
        Target.DefaultCanUpdate = Source.DefaultCanUpdate,
        Target.DefaultCanDelete = Source.DefaultCanDelete,
        Target.DefaultCanRead   = Source.DefaultCanRead

WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        LicenseId,
        ModuleId,
        DefaultCanCreate,
        DefaultCanUpdate,
        DefaultCanDelete,
        DefaultCanRead
    )
    VALUES
    (
        Source.LicenseId,
        Source.ModuleId,
        Source.DefaultCanCreate,
        Source.DefaultCanUpdate,
        Source.DefaultCanDelete,
        Source.DefaultCanRead
    );