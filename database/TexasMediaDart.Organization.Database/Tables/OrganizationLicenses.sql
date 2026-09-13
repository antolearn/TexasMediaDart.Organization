CREATE TABLE [dbo].[OrganizationLicenses]
(
    [Id]             BIGINT IDENTITY(1,1) NOT NULL,
    [OrganizationId] UNIQUEIDENTIFIER NOT NULL,
    [LicenseId]      INT NOT NULL,

    [IsActive]       BIT NOT NULL
        CONSTRAINT [DF_OrganizationLicenses_IsActive]
        DEFAULT (1),

    [StartUtc]       DATETIME2(7) NOT NULL
        CONSTRAINT [DF_OrganizationLicenses_StartUtc]
        DEFAULT (SYSUTCDATETIME()),

    [EndUtc]         DATETIME2(7) NULL,

    [CreatedBy]      NVARCHAR(100) NOT NULL,

    [CreatedUtc]     DATETIME2(7) NOT NULL
        CONSTRAINT [DF_OrganizationLicenses_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    [ModifiedBy]     NVARCHAR(100) NULL,
    [ModifiedUtc]    DATETIME2(7) NULL,

    CONSTRAINT [PK_OrganizationLicenses]
        PRIMARY KEY CLUSTERED ([Id]),

    CONSTRAINT [FK_OrganizationLicenses_Organizations]
        FOREIGN KEY ([OrganizationId])
        REFERENCES [dbo].[Organizations] ([Id]),

    CONSTRAINT [FK_OrganizationLicenses_Licenses]
        FOREIGN KEY ([LicenseId])
        REFERENCES [dbo].[Licenses] ([Id]),

    CONSTRAINT [UQ_OrganizationLicenses_Organization_License]
        UNIQUE
        (
            [OrganizationId],
            [LicenseId]
        )
);
GO