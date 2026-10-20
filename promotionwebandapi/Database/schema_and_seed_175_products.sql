-- ==============================================================================
-- SMARTBAZAR E-COMMERCE & LOAN ENHANCEMENT SCHEMA & SEED SCRIPT (195+ REAL PRODUCTS)
-- ==============================================================================

-- 1. Shop Categories Table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_ShopCategories')
BEGIN
    CREATE TABLE dbo.tbl_ShopCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL UNIQUE,
        BanglaName NVARCHAR(100) NOT NULL,
        Icon NVARCHAR(50) NOT NULL DEFAULT '🛍️',
        Description NVARCHAR(250) NULL,
        DisplayOrder INT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
    );

    INSERT INTO dbo.tbl_ShopCategories (Name, BanglaName, Icon, Description, DisplayOrder)
    VALUES
    (N'মুদির দোকান', N'মুদি দোকান', N'🛒', N'চাল, ডাল, তেল, চিনি, লবণ, আটা, মসলা ও নিত্যপ্রয়োজনীয় গ্রোসারি', 1),
    (N'কসমেটিক্স', N'কসমেটিক্স ও রূপচর্চা', N'💄', N'স্কিনকেয়ার, শ্যাম্পু, সাবান, লোশন ও প্রসাধনী সামগ্রী', 2),
    (N'ফার্মেসি', N'ফার্মেসি ও ঔষধ', N'💊', N'জরুরী ঔষধ, প্রেসক্রিপশন মেডিসিন, ব্যান্ডেজ ও স্বাস্থ্যসেবা পণ্য', 3),
    (N'জামা-কাপড়', N'পোশাক ও বস্ত্র', N'👕', N'শার্ট, টি-শার্ট, পাঞ্জাবি, শাড়ি, থ্রি-পিস ও ট্রাউজার', 4),
    (N'জুতার দোকান', N'জুতা ও স্যান্ডেল', N'👟', N'লেদার শু, কেডস, ক্যাজুয়াল শু, স্লিপার ও শিশুদের জুতা', 5),
    (N'কাঁচা বাজার', N'কাঁচা বাজার ও ফলমূল', N'🥬', N'তাজা শাক-সবজি, মাছ-মাংস, ফলমূল ও কাঁচাবাজার', 6),
    (N'ইলেকট্রনিক্স শপ', N'ইলেকট্রনিক্স ও হোম অ্যাপ্লায়েন্স', N'⚡', N'ফ্যান, লাইট, ব্লেন্ডার, আয়রন, মাল্টিপ্লাগ ও ইলেকট্রিক যন্ত্রপাতি', 7),
    (N'মোবাইল ফোনের দোকান', N'মোবাইল ও গ্যাজেট', N'📱', N'স্মার্টফোন, চার্জার, কেবল, হেডফোন, পাওয়ার ব্যাংক ও অ্যাক্সেসরিজ', 8),
    (N'হার্ডওয়্যার দোকান', N'হার্ডওয়্যার', N'🔧', N'রং, সিমেন্ট, পাইপ, তালা, স্ক্রু, হাতিয়ার ও নির্মাণ সামগ্রী', 9);
END;

-- 1b. Fix legacy category name mismatches so existing products line up with the canonical list above
UPDATE dbo.tbl_CompanyProducts SET Category = N'ইলেকট্রনিক্স শপ' WHERE Category = N'ইলেকট্রনিক্স';
UPDATE dbo.tbl_CompanyProducts SET Category = N'কসমেটিক্স' WHERE Category = N'কসমেটিকস';
UPDATE dbo.tbl_CustomerOrderProducts SET Category = N'ইলেকট্রনিক্স শপ' WHERE Category = N'ইলেকট্রনিক্স';
UPDATE dbo.tbl_CustomerOrderProducts SET Category = N'কসমেটিক্স' WHERE Category = N'কসমেটিকস';
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_Shopkeepers')
BEGIN
    UPDATE dbo.tbl_Shopkeepers SET ShopType = N'ইলেকট্রনিক্স শপ' WHERE ShopType = N'ইলেকট্রনিক্স';
    UPDATE dbo.tbl_Shopkeepers SET ShopType = N'কসমেটিক্স' WHERE ShopType = N'কসমেটিকস';
END;

-- 2. Loan Configuration Table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_LoanConfig')
BEGIN
    CREATE TABLE dbo.tbl_LoanConfig (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ConfigKey NVARCHAR(50) NOT NULL UNIQUE,
        MinAmount DECIMAL(18,2) NOT NULL DEFAULT 5000.00,
        MaxAmount DECIMAL(18,2) NOT NULL DEFAULT 50000.00,
        AnnualInterestRate DECIMAL(5,2) NOT NULL DEFAULT 9.00,
        ProcessingFeePercent DECIMAL(5,2) NOT NULL DEFAULT 0.50,
        MinProcessingFee DECIMAL(18,2) NOT NULL DEFAULT 25.00,
        AllowedTenures NVARCHAR(50) NOT NULL DEFAULT '3,6,9,12',
        IsActive BIT NOT NULL DEFAULT 1,
        UpdatedAt DATETIME NOT NULL DEFAULT GETDATE()
    );

    INSERT INTO dbo.tbl_LoanConfig (ConfigKey, MinAmount, MaxAmount, AnnualInterestRate, ProcessingFeePercent, MinProcessingFee, AllowedTenures)
    VALUES (N'DefaultCustomerLoan', 5000.00, 50000.00, 9.00, 0.50, 25.00, N'3,6,9,12');
END;

-- 3. Ensure Columns in tbl_DistrictPricingConfig
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_DistrictPricingConfig')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.tbl_DistrictPricingConfig') AND name = N'DistrictAdjustmentAmount')
        ALTER TABLE dbo.tbl_DistrictPricingConfig ADD DistrictAdjustmentAmount DECIMAL(18,2) NOT NULL DEFAULT 0.00;
    
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.tbl_DistrictPricingConfig') AND name = N'ServiceCharge')
        ALTER TABLE dbo.tbl_DistrictPricingConfig ADD ServiceCharge DECIMAL(18,2) NOT NULL DEFAULT 10.00;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.tbl_DistrictPricingConfig') AND name = N'PlatformCharge')
        ALTER TABLE dbo.tbl_DistrictPricingConfig ADD PlatformCharge DECIMAL(18,2) NOT NULL DEFAULT 5.00;
END;

