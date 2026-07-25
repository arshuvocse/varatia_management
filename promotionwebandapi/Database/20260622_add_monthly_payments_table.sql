IF OBJECT_ID(N'dbo.MonthlyPayments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MonthlyPayments
    (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserId NVARCHAR(100) NOT NULL,
        TransactionId NVARCHAR(100) NOT NULL UNIQUE,
        Amount DECIMAL(18,2) NOT NULL,
        Status NVARCHAR(20) NOT NULL, -- 'pending', 'success', 'failed', 'cancelled'
        MonthYear NVARCHAR(7) NOT NULL, -- 'YYYY-MM'
        PaymentDate DATETIME2 NULL,
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_MonthlyPayments_CreatedOn DEFAULT (SYSUTCDATETIME()),
        UpdatedOn DATETIME2 NOT NULL CONSTRAINT DF_MonthlyPayments_UpdatedOn DEFAULT (SYSUTCDATETIME())
    );
END;
GO
