-- =========================================================================================
-- Migration Script: 20261020_varatia_schema_and_parity_migration.sql
-- Description: Applies full database architecture updates and migrations for Varatia Management:
--              1. Adds IsVerified to dbo.GeneralPosts
--              2. Adds IsRegistrationFeePaid, RegistrationFeeTransactionId, RegistrationFeePaidAt to dbo.Users
--              3. Alters MonthYear column to NVARCHAR(20) on dbo.MonthlyPayments
--              4. Creates dbo.tbl_CompanySettings table with registration fee configuration & defaults
--              5. Creates dbo.SubscriptionPlans table and seeds 4 matchmaking packages
--              6. Creates dbo.UserSubscriptions table for tracking matchmaking subscriptions
--              7. Creates performance indexes on GeneralPosts and UserSubscriptions
-- Target Database: SmartBazarDbmssql
-- Applied Date: 2026-10-20
-- =========================================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Add IsVerified to dbo.GeneralPosts
IF COL_LENGTH(N'dbo.GeneralPosts', N'IsVerified') IS NULL
BEGIN
    ALTER TABLE dbo.GeneralPosts ADD IsVerified BIT NOT NULL CONSTRAINT DF_GeneralPosts_IsVerified DEFAULT (0);
    PRINT 'Added IsVerified column to dbo.GeneralPosts';
END;
GO

-- 2. Add Registration Fee Tracking columns to dbo.Users
IF COL_LENGTH(N'dbo.Users', N'IsRegistrationFeePaid') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD IsRegistrationFeePaid BIT NOT NULL CONSTRAINT DF_Users_IsRegistrationFeePaid DEFAULT (0);
    PRINT 'Added IsRegistrationFeePaid column to dbo.Users';
END;
GO

IF COL_LENGTH(N'dbo.Users', N'RegistrationFeeTransactionId') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD RegistrationFeeTransactionId NVARCHAR(100) NULL;
    PRINT 'Added RegistrationFeeTransactionId column to dbo.Users';
END;
GO

IF COL_LENGTH(N'dbo.Users', N'RegistrationFeePaidAt') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD RegistrationFeePaidAt DATETIME2 NULL;
    PRINT 'Added RegistrationFeePaidAt column to dbo.Users';
END;
GO

-- 3. Alter MonthYear length in dbo.MonthlyPayments
IF EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'dbo.MonthlyPayments') 
      AND name = N'MonthYear' 
      AND max_length < 40
)
BEGIN
    ALTER TABLE dbo.MonthlyPayments ALTER COLUMN MonthYear NVARCHAR(20) NOT NULL;
    PRINT 'Altered dbo.MonthlyPayments.MonthYear to NVARCHAR(20)';
END;
GO

-- 4. Create dbo.tbl_CompanySettings
IF OBJECT_ID(N'dbo.tbl_CompanySettings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.tbl_CompanySettings (
        Id INT NOT NULL CONSTRAINT PK_tbl_CompanySettings PRIMARY KEY,
        CommissionRate DECIMAL(5,2) NOT NULL DEFAULT (1),
        CashbackRate DECIMAL(5,2) NOT NULL DEFAULT (2),
        DeliveryCharge DECIMAL(18,2) NOT NULL DEFAULT (60),
        SupportPhone NVARCHAR(30) NOT NULL DEFAULT (N'09678-123456'),
        PaymentGateway NVARCHAR(100) NOT NULL DEFAULT (N'SSLCommerz'),
        RegistrationFee DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_CompanySettings_RegistrationFee DEFAULT (50.00),
        IsRegistrationFeeActive BIT NOT NULL CONSTRAINT DF_tbl_CompanySettings_IsRegistrationFeeActive DEFAULT (1),
        UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_CompanySettings_UpdatedAt DEFAULT SYSUTCDATETIME()
    );
    INSERT INTO dbo.tbl_CompanySettings (Id, CommissionRate, CashbackRate, DeliveryCharge, SupportPhone, PaymentGateway, RegistrationFee, IsRegistrationFeeActive) 
    VALUES (1, 1, 2, 60, N'09678-123456', N'SSLCommerz', 50.00, 1);
    PRINT 'Created dbo.tbl_CompanySettings and inserted default configuration';
END
ELSE
BEGIN
    IF COL_LENGTH(N'dbo.tbl_CompanySettings', N'RegistrationFee') IS NULL
    BEGIN
        ALTER TABLE dbo.tbl_CompanySettings ADD RegistrationFee DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_CompanySettings_RegistrationFee DEFAULT (50.00);
        PRINT 'Added RegistrationFee to dbo.tbl_CompanySettings';
    END;
    IF COL_LENGTH(N'dbo.tbl_CompanySettings', N'IsRegistrationFeeActive') IS NULL
    BEGIN
        ALTER TABLE dbo.tbl_CompanySettings ADD IsRegistrationFeeActive BIT NOT NULL CONSTRAINT DF_tbl_CompanySettings_IsRegistrationFeeActive DEFAULT (1);
        PRINT 'Added IsRegistrationFeeActive to dbo.tbl_CompanySettings';
    END;
END;
GO