-- Ensure all major Bangladesh Districts are present in tbl_DistrictPricingConfig
MERGE dbo.tbl_DistrictPricingConfig AS target
USING (VALUES
    (N'ঢাকা', 1.0000, 0.00, 30.00, 10.00, 5.00, 10.00, 5.00),
    (N'চট্টগ্রাম', 1.0200, 5.00, 40.00, 10.00, 5.00, 10.00, 5.00),
    (N'সিলেট', 1.0250, 5.00, 40.00, 10.00, 5.00, 10.00, 5.00),
    (N'রাজশাহী', 1.0300, 8.00, 45.00, 10.00, 5.00, 10.00, 5.00),
    (N'খুলনা', 1.0300, 8.00, 45.00, 10.00, 5.00, 10.00, 5.00),
    (N'বরিশাল', 1.0350, 10.00, 50.00, 10.00, 5.00, 10.00, 5.00),
    (N'রংপুর', 1.0400, 10.00, 50.00, 10.00, 5.00, 10.00, 5.00),
    (N'ময়মনসিংহ', 1.0200, 5.00, 40.00, 10.00, 5.00, 10.00, 5.00),
    (N'কুমিল্লা', 1.0150, 4.00, 35.00, 10.00, 5.00, 10.00, 5.00),
    (N'বগুড়া', 1.0250, 6.00, 40.00, 10.00, 5.00, 10.00, 5.00),
    (N'গাজীপুর', 1.0050, 2.00, 35.00, 10.00, 5.00, 10.00, 5.00),
    (N'নারায়ণগঞ্জ', 1.0050, 2.00, 35.00, 10.00, 5.00, 10.00, 5.00),
    (N'কক্সবাজার', 1.0450, 12.00, 55.00, 10.00, 5.00, 10.00, 5.00),
    (N'যশোর', 1.0300, 8.00, 45.00, 10.00, 5.00, 10.00, 5.00),
    (N'দিনাজপুর', 1.0450, 12.00, 50.00, 10.00, 5.00, 10.00, 5.00),
    (N'পাবনা', 1.0250, 6.00, 40.00, 10.00, 5.00, 10.00, 5.00),
    (N'টাঙ্গাইল', 1.0150, 4.00, 40.00, 10.00, 5.00, 10.00, 5.00),
    (N'নোয়াখালী', 1.0250, 6.00, 45.00, 10.00, 5.00, 10.00, 5.00),
    (N'ফরিদপুর', 1.0200, 5.00, 40.00, 10.00, 5.00, 10.00, 5.00),
    (N'ব্রাহ্মণবাড়িয়া', 1.0200, 5.00, 40.00, 10.00, 5.00, 10.00, 5.00)
) AS source (DistrictName, TransportMultiplier, DistrictAdjustmentAmount, DefaultDeliveryCharge, ServiceCharge, PlatformCharge, ShopkeeperMarginPercent, CompanyMarginPercent)
ON target.DistrictName = source.DistrictName
WHEN MATCHED THEN
    UPDATE SET
        TransportMultiplier = source.TransportMultiplier,
        DistrictAdjustmentAmount = source.DistrictAdjustmentAmount,
        DefaultDeliveryCharge = source.DefaultDeliveryCharge,
        ServiceCharge = source.ServiceCharge,
        PlatformCharge = source.PlatformCharge,
        ShopkeeperMarginPercent = source.ShopkeeperMarginPercent,
        CompanyMarginPercent = source.CompanyMarginPercent
WHEN NOT MATCHED THEN
    INSERT (DistrictName, TransportMultiplier, DistrictAdjustmentAmount, DefaultDeliveryCharge, ServiceCharge, PlatformCharge, ShopkeeperMarginPercent, CompanyMarginPercent)
    VALUES (source.DistrictName, source.TransportMultiplier, source.DistrictAdjustmentAmount, source.DefaultDeliveryCharge, source.ServiceCharge, source.PlatformCharge, source.ShopkeeperMarginPercent, source.CompanyMarginPercent);

-- 4. Ensure tbl_Loans columns for complete lifecycle
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_Loans')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.tbl_Loans') AND name = N'AdminNotes')
        ALTER TABLE dbo.tbl_Loans ADD AdminNotes NVARCHAR(500) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.tbl_Loans') AND name = N'ApprovedByUserId')
        ALTER TABLE dbo.tbl_Loans ADD ApprovedByUserId INT NULL;
END;

-- 5. SEED 195+ REAL PRODUCTS ACROSS ALL 9 BUSINESS CATEGORIES
DECLARE @CompanyUserId INT = (SELECT TOP 1 Id FROM dbo.tbl_Users WHERE Role = 'Company' AND IsActive = 1);
IF @CompanyUserId IS NULL SET @CompanyUserId = 1;

-- Temporary table to hold 175+ real products
CREATE TABLE #SeedProducts (
    ProductCode NVARCHAR(50),
    Name NVARCHAR(200),
    Category NVARCHAR(100),
    Uom NVARCHAR(50),
    UnitPrice DECIMAL(18,2),
    OpeningStock INT,
    ImageUrl NVARCHAR(500)
);

