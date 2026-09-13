CREATE TABLE [dbo].[LicenseModules]
(
    [LicenseId] INT NOT NULL,
    [ModuleId]  INT NOT NULL,

    [DefaultCanCreate] BIT NOT NULL
        CONSTRAINT [DF_LicenseModules_DefaultCanCreate]
        DEFAULT (0),

    [DefaultCanUpdate] BIT NOT NULL
        CONSTRAINT [DF_LicenseModules_DefaultCanUpdate]
        DEFAULT (0),

    [DefaultCanDelete] BIT NOT NULL
        CONSTRAINT [DF_LicenseModules_DefaultCanDelete]
        DEFAULT (0),

    [DefaultCanRead] BIT NOT NULL
        CONSTRAINT [DF_LicenseModules_DefaultCanRead]
        DEFAULT (0),

    CONSTRAINT [PK_LicenseModules]
        PRIMARY KEY CLUSTERED
        (
            [LicenseId],
            [ModuleId]
        ),

    CONSTRAINT [FK_LicenseModules_Licenses]
        FOREIGN KEY ([LicenseId])
        REFERENCES [dbo].[Licenses] ([Id]),

    CONSTRAINT [FK_LicenseModules_Modules]
        FOREIGN KEY ([ModuleId])
        REFERENCES [dbo].[Modules] ([Id])
);
GO