CREATE TABLE [dbo].[UserGroupMembers]
(
    [UserGroupId]        UNIQUEIDENTIFIER NOT NULL,
    [OrganizationUserId] BIGINT NOT NULL,

    [CreatedBy]          NVARCHAR(100) NOT NULL,

    [CreatedUtc]         DATETIME2(7) NOT NULL
        CONSTRAINT [DF_UserGroupMembers_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_UserGroupMembers]
        PRIMARY KEY CLUSTERED
        (
            [UserGroupId],
            [OrganizationUserId]
        ),

    CONSTRAINT [FK_UserGroupMembers_UserGroups]
        FOREIGN KEY ([UserGroupId])
        REFERENCES [dbo].[UserGroups] ([Id]),

    CONSTRAINT [FK_UserGroupMembers_OrganizationUsers]
        FOREIGN KEY ([OrganizationUserId])
        REFERENCES [dbo].[OrganizationUsers] ([Id])
);
GO