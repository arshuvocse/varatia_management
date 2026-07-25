CREATE TABLE dbo.tbl_ShopkeeperSubscriptions
(
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ShopkeeperSubscriptions PRIMARY KEY,
    ShopkeeperId INT NOT NULL CONSTRAINT FK_ShopkeeperSubscriptions_ShopkeeperId FOREIGN KEY REFERENCES dbo.tbl_Shopkeepers(Id),
    MonthYear NVARCHAR(7) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    IsPaid BIT NOT NULL CONSTRAINT DF_ShopkeeperSubscriptions_IsPaid DEFAULT (0),
    TransactionId NVARCHAR(100) NULL,
    PaidAt DATETIME2(0) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_ShopkeeperSubscriptions_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT UQ_ShopkeeperSubscriptions_Month UNIQUE (ShopkeeperId, MonthYear)
);
GO

CREATE PROCEDURE dbo.sp_ShopkeeperSubscription_Check
    @ShopkeeperId INT,
    @CurrentMonthYear NVARCHAR(7),
    @NextMonthYear NVARCHAR(7)
AS
BEGIN
    SET NOCOUNT ON;

    -- Return 1 if paid for current month, 0 if not
    DECLARE @CurrentIsPaid BIT = 0;
    IF EXISTS (SELECT 1 FROM dbo.tbl_ShopkeeperSubscriptions WHERE ShopkeeperId = @ShopkeeperId AND MonthYear = @CurrentMonthYear AND IsPaid = 1)
    BEGIN
        SET @CurrentIsPaid = 1;
    END

    -- Return 1 if paid for next month, 0 if not
    DECLARE @NextIsPaid BIT = 0;
    IF EXISTS (SELECT 1 FROM dbo.tbl_ShopkeeperSubscriptions WHERE ShopkeeperId = @ShopkeeperId AND MonthYear = @NextMonthYear AND IsPaid = 1)
    BEGIN
        SET @NextIsPaid = 1;
    END

    SELECT 
        @CurrentIsPaid AS CurrentMonthIsPaid,
        @NextIsPaid AS NextMonthIsPaid;
END
GO
