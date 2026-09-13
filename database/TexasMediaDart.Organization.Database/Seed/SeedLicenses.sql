MERGE dbo.Licenses AS Target
USING
(
    VALUES
        ('CORE',      'Core',                 'Default platform functionality', 1, 1),
        ('MEDIA',     'Media',                'Media/property/channel functionality', 0, 1),
        ('CRM',       'CRM',                  'Customer relationship management functionality', 0, 1),
        ('SALES',     'Sales',                'Sales, proposals, deals and orders', 0, 1),
        ('S_AND_P',   'Standards & Practices','Clearance and standards functionality', 0, 1),
        ('BILLING',   'Billing',              'Invoice and payment functionality', 0, 1),
        ('WORKFLOW',  'Workflow',             'Tasks, notifications and approvals', 0, 1)
) AS Source
(
    Code,
    Name,
    Description,
    IsDefault,
    IsActive
)
ON Target.Code = Source.Code

WHEN MATCHED THEN
    UPDATE SET
        Target.Name        = Source.Name,
        Target.Description = Source.Description,
        Target.IsDefault   = Source.IsDefault,
        Target.IsActive    = Source.IsActive

WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        Code,
        Name,
        Description,
        IsDefault,
        IsActive
    )
    VALUES
    (
        Source.Code,
        Source.Name,
        Source.Description,
        Source.IsDefault,
        Source.IsActive
    );