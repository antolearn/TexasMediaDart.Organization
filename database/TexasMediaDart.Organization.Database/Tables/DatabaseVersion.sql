CREATE TABLE [dbo].[DatabaseVersion]
(
    [Id] INT NOT NULL,
    [Version] NVARCHAR(20) NOT NULL,
    [DeployedUtc] DATETIME2(7) NOT NULL,

    CONSTRAINT [PK_DatabaseVersion]
        PRIMARY KEY CLUSTERED ([Id] ASC)
);