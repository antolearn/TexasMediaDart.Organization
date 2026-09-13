CREATE TABLE [dbo].[Roles]
(
    [Id]             UNIQUEIDENTIFIER NOT NULL,
    [OrganizationId] UNIQUEIDENTIFIER NOT NULL,

    [Name]           NVARCHAR(100) NOT NULL,
    [Description]    NVARCHAR(500) NULL,

    [IsSystemRole]   BIT NOT NULL
        CONSTRAINT [DF_Roles_IsSystemRole]
        DEFAULT (0),

    [IsActive]       BIT NOT NULL
        CONSTRAINT [DF_Roles_IsActive]
        DEFAULT (1),

    [IsDeleted]      BIT NOT NULL
        CONSTRAINT [DF_Roles_IsDeleted]
        DEFAULT (0),

    [IsApproved]     BIT NOT NULL
        CONSTRAINT [DF_Roles_IsApproved]
        DEFAULT (0),

    [CreatedBy]      NVARCHAR(100) NOT NULL,

    [CreatedUtc]     DATETIME2(7) NOT NULL
        CONSTRAINT [DF_Roles_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    [ModifiedBy]     NVARCHAR(100) NULL,
    [ModifiedUtc]    DATETIME2(7) NULL,

    [ApprovedBy]     NVARCHAR(100) NULL,
    [ApprovedUtc]    DATETIME2(7) NULL,

    CONSTRAINT [PK_Roles]
        PRIMARY KEY NONCLUSTERED ([Id]),

    CONSTRAINT [FK_Roles_Organizations]
        FOREIGN KEY ([OrganizationId])
        REFERENCES [dbo].[Organizations] ([Id]),

    CONSTRAINT [UQ_Roles_Organization_Name]
        UNIQUE
        (
            [OrganizationId],
            [Name]
        )
);
GO