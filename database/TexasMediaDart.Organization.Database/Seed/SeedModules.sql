MERGE dbo.Modules AS Target
USING
(
    VALUES
        ('ORGANIZATION',      'Organization',       'Organization profile and settings', 1),
        ('USERS',             'Users',              'Organization users', 1),
        ('USER_GROUPS',       'User Groups',        'User group management', 1),
        ('ROLES',             'Roles',              'Role management', 1),
        ('PERMISSIONS',       'Permissions',        'Permission management', 1),
        ('LICENSES',          'Licenses',           'Organization license information', 1),
        ('CONTACT',           'Contact',            'Contact management', 1),

        ('PROPERTY',          'Property',           'Media properties', 1),
        ('CHANNEL',           'Channel',            'Media channels', 1),
        ('STATION',           'Station',            'Media stations', 1),
        ('NETWORK',           'Network',            'Media networks', 1),
        ('MARKET',            'Market',             'Media markets', 1),

        ('ADVERTISER',        'Advertiser',         'Advertiser management', 1),
        ('AGENCY',            'Agency',             'Agency management', 1),
        ('ACCOUNT_EXECUTIVE', 'Account Executive',  'Account executive management', 1),
        ('CRM_CODES',         'CRM Codes',          'CRM reference codes', 1),

        ('SALES_CODES',       'Sales Codes',        'Sales reference codes', 1),
        ('PROPOSAL',          'Proposal',           'Proposal management', 1),
        ('DEALS',             'Deals',              'Deal management', 1),
        ('ORDER',             'Order',              'Order management', 1),

        ('CLEARANCE',         'Clearance',          'Standards and practices clearance', 1),

        ('INVOICE',           'Invoice',            'Invoice management', 1),
        ('PAYMENTS',          'Payments',           'Payment management', 1),

        ('TASK',              'Task',               'Task management', 1),
        ('NOTIFICATIONS',     'Notifications',      'Notification management', 1),
        ('APPROVALS',         'Approvals',          'Approval workflow', 1)
) AS Source
(
    Code,
    Name,
    Description,
    IsActive
)
ON Target.Code = Source.Code

WHEN MATCHED THEN
    UPDATE SET
        Target.Name        = Source.Name,
        Target.Description = Source.Description,
        Target.IsActive    = Source.IsActive

WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        Code,
        Name,
        Description,
        IsActive
    )
    VALUES
    (
        Source.Code,
        Source.Name,
        Source.Description,
        Source.IsActive
    );