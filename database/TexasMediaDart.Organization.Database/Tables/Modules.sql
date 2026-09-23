CREATE TABLE [dbo].[Modules]
(
    [Id]          INT IDENTITY(1,1) NOT NULL,
    [Code]        NVARCHAR(100) NOT NULL,
    [Name]        NVARCHAR(150) NOT NULL,
    [Description] NVARCHAR(500) NULL,

    ------------------------------------------------------------
    -- Navigation metadata
    ------------------------------------------------------------
    [Route]        NVARCHAR(200) NULL,
    [IconKey]      NVARCHAR(100) NULL,
    [MenuGroup]    NVARCHAR(100) NULL,

    [DisplayOrder] INT NOT NULL
        CONSTRAINT [DF_Modules_DisplayOrder]
        DEFAULT (0),

    [ShowInMenu]   BIT NOT NULL
        CONSTRAINT [DF_Modules_ShowInMenu]
        DEFAULT (1),

    ------------------------------------------------------------
    -- Supported actions
    --
    -- These columns define which actions are conceptually
    -- supported by the module.
    --
    -- They do NOT grant permissions to a user or organization.
    ------------------------------------------------------------
    [SupportsCreate] BIT NOT NULL
        CONSTRAINT [DF_Modules_SupportsCreate]
        DEFAULT (0),

    [SupportsRead] BIT NOT NULL
        CONSTRAINT [DF_Modules_SupportsRead]
        DEFAULT (1),

    [SupportsUpdate] BIT NOT NULL
        CONSTRAINT [DF_Modules_SupportsUpdate]
        DEFAULT (0),

    [SupportsDelete] BIT NOT NULL
        CONSTRAINT [DF_Modules_SupportsDelete]
        DEFAULT (0),

    [SupportsApprove] BIT NOT NULL
        CONSTRAINT [DF_Modules_SupportsApprove]
        DEFAULT (0),

    ------------------------------------------------------------
    -- Status
    ------------------------------------------------------------
    [IsActive] BIT NOT NULL
        CONSTRAINT [DF_Modules_IsActive]
        DEFAULT (1),

    ------------------------------------------------------------
    -- Audit
    ------------------------------------------------------------
    [CreatedUtc] DATETIME2(7) NOT NULL
        CONSTRAINT [DF_Modules_CreatedUtc]
        DEFAULT (SYSUTCDATETIME()),

    ------------------------------------------------------------
    -- Keys / Constraints
    ------------------------------------------------------------
    CONSTRAINT [PK_Modules]
        PRIMARY KEY CLUSTERED ([Id]),

    CONSTRAINT [UQ_Modules_Code]
        UNIQUE ([Code])
);
GO