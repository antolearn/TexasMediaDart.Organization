CREATE TABLE [dbo].[RolePermissions]
(
    [RoleId]     UNIQUEIDENTIFIER NOT NULL,
    [ModuleId]   INT NOT NULL,

    [CanCreate]  BIT NOT NULL
        CONSTRAINT [DF_RolePermissions_CanCreate]
        DEFAULT (0),

    [CanUpdate]  BIT NOT NULL
        CONSTRAINT [DF_RolePermissions_CanUpdate]
        DEFAULT (0),

    [CanDelete]  BIT NOT NULL
        CONSTRAINT [DF_RolePermissions_CanDelete]
        DEFAULT (0),

    [CanRead]    BIT NOT NULL
        CONSTRAINT [DF_RolePermissions_CanRead]
        DEFAULT (0),

    [CreatedBy]  NVARCHAR(100) NOT NULL,

    [CreatedUtc] DATETIME2(7) NOT NULL
        CONSTRAINT [DF_RolePermissions_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    [ModifiedBy] NVARCHAR(100) NULL,
    [ModifiedUtc] DATETIME2(7) NULL,

    CONSTRAINT [PK_RolePermissions]
        PRIMARY KEY CLUSTERED
        (
            [RoleId],
            [ModuleId]
        ),

    CONSTRAINT [FK_RolePermissions_Roles]
        FOREIGN KEY ([RoleId])
        REFERENCES [dbo].[Roles] ([Id]),

    CONSTRAINT [FK_RolePermissions_Modules]
        FOREIGN KEY ([ModuleId])
        REFERENCES [dbo].[Modules] ([Id])
);
GO