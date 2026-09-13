CREATE TABLE [dbo].[Licenses]
(
    [Id]          INT IDENTITY(1,1) NOT NULL,
    [Code]        NVARCHAR(50) NOT NULL,
    [Name]        NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,

    [IsDefault]   BIT NOT NULL
        CONSTRAINT [DF_Licenses_IsDefault]
        DEFAULT (0),

    [IsActive]    BIT NOT NULL
        CONSTRAINT [DF_Licenses_IsActive]
        DEFAULT (1),

    [CreatedUtc]  DATETIME2(7) NOT NULL
        CONSTRAINT [DF_Licenses_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_Licenses]
        PRIMARY KEY CLUSTERED ([Id]),

    CONSTRAINT [UQ_Licenses_Code]
        UNIQUE ([Code])
);
GO