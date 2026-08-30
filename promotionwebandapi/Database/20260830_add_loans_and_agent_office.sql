-- ==============================================================================
-- 1. Ensure Agent Office Location Columns in tbl_Users & tbl_Agents
-- ==============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.tbl_Users') AND name = N'OfficeName')
BEGIN
    ALTER TABLE dbo.tbl_Users ADD
        OfficeName NVARCHAR(200) NULL,
        OfficeAddress NVARCHAR(500) NULL,
        RoadNo NVARCHAR(100) NULL,
        AreaName NVARCHAR(150) NULL,
        Thana NVARCHAR(150) NULL,
        OfficeHours NVARCHAR(100) NULL,
        ContactPhone NVARCHAR(50) NULL,
        Latitude DECIMAL(18, 8) NULL,
        Longitude DECIMAL(18, 8) NULL;
END;

-- ==============================================================================
-- 2. Ensure bKash-style Digital Nano Loans Tables
-- ==============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_Loans')
BEGIN
    CREATE TABLE dbo.tbl_Loans (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NOT NULL,
        UserRole NVARCHAR(50) NOT NULL, -- 'Customer', 'Shopkeeper'
        CustomerName NVARCHAR(150) NULL,
        Phone NVARCHAR(50) NOT NULL,
        LoanAmount DECIMAL(18,2) NOT NULL,
        InterestRate DECIMAL(5,2) NOT NULL DEFAULT 9.00,
        TenureMonths INT NOT NULL,
        MonthlyInstallment DECIMAL(18,2) NOT NULL,
        ProcessingFee DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        TotalInterest DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        TotalPayable DECIMAL(18,2) NOT NULL,
        RemainingAmount DECIMAL(18,2) NOT NULL,
        Purpose NVARCHAR(250) NULL,
        Status NVARCHAR(50) NOT NULL DEFAULT N'Approved', -- 'Pending', 'Approved', 'Disbursed', 'Completed', 'Rejected'
        AppliedAt DATETIME NOT NULL DEFAULT GETDATE(),
        ApprovedAt DATETIME NULL DEFAULT GETDATE(),
        DisbursedAt DATETIME NULL DEFAULT GETDATE(),
        CompletedAt DATETIME NULL
    );
    CREATE INDEX IX_tbl_Loans_UserId ON dbo.tbl_Loans(UserId);
    CREATE INDEX IX_tbl_Loans_Phone ON dbo.tbl_Loans(Phone);
END;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_LoanInstallments')
BEGIN
    CREATE TABLE dbo.tbl_LoanInstallments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        LoanId INT NOT NULL,
        InstallmentNumber INT NOT NULL,
        DueDate DATETIME NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        PrincipalPortion DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        InterestPortion DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        PaidAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00,
        Status NVARCHAR(50) NOT NULL DEFAULT N'Pending', -- 'Pending', 'Paid', 'Overdue'
        PaidAt DATETIME NULL,
        PaymentMethod NVARCHAR(50) NULL, -- 'Wallet', 'bKash', 'Nagad', 'Cash'
        CONSTRAINT FK_tbl_LoanInstallments_LoanId FOREIGN KEY (LoanId) REFERENCES dbo.tbl_Loans(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_tbl_LoanInstallments_LoanId ON dbo.tbl_LoanInstallments(LoanId);
END;

-- ==============================================================================
-- 3. Ensure District Pricing Adjustments
-- ==============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_DistrictPricingConfig')
BEGIN
    CREATE TABLE dbo.tbl_DistrictPricingConfig (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DistrictName NVARCHAR(100) NOT NULL UNIQUE,
        TransportMultiplier DECIMAL(5,4) NOT NULL DEFAULT 1.0000, -- e.g. 1.02 for +2%
        DefaultDeliveryCharge DECIMAL(18,2) NOT NULL DEFAULT 40.00,
        ShopkeeperMarginPercent DECIMAL(5,2) NOT NULL DEFAULT 10.00,
        CompanyMarginPercent DECIMAL(5,2) NOT NULL DEFAULT 5.00
    );

    -- Insert seed district configs
    INSERT INTO dbo.tbl_DistrictPricingConfig (DistrictName, TransportMultiplier, DefaultDeliveryCharge, ShopkeeperMarginPercent, CompanyMarginPercent)
    VALUES
    (N'ঢাকা', 1.0000, 30.00, 10.00, 5.00),
    (N'চট্টগ্রাম', 1.0200, 40.00, 10.00, 5.00),
    (N'সিলেট', 1.0250, 40.00, 10.00, 5.00),
    (N'রাজশাহী', 1.0300, 45.00, 10.00, 5.00),
    (N'খুলনা', 1.0300, 45.00, 10.00, 5.00),
    (N'বরিশাল', 1.0350, 50.00, 10.00, 5.00),
    (N'রংপুর', 1.0400, 50.00, 10.00, 5.00),
    (N'ময়মনসিংহ', 1.0200, 40.00, 10.00, 5.00);
END;
