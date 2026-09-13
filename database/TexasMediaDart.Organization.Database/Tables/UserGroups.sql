CREATE TABLE [dbo].[UserGroups]
(
    [Id]             UNIQUEIDENTIFIER NOT NULL,
    [OrganizationId] UNIQUEIDENTIFIER NOT NULL,

    [Name]           NVARCHAR(100) NOT NULL,
    [Description]    NVARCHAR(500) NULL,

    [IsActive]       BIT NOT NULL
        CONSTRAINT [DF_UserGroups_IsActive]
        DEFAULT (1),

    [IsDeleted]      BIT NOT NULL
        CONSTRAINT [DF_UserGroups_IsDeleted]
        DEFAULT (0),

    [IsApproved]     BIT NOT NULL
        CONSTRAINT [DF_UserGroups_IsApproved]
        DEFAULT (0),

    [CreatedBy]      NVARCHAR(100) NOT NULL,

    [CreatedUtc]     DATETIME2(7) NOT NULL
        CONSTRAINT [DF_UserGroups_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    [ModifiedBy]     NVARCHAR(100) NULL,
    [ModifiedUtc]    DATETIME2(7) NULL,

    [ApprovedBy]     NVARCHAR(100) NULL,
    [ApprovedUtc]    DATETIME2(7) NULL,

    CONSTRAINT [PK_UserGroups]
        PRIMARY KEY NONCLUSTERED ([Id]),

    CONSTRAINT [FK_UserGroups_Organizations]
        FOREIGN KEY ([OrganizationId])
        REFERENCES [dbo].[Organizations] ([Id]),

    CONSTRAINT [UQ_UserGroups_Organization_Name]
        UNIQUE
        (
            [OrganizationId],
            [Name]
        )
);
GO