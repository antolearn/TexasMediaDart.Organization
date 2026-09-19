MERGE dbo.Modules AS Target
USING
(
    VALUES
        -- CORE
        ('ORGANIZATION',      'Organization',      'Organization profile and settings',       '/organization',    'business',             'Administration', 10,  1, 1),
        ('USERS',             'Users',             'Organization users',                      '/users',           'people',               'Administration', 20,  1, 1),
        ('USER_GROUPS',       'User Groups',       'User group management',                   '/user-groups',     'groups',               'Administration', 30,  1, 1),
        ('ROLES',             'Roles',             'Role management',                         '/roles',           'security',             'Administration', 40,  1, 1),
        ('PERMISSIONS',       'Permissions',       'Permission management',                   '/permissions',     'admin_panel_settings', 'Administration', 50,  1, 1),
        ('LICENSES',          'Licenses',          'Organization license information',         '/licenses',        'key',                  'Administration', 60,  1, 1),
        ('CONTACT',           'Contact',           'Contact management',                      '/contacts',        'contacts',             'CRM',            100,  1, 1),

        -- MEDIA
        ('PROPERTY',          'Property',          'Media properties',                        '/properties',      'domain',               'Media',          200,  1, 1),
        ('CHANNEL',           'Channel',           'Media channels',                          '/channels',        'live_tv',              'Media',          210,  1, 1),
        ('STATION',           'Station',           'Media stations',                          '/stations',        'radio',                'Media',          220,  1, 1),
        ('NETWORK',           'Network',           'Media networks',                          '/networks',        'hub',                  'Media',          230,  1, 1),
        ('MARKET',            'Market',            'Media markets',                           '/markets',         'location_city',        'Media',          240,  1, 1),

        -- CRM
        ('ADVERTISER',        'Advertiser',        'Advertiser management',                   '/advertisers',     'campaign',             'CRM',            300,  1, 1),
        ('AGENCY',            'Agency',            'Agency management',                       '/agencies',        'apartment',            'CRM',            310,  1, 1),
        ('ACCOUNT_EXECUTIVE', 'Account Executive', 'Account executive management',            '/account-executives','badge',              'CRM',            320,  1, 1),
        ('CRM_CODES',         'CRM Codes',         'CRM reference codes',                     '/crm-codes',       'code',                 'CRM',            330,  1, 1),

        -- SALES
        ('SALES_CODES',       'Sales Codes',       'Sales reference codes',                   '/sales-codes',     'code',                 'Sales',          400,  1, 1),
        ('PROPOSAL',          'Proposal',          'Proposal management',                     '/proposals',       'description',          'Sales',          410,  1, 1),
        ('DEALS',             'Deals',             'Deal management',                         '/deals',           'handshake',            'Sales',          420,  1, 1),
        ('ORDER',             'Order',             'Order management',                        '/orders',          'shopping_cart',        'Sales',          430,  1, 1),

        -- STANDARDS & PRACTICES
        ('CLEARANCE',         'Clearance',         'Standards and practices clearance',       '/clearance',       'verified',             'Standards',      500,  1, 1),

        -- BILLING
        ('INVOICE',           'Invoice',           'Invoice management',                      '/invoices',        'receipt_long',          'Billing',        600,  1, 1),
        ('PAYMENTS',          'Payments',          'Payment management',                      '/payments',        'payments',             'Billing',        610,  1, 1),

        -- WORKFLOW
        ('TASK',              'Task',              'Task management',                         '/tasks',           'task_alt',             'Workflow',       700,  1, 1),
        ('NOTIFICATIONS',     'Notifications',     'Notification management',                 '/notifications',   'notifications',        'Workflow',       710,  1, 1),
        ('APPROVALS',         'Approvals',         'Approval workflow',                       '/approvals',       'approval',             'Workflow',       720,  1, 1)
)
AS Source
(
    Code,
    Name,
    Description,
    Route,
    IconKey,
    MenuGroup,
    DisplayOrder,
    ShowInMenu,
    IsActive
)

ON Target.Code = Source.Code

WHEN MATCHED THEN
    UPDATE SET
        Target.Name         = Source.Name,
        Target.Description  = Source.Description,
        Target.Route        = Source.Route,
        Target.IconKey      = Source.IconKey,
        Target.MenuGroup    = Source.MenuGroup,
        Target.DisplayOrder = Source.DisplayOrder,
        Target.ShowInMenu   = Source.ShowInMenu,
        Target.IsActive     = Source.IsActive

WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        Code,
        Name,
        Description,
        Route,
        IconKey,
        MenuGroup,
        DisplayOrder,
        ShowInMenu,
        IsActive
    )
    VALUES
    (
        Source.Code,
        Source.Name,
        Source.Description,
        Source.Route,
        Source.IconKey,
        Source.MenuGroup,
        Source.DisplayOrder,
        Source.ShowInMenu,
        Source.IsActive
    );
GO