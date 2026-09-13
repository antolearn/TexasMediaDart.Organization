CREATE TABLE [dbo].[Contacts]
(
    [Id]               UNIQUEIDENTIFIER NOT NULL,
    [OrganizationId]   UNIQUEIDENTIFIER NOT NULL,

    [FirstName]        NVARCHAR(100) NULL,
    [MiddleName]       NVARCHAR(100) NULL,
    [LastName]         NVARCHAR(100) NULL,
    [CompanyName]      NVARCHAR(200) NULL,

    [Email]            NVARCHAR(320) NULL,
    [NormalizedEmail]  NVARCHAR(320) NULL,

    [Phone]            NVARCHAR(32) NULL,
    [MobilePhone]      NVARCHAR(32) NULL,

    [AddressLine1]     NVARCHAR(200) NULL,
    [AddressLine2]     NVARCHAR(200) NULL,
    [City]             NVARCHAR(100) NULL,
    [StateProvince]    NVARCHAR(100) NULL,
    [PostalCode]       NVARCHAR(16) NULL,
    [Country]          NVARCHAR(32) NULL,

    [Notes]            NVARCHAR(512) NULL,

    [IsActive]         BIT NOT NULL
        CONSTRAINT [DF_Contacts_IsActive]
        DEFAULT (1),

    [IsDeleted]        BIT NOT NULL
        CONSTRAINT [DF_Contacts_IsDeleted]
        DEFAULT (0),

    [CreatedBy]        NVARCHAR(100) NOT NULL,

    [CreatedUtc]       DATETIME2(7) NOT NULL
        CONSTRAINT [DF_Contacts_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    [ModifiedBy]       NVARCHAR(100) NULL,
    [ModifiedUtc]      DATETIME2(7) NULL,

    CONSTRAINT [PK_Contacts]
        PRIMARY KEY NONCLUSTERED ([Id]),

    CONSTRAINT [FK_Contacts_Organizations]
        FOREIGN KEY ([OrganizationId])
        REFERENCES [dbo].[Organizations] ([Id])
);
GO

CREATE UNIQUE INDEX [UX_Contacts_Organization_NormalizedEmail]
ON [dbo].[Contacts]
(
    [OrganizationId],
    [NormalizedEmail]
)
WHERE [NormalizedEmail] IS NOT NULL;
GO