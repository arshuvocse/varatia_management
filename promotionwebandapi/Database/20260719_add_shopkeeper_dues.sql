USE SmartBazarDbmssql;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Add PaidAmount and DueAmount to tbl_Sales
IF COL_LENGTH('dbo.tbl_Sales', 'PaidAmount') IS NULL
BEGIN
    ALTER TABLE dbo.tbl_Sales
    ADD PaidAmount DECIMAL(18,2) NOT NULL DEFAULT 0;
END
GO

IF COL_LENGTH('dbo.tbl_Sales', 'DueAmount') IS NULL
BEGIN
    ALTER TABLE dbo.tbl_Sales
    ADD DueAmount AS (CONVERT(DECIMAL(18,2), GrossAmount - PaidAmount)) PERSISTED;
END
GO

-- Create table for tracking partial and full payments
IF OBJECT_ID('dbo.tbl_SalePayments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_SalePayments
    (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_SalePayments PRIMARY KEY,
        SaleId INT NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        PaymentMethod NVARCHAR(30) NOT NULL,
        PaidAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_SalePayments_PaidAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_tbl_SalePayments_tbl_Sales FOREIGN KEY (SaleId) REFERENCES dbo.tbl_Sales(Id)
    );
END
GO

-- Create procedure for paying dues
IF OBJECT_ID('dbo.sp_Sale_PayDue', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Sale_PayDue;
GO

CREATE PROCEDURE dbo.sp_Sale_PayDue
    @SaleId INT,
    @ShopkeeperId INT,
    @Amount DECIMAL(18,2),
    @PaymentMethod NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Amount <= 0
        THROW 51020, N'Amount must be greater than 0.', 1;

    DECLARE @CurrentDue DECIMAL(18,2);

    BEGIN TRANSACTION;

    SELECT @CurrentDue = DueAmount
    FROM dbo.tbl_Sales WITH (UPDLOCK, HOLDLOCK)
    WHERE Id = @SaleId AND ShopkeeperId = @ShopkeeperId;

    IF @CurrentDue IS NULL
        THROW 51021, N'Sale not found or unauthorized.', 1;

    IF @Amount > @CurrentDue
        THROW 51022, N'Amount exceeds the current due.', 1;

    INSERT INTO dbo.tbl_SalePayments (SaleId, Amount, PaymentMethod)
    VALUES (@SaleId, @Amount, @PaymentMethod);

    UPDATE dbo.tbl_Sales
    SET PaidAmount = PaidAmount + @Amount
    WHERE Id = @SaleId;

    COMMIT TRANSACTION;
END
GO
