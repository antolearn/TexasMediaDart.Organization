CREATE TABLE [dbo].[Organizations]
(
    [Id]             UNIQUEIDENTIFIER NOT NULL,
    [Name]           NVARCHAR(200) NOT NULL,

    [IsActive]       BIT NOT NULL
        CONSTRAINT [DF_Organizations_IsActive]
        DEFAULT (1),

    [IsDeleted]      BIT NOT NULL
        CONSTRAINT [DF_Organizations_IsDeleted]
        DEFAULT (0),

    [CreatedBy]      NVARCHAR(100) NOT NULL,

    [CreatedUtc]     DATETIME2(7) NOT NULL
        CONSTRAINT [DF_Organizations_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    [ModifiedBy]     NVARCHAR(100) NULL,
    [ModifiedUtc]    DATETIME2(7) NULL,

    CONSTRAINT [PK_Organizations]
        PRIMARY KEY NONCLUSTERED ([Id]),

    CONSTRAINT [UQ_Organizations_Name]
        UNIQUE ([Name])
);
GO