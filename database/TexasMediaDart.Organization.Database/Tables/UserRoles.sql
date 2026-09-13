CREATE TABLE [dbo].[UserRoles]
(
    [OrganizationUserId] BIGINT NOT NULL,
    [RoleId]             UNIQUEIDENTIFIER NOT NULL,

    [CreatedBy]          NVARCHAR(100) NOT NULL,

    [CreatedUtc]         DATETIME2(7) NOT NULL
        CONSTRAINT [DF_UserRoles_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_UserRoles]
        PRIMARY KEY CLUSTERED
        (
            [OrganizationUserId],
            [RoleId]
        ),

    CONSTRAINT [FK_UserRoles_OrganizationUsers]
        FOREIGN KEY ([OrganizationUserId])
        REFERENCES [dbo].[OrganizationUsers] ([Id]),

    CONSTRAINT [FK_UserRoles_Roles]
        FOREIGN KEY ([RoleId])
        REFERENCES [dbo].[Roles] ([Id])
);
GO