IF OBJECT_ID(N'dbo.tbl_ServiceRequests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_ServiceRequests
    (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ServiceRequests PRIMARY KEY,
        Name NVARCHAR(150) NOT NULL,
        Phone NVARCHAR(20) NOT NULL,
        Service NVARCHAR(100) NOT NULL,
        Location NVARCHAR(200) NULL,
        Message NVARCHAR(2000) NULL,
        CreatedAt DATETIME2(0) NOT NULL
            CONSTRAINT DF_tbl_ServiceRequests_CreatedAt DEFAULT SYSUTCDATETIME()
    );

    CREATE INDEX IX_tbl_ServiceRequests_CreatedAt
        ON dbo.tbl_ServiceRequests (CreatedAt DESC);
END;