-- 5. Create dbo.SubscriptionPlans
IF OBJECT_ID(N'dbo.SubscriptionPlans', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SubscriptionPlans (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SubscriptionPlans PRIMARY KEY,
        ServiceCode NVARCHAR(50) NOT NULL CONSTRAINT UQ_SubscriptionPlans_ServiceCode UNIQUE,
        Title NVARCHAR(200) NOT NULL,
        TargetRole NVARCHAR(50) NOT NULL,
        Description NVARCHAR(500) NOT NULL,
        Fee DECIMAL(18,2) NOT NULL,
        DeliveryDays INT NOT NULL CONSTRAINT DF_SubscriptionPlans_DeliveryDays DEFAULT (7),
        IsActive BIT NOT NULL CONSTRAINT DF_SubscriptionPlans_IsActive DEFAULT (1),
        UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_SubscriptionPlans_UpdatedAt DEFAULT SYSUTCDATETIME()
    );

    INSERT INTO dbo.SubscriptionPlans (ServiceCode, Title, TargetRole, Description, Fee, DeliveryDays, IsActive) VALUES
        (N'find_flat', N'বাসা / ফ্ল্যাট অনুসন্ধান সাবস্ক্রিপশন', N'Tenant', N'অ্যাডমিন টিম আপনার পছন্দ ও বাজেট অনুযায়ী নির্ধারিত সময়ের মধ্যে ভেরিফাইড বাসা খুঁজে দিবে।', 500.00, 7, 1),
        (N'find_tenant', N'ভাড়াটিয়া ম্যাচিং সাবস্ক্রিপশন', N'Owner', N'আপনার খালি ফ্ল্যাট বা ইউনিটের জন্য যাচাইকৃত জেনুইন ভাড়াটিয়া খুঁজে দেওয়ার গ্যারান্টি সার্ভিস।', 500.00, 7, 1),
        (N'find_tutor', N'টিউটর / গৃহশিক্ষক ম্যাচিং সাবস্ক্রিপশন', N'Student', N'অভিভাবক ও শিক্ষার্থীদের জন্য কাঙ্ক্ষিত ক্লাসের অভিজ্ঞ গৃহশিক্ষক ম্যাচিং সার্ভিস।', 300.00, 10, 1),
        (N'find_student', N'টিউশন / শিক্ষার্থী সন্ধান সাবস্ক্রিপশন', N'Teacher', N'শিক্ষক ও টিউটরদের জন্য পছন্দসই লোকেশনে উপযুক্ত শিক্ষার্থী ও টিউশন ম্যাচিং সার্ভিস।', 400.00, 15, 1);
    PRINT 'Created dbo.SubscriptionPlans and seeded default plans';
END;
GO

-- 6. Create dbo.UserSubscriptions
IF OBJECT_ID(N'dbo.UserSubscriptions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.UserSubscriptions (
        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_UserSubscriptions PRIMARY KEY,
        UserId NVARCHAR(100) NOT NULL,
        ServiceCode NVARCHAR(50) NOT NULL,
        Title NVARCHAR(200) NOT NULL,
        Amount DECIMAL(18,2) NOT NULL,
        TransactionId NVARCHAR(100) NOT NULL CONSTRAINT UQ_UserSubscriptions_TransactionId UNIQUE,
        PaymentStatus NVARCHAR(50) NOT NULL CONSTRAINT DF_UserSubscriptions_PaymentStatus DEFAULT ('pending'),
        SubscriptionStatus NVARCHAR(50) NOT NULL CONSTRAINT DF_UserSubscriptions_SubscriptionStatus DEFAULT ('in_progress'),
        UserRequirements NVARCHAR(1000) NULL,
        DeliveryDays INT NOT NULL,
        SubscribedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserSubscriptions_SubscribedAt DEFAULT SYSUTCDATETIME(),
        DeadlineAt DATETIME2(0) NOT NULL,
        FulfilledAt DATETIME2(0) NULL,
        AdminNotes NVARCHAR(1000) NULL,
        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserSubscriptions_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserSubscriptions_UpdatedAt DEFAULT SYSUTCDATETIME()
    );
    PRINT 'Created dbo.UserSubscriptions';
END;
GO

-- 7. Performance Indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_GeneralPosts_Category_Status' AND object_id = OBJECT_ID(N'dbo.GeneralPosts'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_GeneralPosts_Category_Status ON dbo.GeneralPosts (Category, Status) INCLUDE (Price, DivisionId, AreaId, CreatedOn);
    PRINT 'Created index IX_GeneralPosts_Category_Status';
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_GeneralPosts_UserId' AND object_id = OBJECT_ID(N'dbo.GeneralPosts'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_GeneralPosts_UserId ON dbo.GeneralPosts (UserId);
    PRINT 'Created index IX_GeneralPosts_UserId';
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_UserSubscriptions_UserId_Status' AND object_id = OBJECT_ID(N'dbo.UserSubscriptions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_UserSubscriptions_UserId_Status ON dbo.UserSubscriptions (UserId, SubscriptionStatus);
    PRINT 'Created index IX_UserSubscriptions_UserId_Status';
END;
GO
