CREATE TABLE [dbo].[OrganizationUsers]
(
    [Id]             BIGINT IDENTITY(1,1) NOT NULL,
    [OrganizationId] UNIQUEIDENTIFIER NOT NULL,
    [IdentityUserId] UNIQUEIDENTIFIER NOT NULL,

    [IsActive]       BIT NOT NULL
        CONSTRAINT [DF_OrganizationUsers_IsActive]
        DEFAULT (1),

    [IsApproved]     BIT NOT NULL
        CONSTRAINT [DF_OrganizationUsers_IsApproved]
        DEFAULT (0),

    [CreatedBy]      NVARCHAR(100) NOT NULL,

    [CreatedUtc]     DATETIME2(7) NOT NULL
        CONSTRAINT [DF_OrganizationUsers_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    [ModifiedBy]     NVARCHAR(100) NULL,
    [ModifiedUtc]    DATETIME2(7) NULL,

    [ApprovedBy]     NVARCHAR(100) NULL,
    [ApprovedUtc]    DATETIME2(7) NULL,

    CONSTRAINT [PK_OrganizationUsers]
        PRIMARY KEY CLUSTERED ([Id]),

    CONSTRAINT [FK_OrganizationUsers_Organizations]
        FOREIGN KEY ([OrganizationId])
        REFERENCES [dbo].[Organizations] ([Id]),

    CONSTRAINT [UQ_OrganizationUsers_IdentityUserId]
        UNIQUE ([IdentityUserId])
);
GO