INSERT INTO #SeedProducts (ProductCode, Name, Category, Uom, UnitPrice, OpeningStock, ImageUrl)
VALUES
-- ==============================================================================
-- 1. মুদির দোকান (Grocery) - 25 items
-- ==============================================================================
('GROC-001', N'মিনিকেট চাল ২৫ কেজি', N'মুদির দোকান', N'ব্যাগ', 1700.00, 100, N'/images/products/grocery/miniket_rice.jpg'),
('GROC-002', N'নাজিরশাইল চাল ২৫ কেজি', N'মুদির দোকান', N'ব্যাগ', 1850.00, 100, N'/images/products/grocery/najirshail_rice.jpg'),
('GROC-003', N'চিনিগুঁড়া সুগন্ধি পোলাও চাল ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 145.00, 200, N'/images/products/grocery/polao_rice.jpg'),
('GROC-004', N'তীর আটা ২ কেজি', N'মুদির দোকান', N'প্যাকেট', 110.00, 200, N'/images/products/grocery/teer_atta.jpg'),
('GROC-005', N'ফ্রেশ ময়দা ২ কেজি', N'মুদির দোকান', N'প্যাকেট', 140.00, 200, N'/images/products/grocery/fresh_maida.jpg'),
('GROC-006', N'দেশি মসুর ডাল ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 135.00, 150, N'/images/products/grocery/masoor_dal.jpg'),
('GROC-007', N'সোনালী মুগ ডাল ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 160.00, 100, N'/images/products/grocery/moong_dal.jpg'),
('GROC-008', N'বুট ডাল ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 110.00, 150, N'/images/products/grocery/chana_dal.jpg'),
('GROC-009', N'রূপচাঁদা ফর্টিফাইড সয়াবিন তেল ৫ লিটার', N'মুদির দোকান', N'বোতল', 820.00, 50, N'/images/products/grocery/rupchanda_oil_5l.jpg'),
('GROC-010', N'তীর সয়াবিন তেল ২ লিটার', N'মুদির দোকান', N'বোতল', 330.00, 80, N'/images/products/grocery/teer_oil_2l.jpg'),
('GROC-011', N'রাধুনী সরিষার তেল ১ লিটার', N'মুদির দোকান', N'বোতল', 250.00, 60, N'/images/products/grocery/radhuni_mustard_oil.jpg'),
('GROC-012', N'ফ্রেশ আয়োডাইজড লবণ ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 42.00, 300, N'/images/products/grocery/fresh_salt.jpg'),
('GROC-013', N'ডিপ্লোমা ফুল ক্রিম গুঁড়ো দুধ ৫০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 420.00, 120, N'/images/products/grocery/diploma_milk.jpg'),
('GROC-014', N'ডানো গুঁড়ো দুধ ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 850.00, 80, N'/images/products/grocery/dano_milk.jpg'),
('GROC-015', N'মার্কস গুঁড়ো দুধ ৫০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 410.00, 100, N'/images/products/grocery/marks_milk.jpg'),
('GROC-016', N'ইস্পাহানি মির্জাপুর চা ৪০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 190.00, 150, N'/images/products/grocery/ispahani_tea.jpg'),
('GROC-017', N'তাজা প্রিমিয়াম চা ২০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 95.00, 200, N'/images/products/grocery/taaza_tea.jpg'),
('GROC-018', N'ম্যাগি ২ মিনিট নুডলস ৮ প্যাক', N'মুদির দোকান', N'প্যাকেট', 140.00, 150, N'/images/products/grocery/maggi_noodles.jpg'),
('GROC-019', N'কোকোলা এগ নুডলস ৩৫০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 45.00, 200, N'/images/products/grocery/cocola_noodles.jpg'),
('GROC-020', N'রাধুনী হলুদ গুঁড়া ২০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 65.00, 150, N'/images/products/grocery/radhuni_turmeric.jpg'),
('GROC-021', N'রাধুনী মরিচ গুঁড়া ২০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 100.00, 150, N'/images/products/grocery/radhuni_chilli.jpg'),
('GROC-022', N'রাধুনী ধনিয়া গুঁড়া ২০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 70.00, 150, N'/images/products/grocery/radhuni_coriander.jpg'),
('GROC-023', N'প্রাণ টমেটো সস ৩৪০ গ্রাম', N'মুদির দোকান', N'বোতল', 90.00, 100, N'/images/products/grocery/pran_sauce.jpg'),
('GROC-024', N'ফ্রেশ সাদা চিনি ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 145.00, 200, N'/images/products/grocery/sugar.jpg'),
('GROC-025', N'ফার্মের লাল ডিম ১ ডজন', N'মুদির দোকান', N'ডজন', 150.00, 300, N'/images/products/grocery/eggs.jpg'),

-- ==============================================================================
-- 2. কসমেটিক্স (Cosmetics) - 25 items
-- ==============================================================================
('COSM-001', N'ফেয়ার অ্যান্ড লাভলী ক্রিম ৫০ গ্রাম', N'কসমেটিক্স', N'পিস', 120.00, 150, N'/images/products/cosmetics/fair_lovely.jpg'),
('COSM-002', N'পন্ডস ব্রাইট বিউটি ৫০ গ্রাম', N'কসমেটিক্স', N'পিস', 160.00, 120, N'/images/products/cosmetics/ponds_bright.jpg'),
('COSM-003', N'গার্নিয়ার মেন ফেস ওয়াশ ১০০ গ্রাম', N'কসমেটিক্স', N'টিউব', 220.00, 100, N'/images/products/cosmetics/garnier_men.jpg'),
('COSM-004', N'হিমালয়া নিম ফেস ওয়াশ ১০০ মিলি', N'কসমেটিক্স', N'টিউব', 150.00, 150, N'/images/products/cosmetics/himalaya_neem.jpg'),
('COSM-005', N'নিভিয়া সফট ময়েশ্চারাইজিং ক্রিম ১০০ মিলি', N'কসমেটিক্স', N'পট', 280.00, 80, N'/images/products/cosmetics/nivea_soft.jpg'),
('COSM-006', N'ভ্যাসলিন বডি লোশন ২০০ মিলি', N'কসমেটিক্স', N'বোতল', 260.00, 100, N'/images/products/cosmetics/vaseline_lotion.jpg'),
('COSM-007', N'ডোভ ডেইলি ময়েশ্চার শ্যাম্পু ৩৪০ মিলি', N'কসমেটিক্স', N'বোতল', 380.00, 80, N'/images/products/cosmetics/dove_shampoo.jpg'),
('COSM-008', N'সানসিল্ক ব্ল্যাক শাইন শ্যাম্পু ৩৭৫ মিলি', N'কসমেটিক্স', N'বোতল', 350.00, 100, N'/images/products/cosmetics/sunsilk_shampoo.jpg'),
('COSM-009', N'ক্লিয়ার মেন কুল স্পোর্ট শ্যাম্পু ১৭০ মিলি', N'কসমেটিক্স', N'বোতল', 220.00, 120, N'/images/products/cosmetics/clear_men.jpg'),
('COSM-010', N'প্যান্টিন প্রো-ভি হেয়ার ফল শ্যাম্পু ৩৪০ মিলি', N'কসমেটিক্স', N'বোতল', 390.00, 70, N'/images/products/cosmetics/pantene_shampoo.jpg'),
('COSM-011', N'প্যারাসুট নারিকেল তেল ২০০ মিলি', N'কসমেটিক্স', N'বোতল', 120.00, 200, N'/images/products/cosmetics/parachute_oil.jpg'),
('COSM-012', N'কুমারিকা হারবাল হেয়ার অয়েল ১০০ মিলি', N'কসমেটিক্স', N'বোতল', 95.00, 150, N'/images/products/cosmetics/kumarika_oil.jpg'),
('COSM-013', N'ডাবর ভাটিকা অলিভ হেয়ার অয়েল ২০০ মিলি', N'কসমেটিক্স', N'বোতল', 180.00, 100, N'/images/products/cosmetics/vatika_oil.jpg'),
('COSM-014', N'লাক্স ভেলভেট গ্লো সাবান ১০০ গ্রাম', N'কসমেটিক্স', N'পিস', 45.00, 300, N'/images/products/cosmetics/lux_soap.jpg'),
('COSM-015', N'ডোভ বিউটি ক্রিম বার ১০০ গ্রাম', N'কসমেটিক্স', N'পিস', 95.00, 150, N'/images/products/cosmetics/dove_soap.jpg'),
('COSM-016', N'স্যান্ডেলিনা স্যান্ডাল সোপ ১০০ গ্রাম', N'কসমেটিক্স', N'পিস', 50.00, 200, N'/images/products/cosmetics/sandalina_soap.jpg'),
('COSM-017', N'ডেটোল অরিজিনাল অ্যান্টিসেপটিক সাবান ১০০ গ্রাম', N'কসমেটিক্স', N'পিস', 60.00, 250, N'/images/products/cosmetics/dettol_soap.jpg'),
('COSM-018', N'ক্লোজ আপ রেড হট টুথপেস্ট ১০০ গ্রাম', N'কসমেটিক্স', N'টিউব', 65.00, 200, N'/images/products/cosmetics/closeup_toothpaste.jpg'),
('COSM-019', N'পেপসোডেন্ট জামিচেক টুথপেস্ট ১০০ গ্রাম', N'কসমেটিক্স', N'টিউব', 65.00, 200, N'/images/products/cosmetics/pepsodent.jpg'),
('COSM-020', N'সেনসোডাইন ফ্রেশ মিন্ট ১০০ গ্রাম', N'কসমেটিক্স', N'টিউব', 180.00, 100, N'/images/products/cosmetics/sensodyne.jpg'),
('COSM-021', N'ফগ বডি স্প্রে ১২০ মিলি', N'কসমেটিক্স', N'বোতল', 350.00, 80, N'/images/products/cosmetics/fogg_spray.jpg'),
('COSM-022', N'এক্স ডার্ক টেম্পটেশন বডি স্প্রে ১৫০ মিলি', N'কসমেটিক্স', N'বোতল', 320.00, 100, N'/images/products/cosmetics/axe_spray.jpg'),
('COSM-023', N'জিলেট ফোম শেভিং ক্রিম ২০০ গ্রাম', N'কসমেটিক্স', N'বোতল', 280.00, 60, N'/images/products/cosmetics/gillette_foam.jpg'),
('COSM-024', N'জিলেট ম্যাক৩ রেজোর ব্লেড', N'কসমেটিক্স', N'পিস', 250.00, 100, N'/images/products/cosmetics/gillette_mach3.jpg'),
('COSM-025', N'এনচ্যান্টার ট্যালকম পাউডার ২০০ গ্রাম', N'কসমেটিক্স', N'পিস', 220.00, 80, N'/images/products/cosmetics/enchanteur_powder.jpg'),

-- ==============================================================================
-- 3. ফার্মেসি (Pharmacy) - 25 items
-- ==============================================================================
('PHARM-001', N'Napa Extend 665mg Paracetamol', N'ফার্মেসি', N'বক্স', 15.00, 500, N'/images/products/pharmacy/napa_extend.jpg'),
('PHARM-002', N'Seclo 20mg Omeprazole', N'ফার্মেসি', N'বক্স', 50.00, 300, N'/images/products/pharmacy/seclo_20.jpg'),
('PHARM-003', N'Maxpro 20mg Esomeprazole', N'ফার্মেসি', N'বক্স', 60.00, 300, N'/images/products/pharmacy/maxpro_20.jpg'),
('PHARM-004', N'Sergel 20mg Esomeprazole', N'ফার্মেসি', N'বক্স', 70.00, 300, N'/images/products/pharmacy/sergel_20.jpg'),
('PHARM-005', N'Fexo 120mg Fexofenadine', N'ফার্মেসি', N'বক্স', 80.00, 200, N'/images/products/pharmacy/fexo_120.jpg'),
('PHARM-006', N'Alatrol 10mg Cetirizine', N'ফার্মেসি', N'বক্স', 30.00, 400, N'/images/products/pharmacy/alatrol_10.jpg'),
('PHARM-007', N'Monas 10mg Montelukast', N'ফার্মেসি', N'বক্স', 150.00, 200, N'/images/products/pharmacy/monas_10.jpg'),
('PHARM-008', N'Azithromycin 500mg (Zimax)', N'ফার্মেসি', N'বক্স', 350.00, 100, N'/images/products/pharmacy/zimax_500.jpg'),
('PHARM-009', N'Cefuroxime 500mg (Kilbac)', N'ফার্মেসি', N'বক্স', 450.00, 100, N'/images/products/pharmacy/kilbac_500.jpg'),
('PHARM-010', N'Ciprofloxacin 500mg (Neofloxin)', N'ফার্মেসি', N'বক্স', 150.00, 150, N'/images/products/pharmacy/neofloxin.jpg'),
('PHARM-011', N'Entacyd Plus Suspension 200ml', N'ফার্মেসি', N'বোতল', 85.00, 200, N'/images/products/pharmacy/entacyd.jpg'),
('PHARM-012', N'Gaviscon Antacid Suspension 200ml', N'ফার্মেসি', N'বোতল', 120.00, 150, N'/images/products/pharmacy/gaviscon.jpg'),
('PHARM-013', N'Tufnil 200mg Migraine Tablet', N'ফার্মেসি', N'বক্স', 100.00, 200, N'/images/products/pharmacy/tufnil.jpg'),
('PHARM-014', N'Ecosprin 75mg Aspirin', N'ফার্মেসি', N'বক্স', 50.00, 300, N'/images/products/pharmacy/ecosprin.jpg'),
('PHARM-015', N'Losartan Potassium 50mg (Osartil)', N'ফার্মেসি', N'বক্স', 150.00, 200, N'/images/products/pharmacy/osartil.jpg'),
('PHARM-016', N'Amlodipine 5mg (Amdocal)', N'ফার্মেসি', N'বক্স', 100.00, 250, N'/images/products/pharmacy/amdocal.jpg'),
('PHARM-017', N'Atorvastatin 10mg (Atova)', N'ফার্মেসি', N'বক্স', 180.00, 200, N'/images/products/pharmacy/atova.jpg'),
('PHARM-018', N'Metformin 500mg (Comet)', N'ফার্মেসি', N'বক্স', 120.00, 300, N'/images/products/pharmacy/comet.jpg'),
('PHARM-019', N'Vildagliptin 50mg (Galvus)', N'ফার্মেসি', N'বক্স', 250.00, 150, N'/images/products/pharmacy/galvus.jpg'),
('PHARM-020', N'Cavit-C Chewable Vitamin C', N'ফার্মেসি', N'বক্স', 90.00, 400, N'/images/products/pharmacy/cavit_c.jpg'),
('PHARM-021', N'B-50 Forte Vitamin B-Complex', N'ফার্মেসি', N'বক্স', 110.00, 300, N'/images/products/pharmacy/b_50.jpg'),
('PHARM-022', N'Aristocal D Calcium + Vitamin D3', N'ফার্মেসি', N'বক্স', 200.00, 200, N'/images/products/pharmacy/aristocal_d.jpg'),
('PHARM-023', N'এসএমসি খাবার স্যালাইন-এন', N'ফার্মেসি', N'প্যাকেট', 6.00, 1000, N'/images/products/pharmacy/orsaline.jpg'),
('PHARM-024', N'স্যাভলন অ্যান্টিসেপটিক ক্রিম ৬০ গ্রাম', N'ফার্মেসি', N'টিউব', 45.00, 200, N'/images/products/pharmacy/savlon_cream.jpg'),
('PHARM-025', N'বার্নসিল সিলভার সালফাডায়াজিন ক্রিম', N'ফার্মেসি', N'টিউব', 55.00, 150, N'/images/products/pharmacy/burnsil.jpg'),

-- ==============================================================================
-- 4. জামা-কাপড় (Clothing) - 20 items
-- ==============================================================================
('CLOTH-001', N'পুরুষদের কটন ক্যাজুয়াল শার্ট (ফুল স্লিভ)', N'জামা-কাপড়', N'পিস', 750.00, 50, N'/images/products/clothing/men_shirt.jpg'),
('CLOTH-002', N'পুরুষদের ফরমাল কটন শার্ট', N'জামা-কাপড়', N'পিস', 850.00, 50, N'/images/products/clothing/formal_shirt.jpg'),
('CLOTH-003', N'১০০% কম্বড কটন রাউন্ড নেক টি-শার্ট', N'জামা-কাপড়', N'পিস', 280.00, 100, N'/images/products/clothing/tshirt_round.jpg'),
('CLOTH-004', N'পুরুষদের পোলো কলার টি-শার্ট', N'জামা-কাপড়', N'পিস', 450.00, 80, N'/images/products/clothing/polo_tshirt.jpg'),
('CLOTH-005', N'আড়ং স্টাইল প্রিমিয়াম কটন পাঞ্জাবি', N'জামা-কাপড়', N'পিস', 1250.00, 40, N'/images/products/clothing/panjabi_cotton.jpg'),
('CLOTH-006', N'সেমি-লং ডিজিটাল প্রিন্ট পাঞ্জাবি', N'জামা-কাপড়', N'পিস', 950.00, 50, N'/images/products/clothing/panjabi_printed.jpg'),
('CLOTH-007', N'পুরুষদের সুতি সাদা পায়জামা', N'জামা-কাপড়', N'পিস', 350.00, 80, N'/images/products/clothing/payjama.jpg'),
('CLOTH-008', N'স্ট্রেচেবল ডেনিম জিন্স প্যান্ট', N'জামা-কাপড়', N'পিস', 980.00, 60, N'/images/products/clothing/denim_jeans.jpg'),
('CLOTH-009', N'পুরুষদের গ্যাবার্ডিন ফরমাল ট্রাউজার', N'জামা-কাপড়', N'পিস', 750.00, 60, N'/images/products/clothing/gabardine_pant.jpg'),
('CLOTH-010', N'আরামদায়ক কটন ট্রাউজার / ট্র্যাক প্যান্ট', N'জামা-কাপড়', N'পিস', 350.00, 80, N'/images/products/clothing/track_pant.jpg'),
('CLOTH-011', N'টাঙ্গাইল তাঁতের সুতি প্রিন্টেড শাড়ি', N'জামা-কাপড়', N'পিস', 950.00, 40, N'/images/products/clothing/tangail_saree.jpg'),
('CLOTH-012', N'হাফ সিল্ক উৎসবমুখর জামদানি শাড়ি', N'জামা-কাপড়', N'পিস', 1650.00, 30, N'/images/products/clothing/jamdani_saree.jpg'),
('CLOTH-013', N'মহিলাদের সুতি থ্রি-পিস (আনস্টিচড)', N'জামা-কাপড়', N'সেট', 1150.00, 50, N'/images/products/clothing/three_piece_cotton.jpg'),
('CLOTH-014', N'রেডিমেড জয়পুরী কটন কুর্তি', N'জামা-কাপড়', N'পিস', 650.00, 60, N'/images/products/clothing/kurti_cotton.jpg'),
('CLOTH-015', N'মহিলাদের কটন লেগিংস', N'জামা-কাপড়', N'পিস', 250.00, 100, N'/images/products/clothing/leggings.jpg'),
('CLOTH-016', N'প্লাজো প্যান্ট কটন ফ্রিসাইজ', N'জামা-কাপড়', N'পিস', 320.00, 80, N'/images/products/clothing/palazzo.jpg'),
('CLOTH-017', N'পুরুষদের প্রিমিয়াম সুতি লুঙ্গি (স্ট্যান্ডার্ড)', N'জামা-কাপড়', N'পিস', 450.00, 100, N'/images/products/clothing/lungi_cotton.jpg'),
('CLOTH-018', N'শিশুদের সুতি জামা সেট (১-৩ বছর)', N'জামা-কাপড়', N'সেট', 420.00, 60, N'/images/products/clothing/kids_dress.jpg'),
('CLOTH-019', N'শিশুদের কটন টি-শার্ট ও শর্টস সেট', N'জামা-কাপড়', N'সেট', 380.00, 60, N'/images/products/clothing/kids_shorts.jpg'),
('CLOTH-020', N'নরম সুতি গামছা ২ হাত', N'জামা-কাপড়', N'পিস', 120.00, 150, N'/images/products/clothing/gamcha.jpg'),

-- ==============================================================================
-- 5. জুতার দোকান (Footwear) - 20 items
-- ==============================================================================
('SHOE-001', N'পুরুষদের বাটা স্টাইল ফরমাল লেদার শু', N'জুতার দোকান', N'জোড়া', 1850.00, 40, N'/images/products/footwear/formal_leather_shoe.jpg'),
('SHOE-002', N'পুরুষদের অ্যাপেক্স ক্যাজুয়াল লোফার', N'জুতার দোকান', N'জোড়া', 1450.00, 40, N'/images/products/footwear/casual_loafer.jpg'),
('SHOE-003', N'পুরুষদের রানিং কেডস ও স্নিকার্স', N'জুতার দোকান', N'জোড়া', 950.00, 50, N'/images/products/footwear/running_sneakers.jpg'),
('SHOE-004', N'লাইটওয়েট স্পোর্টস কেডস', N'জুতার দোকান', N'জোড়া', 850.00, 50, N'/images/products/footwear/sports_shoes.jpg'),
('SHOE-005', N'পুরুষদের লেদার স্যান্ডেল শু', N'জুতার দোকান', N'জোড়া', 1150.00, 45, N'/images/products/footwear/leather_sandal.jpg'),
('SHOE-006', N'পুরুষদের দৈনন্দিন পিইউ স্যান্ডেল', N'জুতার দোকান', N'জোড়া', 480.00, 80, N'/images/products/footwear/pu_sandal.jpg'),
('SHOE-007', N'বাটা স্পঞ্জ আরামদায়ক স্লিপার', N'জুতার দোকান', N'জোড়া', 190.00, 120, N'/images/products/footwear/sponge_slipper.jpg'),
('SHOE-008', N'পুরুষদের ওয়াটারপ্রুফ রেইন স্লিপার', N'জুতার দোকান', N'জোড়া', 220.00, 100, N'/images/products/footwear/rain_slipper.jpg'),
('SHOE-009', N'মহিলাদের ফ্ল্যাট আরামদায়ক স্যান্ডেল', N'জুতার দোকান', N'জোড়া', 550.00, 60, N'/images/products/footwear/ladies_flat_sandal.jpg'),
('SHOE-010', N'মহিলাদের পার্টি হিল স্যান্ডেল', N'জুতার দোকান', N'জোড়া', 850.00, 40, N'/images/products/footwear/ladies_heel_sandal.jpg'),
('SHOE-011', N'মহিলাদের ক্যাজুয়াল স্নিকার্স', N'জুতার দোকান', N'জোড়া', 750.00, 50, N'/images/products/footwear/ladies_sneakers.jpg'),
('SHOE-012', N'মহিলাদের আরামদায়ক স্লিপার', N'জুতার দোকান', N'জোড়া', 220.00, 80, N'/images/products/footwear/ladies_slipper.jpg'),
('SHOE-013', N'স্কুল শু কালো লেদার (ছেলেদের)', N'জুতার দোকান', N'জোড়া', 650.00, 60, N'/images/products/footwear/school_shoes_boys.jpg'),
('SHOE-014', N'স্কুল শু সাদা কেডস', N'জুতার দোকান', N'জোড়া', 550.00, 60, N'/images/products/footwear/school_shoes_white.jpg'),
('SHOE-015', N'শিশুদের লাইটিং কিডস স্নিকার্স', N'জুতার দোকান', N'জোড়া', 620.00, 50, N'/images/products/footwear/kids_light_shoes.jpg'),
('SHOE-016', N'শিশুদের নরম বেবি শু', N'জুতার দোকান', N'জোড়া', 320.00, 60, N'/images/products/footwear/baby_soft_shoes.jpg'),
('SHOE-017', N'পুরুষদের সুতি মোজা ৩ জোড়া প্যাক', N'জুতার দোকান', N'প্যাক', 150.00, 100, N'/images/products/footwear/cotton_socks.jpg'),
('SHOE-018', N'মহিলাদের অ্যাঙ্কল মোজা ৩ জোড়া', N'জুতার দোকান', N'প্যাক', 120.00, 100, N'/images/products/footwear/ankle_socks.jpg'),
('SHOE-019', N'কিউই শু পলিশ কালো ৫০ মিলি', N'জুতার দোকান', N'টিন', 65.00, 150, N'/images/products/footwear/kiwi_polish.jpg'),
('SHOE-020', N'প্রিমিয়াম শু ব্রাশ ও শাইনার', N'জুতার দোকান', N'পিস', 95.00, 100, N'/images/products/footwear/shoe_brush.jpg'),

-- ==============================================================================
-- 6. কাঁচা বাজার (Raw Market / Produce) - 20 items
-- ==============================================================================
('VEG-001', N'দেশি আলু ১ কেজি', N'কাঁচা বাজার', N'কেজি', 35.00, 200, N'/images/products/produce/potato.jpg'),
('VEG-002', N'দেশি পেঁয়াজ ১ কেজি', N'কাঁচা বাজার', N'কেজি', 65.00, 200, N'/images/products/produce/onion.jpg'),
('VEG-003', N'রসুন ১ কেজি', N'কাঁচা বাজার', N'কেজি', 160.00, 100, N'/images/products/produce/garlic.jpg'),
('VEG-004', N'আদা ১ কেজি', N'কাঁচা বাজার', N'কেজি', 180.00, 100, N'/images/products/produce/ginger.jpg'),
('VEG-005', N'কাঁচা মরিচ ২৫০ গ্রাম', N'কাঁচা বাজার', N'প্যাকেট', 30.00, 150, N'/images/products/produce/green_chilli.jpg'),
('VEG-006', N'দেশি তাজা টমেটো ১ কেজি', N'কাঁচা বাজার', N'কেজি', 50.00, 120, N'/images/products/produce/tomato.jpg'),
('VEG-007', N'তাজা বেগুন ১ কেজি', N'কাঁচা বাজার', N'কেজি', 45.00, 100, N'/images/products/produce/eggplant.jpg'),
('VEG-008', N'কচি মিষ্টি লাউ ১ পিস', N'কাঁচা বাজার', N'পিস', 60.00, 80, N'/images/products/produce/bottle_gourd.jpg'),
('VEG-009', N'সবুজ শসা ১ কেজি', N'কাঁচা বাজার', N'কেজি', 40.00, 100, N'/images/products/produce/cucumber.jpg'),
('VEG-010', N'ফ্রেশ গাজর ১ কেজি', N'কাঁচা বাজার', N'কেজি', 60.00, 80, N'/images/products/produce/carrot.jpg'),
('VEG-011', N'পটল ১ কেজি', N'কাঁচা বাজার', N'কেজি', 45.00, 80, N'/images/products/produce/pointed_gourd.jpg'),
('VEG-012', N'সবুজ ঢ্যাঁড়শ ১ কেজি', N'কাঁচা বাজার', N'কেজি', 45.00, 80, N'/images/products/produce/okra.jpg'),
('VEG-013', N'তাজা ফুলকপি ১ পিস', N'কাঁচা বাজার', N'পিস', 35.00, 100, N'/images/products/produce/cauliflower.jpg'),
('VEG-014', N'তাজা বাঁধাকপি ১ পিস', N'কাঁচা বাজার', N'পিস', 30.00, 100, N'/images/products/produce/cabbage.jpg'),
('VEG-015', N'টাটকা লাল শাক ২ আঁটি', N'কাঁচা বাজার', N'আঁটি', 25.00, 100, N'/images/products/produce/red_spinach.jpg'),
('VEG-016', N'সবুজ পালং শাক ২ আঁটি', N'কাঁচা বাজার', N'আঁটি', 30.00, 100, N'/images/products/produce/spinach.jpg'),
('VEG-017', N'সুমিষ্ট সাগর কলা ১ ডজন', N'কাঁচা বাজার', N'ডজন', 90.00, 120, N'/images/products/produce/banana.jpg'),
('VEG-018', N'তাজা আপেল ১ কেজি', N'কাঁচা বাজার', N'কেজি', 260.00, 60, N'/images/products/produce/apple.jpg'),
('VEG-019', N'মিষ্টি মাল্টা ১ কেজি', N'কাঁচা বাজার', N'কেজি', 220.00, 60, N'/images/products/produce/malta.jpg'),
('VEG-020', N'কাগজি লেবু ৪ পিস', N'কাঁচা বাজার', N'হালি', 30.00, 150, N'/images/products/produce/lemon.jpg'),

-- ==============================================================================
-- 7. ইলেকট্রনিক্স শপ (Electronics) - 20 items
-- ==============================================================================
('ELEC-001', N'ওয়ালটন এনার্জি সেভিং এলইডি বাল্ব ১৫ ওয়াট', N'ইলেকট্রনিক্স শপ', N'পিস', 220.00, 100, N'/images/products/electronics/walton_bulb_15w.jpg'),
('ELEC-002', N'সুপার স্টার এলইডি বাল্ব ২০ ওয়াট', N'ইলেকট্রনিক্স শপ', N'পিস', 280.00, 100, N'/images/products/electronics/superstar_bulb_20w.jpg'),
('ELEC-003', N'এনার্জিপ্যাক এলইডি টিউব লাইট ২০ ওয়াট', N'ইলেকট্রনিক্স শপ', N'পিস', 180.00, 150, N'/images/products/electronics/energypac_tube.jpg'),
('ELEC-004', N'ওয়ালটন সিলিং ফ্যান ৫৬ ইঞ্চি', N'ইলেকট্রনিক্স শপ', N'পিস', 2800.00, 30, N'/images/products/electronics/walton_fan_56.jpg'),
('ELEC-005', N'বিআরবি সিলিং ফ্যান ৫৬ ইঞ্চি', N'ইলেকট্রনিক্স শপ', N'পিস', 3200.00, 25, N'/images/products/electronics/brb_fan_56.jpg'),
('ELEC-006', N'সুপার স্টার মাল্টিপ্লাগ ৪ পোর্ট (৩ মিটার তার)', N'ইলেকট্রনিক্স শপ', N'পিস', 450.00, 80, N'/images/products/electronics/multiplug_4port.jpg'),
('ELEC-007', N'ওয়ালটন হেভি ডিউটি মাল্টিপ্লাগ ৫ পোর্ট', N'ইলেকট্রনিক্স শপ', N'পিস', 550.00, 60, N'/images/products/electronics/multiplug_5port.jpg'),
('ELEC-008', N'টিপি-লিংক ওয়াইফাই রাউটার Archer C6', N'ইলেকট্রনিক্স শপ', N'পিস', 2800.00, 20, N'/images/products/electronics/tplink_router.jpg'),
('ELEC-009', N'টেন্ডা এফ৩ হাই স্পিড ওয়াইফাই রাউটার', N'ইলেকট্রনিক্স শপ', N'পিস', 1250.00, 30, N'/images/products/electronics/tenda_router.jpg'),
('ELEC-010', N'এফোরটেক ইউএসবি অপটিক্যাল মাউস', N'ইলেকট্রনিক্স শপ', N'পিস', 450.00, 50, N'/images/products/electronics/a4tech_mouse.jpg'),
('ELEC-011', N'লজিটেক ওয়্যারলেস মাউস M185', N'ইলেকট্রনিক্স শপ', N'পিস', 950.00, 40, N'/images/products/electronics/logitech_mouse.jpg'),
('ELEC-012', N'এফোরটেক স্ট্যান্ডার্ড ইউএসবি কীবোর্ড', N'ইলেকট্রনিক্স শপ', N'পিস', 650.00, 30, N'/images/products/electronics/a4tech_keyboard.jpg'),
('ELEC-013', N'সানডিস্ক পেন ড্রাইভ ৩২ জিবি ইউএসবি ৩.০', N'ইলেকট্রনিক্স শপ', N'পিস', 450.00, 60, N'/images/products/electronics/sandisk_32gb.jpg'),
('ELEC-014', N'সানডিস্ক পেন ড্রাইভ ৬৪ জিবি ইউএসবি ৩.০', N'ইলেকট্রনিক্স শপ', N'পিস', 650.00, 50, N'/images/products/electronics/sandisk_64gb.jpg'),
('ELEC-015', N'ট্রানসেন্ড মেমোরি কার্ড ৩২ জিবি ক্লাস ১০', N'ইলেকট্রনিক্স শপ', N'পিস', 400.00, 60, N'/images/products/electronics/transcend_32gb.jpg'),
('ELEC-016', N'ভিশন অটোমেটিক ইলেকট্রিক ইস্ত্রি ১০০০ ওয়াট', N'ইলেকট্রনিক্স শপ', N'পিস', 1250.00, 25, N'/images/products/electronics/vision_iron.jpg'),
('ELEC-017', N'মিয়াকো ব্লেন্ডার ও জুসার ৩ ইন ১ (৭৫০ ওয়াট)', N'ইলেকট্রনিক্স শপ', N'পিস', 3500.00, 15, N'/images/products/electronics/miyako_blender.jpg'),
('ELEC-018', N'ওয়ালটন ইলেকট্রিক রাইস কুকার ২.৮ লিটার', N'ইলেকট্রনিক্স শপ', N'পিস', 2400.00, 20, N'/images/products/electronics/walton_rice_cooker.jpg'),
('ELEC-019', N'সুপার স্টার রুম হিটার ফ্যান ২০০০ ওয়াট', N'ইলেকট্রনিক্স শপ', N'পিস', 1850.00, 20, N'/images/products/electronics/room_heater.jpg'),
('ELEC-020', N'রিচার্জেবল ইমার্জেন্সি এলইডি ল্যাম্প', N'ইলেকট্রনিক্স শপ', N'পিস', 450.00, 40, N'/images/products/electronics/emergency_lamp.jpg'),

-- ==============================================================================
-- 8. মোবাইল ফোনের দোকান (Mobile Phones & Gadgets) - 20 items
-- ==============================================================================
('MOB-001', N'স্যামসাং গ্যালাক্সি A05 (4GB/64GB)', N'মোবাইল ফোনের দোকান', N'পিস', 12999.00, 10, N'/images/products/mobile/samsung_a05.jpg'),
('MOB-002', N'শাওমি রেডমি 13C (6GB/128GB)', N'মোবাইল ফোনের দোকান', N'পিস', 14499.00, 10, N'/images/products/mobile/redmi_13c.jpg'),
('MOB-003', N'রিয়েলমি C53 (6GB/128GB)', N'মোবাইল ফোনের দোকান', N'পিস', 13999.00, 10, N'/images/products/mobile/realme_c53.jpg'),
('MOB-004', N'ওয়ালটন প্রিমো ফাস্ট বাটন ফোন (ডুয়েল সিম)', N'মোবাইল ফোনের দোকান', N'পিস', 1450.00, 30, N'/images/products/mobile/walton_feature_phone.jpg'),
('MOB-005', N'আইটেল ম্যাজিক এক্স ফিচার ফোন', N'মোবাইল ফোনের দোকান', N'পিস', 1750.00, 25, N'/images/products/mobile/itel_feature_phone.jpg'),
('MOB-006', N'শাওমি ফাস্ট চার্জার ৩৩ ওয়াট টাইপ-সি এডাপ্টার', N'মোবাইল ফোনের দোকান', N'পিস', 850.00, 40, N'/images/products/mobile/xiaomi_33w_charger.jpg'),
('MOB-007', N'স্যামসাং অরিজিনাল ২৫ ওয়াট সুপার ফাস্ট চার্জার', N'মোবাইল ফোনের দোকান', N'পিস', 1150.00, 30, N'/images/products/mobile/samsung_25w_charger.jpg'),
('MOB-008', N'বেসাস টাইপ-সি ফাস্ট চার্জিং কেবল (৬৫ ওয়াট)', N'মোবাইল ফোনের দোকান', N'পিস', 350.00, 80, N'/images/products/mobile/baseus_typec_cable.jpg'),
('MOB-009', N'রিমেক্স মাইক্রো ইউএসবি ব্রেডেড কেবল', N'মোবাইল ফোনের দোকান', N'পিস', 220.00, 80, N'/images/products/mobile/remax_microusb_cable.jpg'),
('MOB-010', N'আইফোন লাইটনিং ফাস্ট চার্জিং কেবল', N'মোবাইল ফোনের দোকান', N'পিস', 380.00, 50, N'/images/products/mobile/lightning_cable.jpg'),
('MOB-011', N'শাওমি পাওয়ার ব্যাংক ১০০০০ এমএএইচ (২২.৫ ওয়াট)', N'মোবাইল ফোনের দোকান', N'পিস', 1850.00, 20, N'/images/products/mobile/xiaomi_powerbank.jpg'),
('MOB-012', N'রিমেক্স পাওয়ার ব্যাংক ২০০০০ এমএএইচ ডুয়েল ইউএসবি', N'মোবাইল ফোনের দোকান', N'পিস', 1950.00, 20, N'/images/products/mobile/remax_powerbank.jpg'),
('MOB-013', N'আওয়েই টি১৩ প্রো ব্লুটুথ ট্রু ওয়্যারলেস ইয়ারবাডস', N'মোবাইল ফোনের দোকান', N'পিস', 1250.00, 30, N'/images/products/mobile/awei_earbuds.jpg'),
('MOB-014', N'হায়লু GT1 Pro নয়েজ ক্যানসেলিং ইয়ারবাডস', N'মোবাইল ফোনের দোকান', N'পিস', 1650.00, 25, N'/images/products/mobile/haylou_earbuds.jpg'),
('MOB-015', N'স্যামসাং ৩.৫ মিমি ইন-ইয়ার হেডফোন বেস বুস্ট', N'মোবাইল ফোনের দোকান', N'পিস', 350.00, 100, N'/images/products/mobile/samsung_earphones.jpg'),
('MOB-016', N'ইউগ্রিন ইউনিভার্সাল ম্যাগনেটিক কার ফোন হোল্ডার', N'মোবাইল ফোনের দোকান', N'পিস', 450.00, 40, N'/images/products/mobile/car_phone_holder.jpg'),
('MOB-017', N'অ্যালুমিনিয়াম অ্যাডজাস্টেবল ডেস্কটপ মোবাইল স্ট্যান্ড', N'মোবাইল ফোনের দোকান', N'পিস', 250.00, 60, N'/images/products/mobile/mobile_stand.jpg'),
('MOB-018', N'স্মার্টফোন সেলফি স্টিক উইথ ব্লুটুথ রিমোট ও ট্রাইপড', N'মোবাইল ফোনের দোকান', N'পিস', 550.00, 35, N'/images/products/mobile/selfie_stick.jpg'),
('MOB-019', N'স্মার্টফোন ৯ডি টেম্পারড গ্লাস স্ক্রিন প্রটেক্টর', N'মোবাইল ফোনের দোকান', N'পিস', 120.00, 200, N'/images/products/mobile/tempered_glass.jpg'),
('MOB-020', N'স্মার্টফোন ক্লিয়ার ট্রান্সপারেন্ট ব্যাক কাভার', N'মোবাইল ফোনের দোকান', N'পিস', 150.00, 150, N'/images/products/mobile/back_cover.jpg'),

-- ==============================================================================
-- 9. হার্ডওয়্যার দোকান (Hardware) - 20 items
-- ==============================================================================
('HARD-001', N'রংমিস্ত্রি ব্রাশ ৩ ইঞ্চি', N'হার্ডওয়্যার দোকান', N'পিস', 85.00, 100, N'/images/products/hardware/paint_brush_3in.jpg'),
('HARD-002', N'বার্জার ওয়েদারকোট ইমালশন পেইন্ট ১ লিটার', N'হার্ডওয়্যার দোকান', N'টিন', 650.00, 40, N'/images/products/hardware/berger_paint_1l.jpg'),
('HARD-003', N'এশিয়ান প্লাস্টিক ইমালশন পেইন্ট ১ লিটার', N'হার্ডওয়্যার দোকান', N'টিন', 480.00, 40, N'/images/products/hardware/asian_paint_1l.jpg'),
('HARD-004', N'থিনার ১ লিটার', N'হার্ডওয়্যার দোকান', N'বোতল', 180.00, 60, N'/images/products/hardware/thinner_1l.jpg'),
('HARD-005', N'স্টিল প্যাচার / স্ক্র্যাপার', N'হার্ডওয়্যার দোকান', N'পিস', 60.00, 100, N'/images/products/hardware/steel_scraper.jpg'),
('HARD-006', N'মার্বেল ও টাইলস আঠা ১ কেজি', N'হার্ডওয়্যার দোকান', N'প্যাকেট', 45.00, 150, N'/images/products/hardware/tile_adhesive_1kg.jpg'),
('HARD-007', N'শাহ সিমেন্ট ৫০ কেজি ব্যাগ', N'হার্ডওয়্যার দোকান', N'ব্যাগ', 560.00, 80, N'/images/products/hardware/shah_cement_50kg.jpg'),
('HARD-008', N'রড বাইন্ডিং তার ১ কেজি', N'হার্ডওয়্যার দোকান', N'কয়েল', 150.00, 100, N'/images/products/hardware/binding_wire_1kg.jpg'),
('HARD-009', N'পিভিসি পাইপ ৩ ইঞ্চি (১০ ফুট)', N'হার্ডওয়্যার দোকান', N'পিস', 320.00, 50, N'/images/products/hardware/pvc_pipe_3in.jpg'),
('HARD-010', N'জিআই তার ২ মিমি ১ কেজি', N'হার্ডওয়্যার দোকান', N'কয়েল', 180.00, 60, N'/images/products/hardware/gi_wire_2mm.jpg'),
('HARD-011', N'ব্র্যাস তালা ৬৫ মিমি', N'হার্ডওয়্যার দোকান', N'পিস', 350.00, 80, N'/images/products/hardware/brass_lock_65mm.jpg'),
('HARD-012', N'দরজার হ্যান্ডেল লক সেট', N'হার্ডওয়্যার দোকান', N'সেট', 650.00, 40, N'/images/products/hardware/door_handle_lock_set.jpg'),
('HARD-013', N'কব্জা (হিঞ্জ) ৪ ইঞ্চি', N'হার্ডওয়্যার দোকান', N'পিস', 45.00, 200, N'/images/products/hardware/hinge_4in.jpg'),
('HARD-014', N'স্ক্রু ড্রাইভার সেট (৬ পিস)', N'হার্ডওয়্যার দোকান', N'সেট', 250.00, 60, N'/images/products/hardware/screwdriver_set_6pc.jpg'),
('HARD-015', N'হাতুড়ি ৫০০ গ্রাম', N'হার্ডওয়্যার দোকান', N'পিস', 220.00, 60, N'/images/products/hardware/hammer_500g.jpg'),
('HARD-016', N'প্লায়ার্স কম্বিনেশন ৮ ইঞ্চি', N'হার্ডওয়্যার দোকান', N'পিস', 280.00, 50, N'/images/products/hardware/combination_plier_8in.jpg'),
('HARD-017', N'মেজারিং টেপ ৫ মিটার', N'হার্ডওয়্যার দোকান', N'পিস', 150.00, 100, N'/images/products/hardware/measuring_tape_5m.jpg'),
('HARD-018', N'নাট বল্টু সেট (মিক্সড)', N'হার্ডওয়্যার দোকান', N'প্যাকেট', 120.00, 100, N'/images/products/hardware/nut_bolt_set.jpg'),
('HARD-019', N'ইলেকট্রিক ড্রিল মেশিন ৫০০ ওয়াট', N'হার্ডওয়্যার দোকান', N'পিস', 2200.00, 20, N'/images/products/hardware/electric_drill_500w.jpg'),
('HARD-020', N'স্যান্ডপেপার শিট (১০ পিস)', N'হার্ডওয়্যার দোকান', N'প্যাকেট', 90.00, 100, N'/images/products/hardware/sandpaper_sheet_10pc.jpg');

-- Upsert into tbl_CompanyProducts
MERGE dbo.tbl_CompanyProducts AS target
USING #SeedProducts AS source
ON target.ProductCode = source.ProductCode
WHEN MATCHED THEN
    UPDATE SET
        Name = source.Name,
        Category = source.Category,
        Uom = source.Uom,
        UnitPrice = source.UnitPrice,
        OpeningStock = source.OpeningStock,
        ImageUrl = source.ImageUrl,
        IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (ProductCode, Name, Category, Uom, UnitPrice, OpeningStock, ShopkeeperPercentage, CompanyPercentage, AgentPercentage, FieldForcePercentage, CustomerPercentage, CreatedByUserId, ImageUrl, IsActive)
    VALUES (source.ProductCode, source.Name, source.Category, source.Uom, source.UnitPrice, source.OpeningStock, 100.00, 0.00, 0.00, 0.00, 0.00, @CompanyUserId, source.ImageUrl, 1);

-- Upsert into tbl_CustomerOrderProducts
MERGE dbo.tbl_CustomerOrderProducts AS target
USING #SeedProducts AS source
ON target.Sku = source.ProductCode
WHEN MATCHED THEN
    UPDATE SET
        Name = source.Name,
        Category = source.Category,
        UnitPrice = source.UnitPrice,
        ImageUrl = source.ImageUrl,
        IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (Name, Sku, Category, UnitPrice, ImageUrl, IsActive)
    VALUES (source.Name, source.ProductCode, source.Category, source.UnitPrice, source.ImageUrl, 1);

DROP TABLE #SeedProducts;
