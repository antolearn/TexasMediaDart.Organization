CREATE TYPE [dbo].[RolePermissionInputType] AS TABLE
(
    [ModuleId]   INT NOT NULL,
    [CanCreate]  BIT NOT NULL,
    [CanUpdate]  BIT NOT NULL,
    [CanDelete]  BIT NOT NULL,
    [CanRead]    BIT NOT NULL,
    [CanApprove] BIT NOT NULL,

    PRIMARY KEY ([ModuleId])
);
GO