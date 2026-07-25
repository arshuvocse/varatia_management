SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.MonthlyPayments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.MonthlyPayments
    (
        Id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_MonthlyPayments PRIMARY KEY,
        UserId UNIQUEIDENTIFIER NOT NULL,
        TransactionId NVARCHAR(100) NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        Status NVARCHAR(20) NOT NULL,
        MonthYear CHAR(7) NOT NULL,
        PaymentDate DATETIME2 NULL,
        CreatedOn DATETIME2 NOT NULL
            CONSTRAINT DF_MonthlyPayments_CreatedOn DEFAULT (SYSUTCDATETIME()),
        UpdatedOn DATETIME2 NOT NULL
            CONSTRAINT DF_MonthlyPayments_UpdatedOn DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT UQ_MonthlyPayments_TransactionId UNIQUE (TransactionId),
        CONSTRAINT CK_MonthlyPayments_Amount CHECK (Amount > 0),
        CONSTRAINT CK_MonthlyPayments_Status
            CHECK (Status IN (N'pending', N'success', N'failed', N'cancelled')),
        CONSTRAINT CK_MonthlyPayments_MonthYear
            CHECK (MonthYear LIKE '[1-2][0-9][0-9][0-9]-[0-1][0-9]'),
        CONSTRAINT FK_MonthlyPayments_Users
            FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.MonthlyPayments')
      AND name = N'IX_MonthlyPayments_UserId_MonthYear_Status'
)
BEGIN
    CREATE INDEX IX_MonthlyPayments_UserId_MonthYear_Status
        ON dbo.MonthlyPayments (UserId, MonthYear, Status)
        INCLUDE (Amount, PaymentDate, UpdatedOn);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_MonthlyPayment_GetStatus
    @UserId UNIQUEIDENTIFIER,
    @MonthYear CHAR(7) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Id = @UserId)
    BEGIN
        THROW 51040, N'User not found.', 1;
    END;

    DECLARE @BangladeshNow DATETIME2 = DATEADD(HOUR, 6, SYSUTCDATETIME());
    DECLARE @RequestedMonth CHAR(7) = COALESCE(
        NULLIF(LTRIM(RTRIM(@MonthYear)), ''),
        CONVERT(CHAR(7), @BangladeshNow, 126)
    );

    IF TRY_CONVERT(DATE, CONCAT(@RequestedMonth, '-01')) IS NULL
    BEGIN
        THROW 51041, N'MonthYear must use YYYY-MM format.', 1;
    END;

    DECLARE @MonthStart DATE = CONVERT(DATE, CONCAT(@RequestedMonth, '-01'));
    DECLARE @ExpiresAt DATETIME2 = DATEADD(
        SECOND,
        -1,
        CAST(DATEADD(MONTH, 1, @MonthStart) AS DATETIME2)
    );

    ;WITH CurrentPayment AS
    (
        SELECT TOP (1)
            p.Amount,
            p.Status,
            p.PaymentDate,
            p.UpdatedOn
        FROM dbo.MonthlyPayments AS p
        WHERE p.UserId = CONVERT(NVARCHAR(36), @UserId)
          AND p.MonthYear = @RequestedMonth
        ORDER BY
            CASE p.Status
                WHEN N'success' THEN 1
                WHEN N'pending' THEN 2
                WHEN N'failed' THEN 3
                WHEN N'cancelled' THEN 4
                ELSE 5
            END,
            p.UpdatedOn DESC,
            p.Id DESC
    )
    SELECT
        CONVERT(NVARCHAR(36), u.Id) AS UserId,
        COALESCE(NULLIF(u.Role, N''), N'tenant') AS Role,
        @RequestedMonth AS PaymentMonth,
        CASE
            WHEN p.Status = N'success' THEN N'paid'
            WHEN p.Status = N'pending' THEN N'pending'
            ELSE N'unpaid'
        END AS PaymentStatus,
        COALESCE(p.Amount, CAST(50.00 AS DECIMAL(18,2))) AS Amount,
        CASE WHEN p.Status = N'success' THEN p.PaymentDate END AS PaidAt,
        CASE WHEN p.Status = N'success' THEN @ExpiresAt END AS ExpiresAt,
        CONVERT(BIT, CASE WHEN p.Status = N'success' THEN 1 ELSE 0 END) AS AccessAllowed
    FROM dbo.Users AS u
    LEFT JOIN CurrentPayment AS p ON 1 = 1
    WHERE u.Id = @UserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_MonthlyPayment_GetHistory
    @UserId UNIQUEIDENTIFIER,
    @Year SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Id = @UserId)
    BEGIN
        THROW 51040, N'User not found.', 1;
    END;

    IF @Year < 2000 OR @Year > 2100
    BEGIN
        THROW 51042, N'Year must be between 2000 and 2100.', 1;
    END;

    DECLARE @BangladeshToday DATE = CONVERT(
        DATE,
        DATEADD(HOUR, 6, SYSUTCDATETIME())
    );

    ;WITH Months AS
    (
        SELECT 1 AS MonthNumber
        UNION ALL
        SELECT MonthNumber + 1
        FROM Months
        WHERE MonthNumber < 12
    ),
    RankedPayments AS
    (
        SELECT
            p.MonthYear,
            p.Amount,
            p.Status,
            p.PaymentDate,
            ROW_NUMBER() OVER
            (
                PARTITION BY p.MonthYear
                ORDER BY
                    CASE p.Status
                        WHEN N'success' THEN 1
                        WHEN N'pending' THEN 2
                        WHEN N'failed' THEN 3
                        WHEN N'cancelled' THEN 4
                        ELSE 5
                    END,
                    p.UpdatedOn DESC,
                    p.Id DESC
            ) AS RowNumber
        FROM dbo.MonthlyPayments AS p
        WHERE p.UserId = CONVERT(NVARCHAR(36), @UserId)
          AND p.MonthYear >= CONCAT(@Year, '-01')
          AND p.MonthYear <= CONCAT(@Year, '-12')
    )
    SELECT
        CONVERT(NVARCHAR(36), u.Id) AS UserId,
        COALESCE(NULLIF(u.Role, N''), N'tenant') AS Role,
        CONVERT(INT, @Year) AS [Year],
        m.MonthNumber,
        CONCAT(
            @Year,
            N'-',
            RIGHT(CONCAT(N'0', m.MonthNumber), 2)
        ) AS PaymentMonth,
        CASE
            WHEN DATEFROMPARTS(@Year, m.MonthNumber, 1) >
                 DATEFROMPARTS(YEAR(@BangladeshToday), MONTH(@BangladeshToday), 1)
                THEN N'upcoming'
            WHEN rp.Status = N'success' THEN N'paid'
            WHEN rp.Status = N'pending' THEN N'pending'
            ELSE N'unpaid'
        END AS PaymentStatus,
        COALESCE(rp.Amount, CAST(50.00 AS DECIMAL(18,2))) AS Amount,
        CASE WHEN rp.Status = N'success' THEN rp.PaymentDate END AS PaidAt,
        CONVERT(BIT, CASE WHEN rp.Status = N'success' THEN 1 ELSE 0 END)
            AS AccessAllowed
    FROM dbo.Users AS u
    CROSS JOIN Months AS m
    LEFT JOIN RankedPayments AS rp
        ON rp.MonthYear = CONCAT(
            @Year,
            N'-',
            RIGHT(CONCAT(N'0', m.MonthNumber), 2)
        )
       AND rp.RowNumber = 1
    WHERE u.Id = @UserId
    ORDER BY m.MonthNumber;
END;
GO

-- Example:
-- EXEC dbo.sp_MonthlyPayment_GetStatus
--     @UserId = '00000000-0000-0000-0000-000000000000';
