DECLARE @CompanyUserId INT = (SELECT TOP 1 Id FROM dbo.tbl_Users WHERE Role = 'Company' AND IsActive = 1);
IF @CompanyUserId IS NULL SET @CompanyUserId = 1;

-- Clean existing products or append
-- We use MERGE / IF NOT EXISTS to insert 175+ products across 8 categories

CREATE TABLE #TempProducts (
    ProductCode NVARCHAR(50),
    Name NVARCHAR(200),
    Category NVARCHAR(100),
    Uom NVARCHAR(50),
    UnitPrice DECIMAL(18,2),
    OpeningStock INT
);

INSERT INTO #TempProducts (ProductCode, Name, Category, Uom, UnitPrice, OpeningStock)
VALUES
-- 1. মুদির দোকান (Grocery) - 26 items
('GROC-001', N'মিনিকেট চাল ২৫ কেজি', N'মুদির দোকান', N'ব্যাগ', 1750.00, 100),
('GROC-002', N'নাজিরশাইল চাল ২৫ কেজি', N'মুদির দোকান', N'ব্যাগ', 1880.00, 100),
('GROC-003', N'বাসমতী চাল ৫ কেজি', N'মুদির দোকান', N'প্যাকেট', 650.00, 80),
('GROC-004', N'চিনিগুড়া পোলাও চাল ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 140.00, 150),
('GROC-005', N'তীর আটা ২ কেজি', N'মুদির দোকান', N'প্যাকেট', 115.00, 200),
('GROC-006', N'তীর ময়দা ২ কেজি', N'মুদির দোকান', N'প্যাকেট', 145.00, 200),
('GROC-007', N'দেশি মসুর ডাল ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 135.00, 150),
('GROC-008', N'মুগ ডাল ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 165.00, 100),
('GROC-009', N'ছোলার ডাল ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 120.00, 120),
('GROC-010', N'রূপচাঁদা সয়াবিন তেল ৫ লিটার', N'মুদির দোকান', N'বোতল', 830.00, 80),
('GROC-011', N'তীর সয়াবিন তেল ২ লিটার', N'মুদির দোকান', N'বোতল', 335.00, 100),
('GROC-012', N'রাধুনী সরিষার তেল ১ লিটার', N'মুদির দোকান', N'বোতল', 255.00, 80),
('GROC-013', N'ফ্রেশ আয়োডিনযুক্ত লবণ ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 42.00, 300),
('GROC-014', N'ফ্রেশ সাদা চিনি ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 145.00, 250),
('GROC-015', N'ডিপ্লোমা গুঁড়ো দুধ ৫০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 430.00, 120),
('GROC-016', N'ডানো গুঁড়ো দুধ ১ কেজি', N'মুদির দোকান', N'প্যাকেট', 860.00, 80),
('GROC-017', N'মার্কস ফুল ক্রিম মিল্ক পাউডার ৫০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 415.00, 100),
('GROC-018', N'ইস্পাহানি মির্জাপুর প্রিমিয়াম চা ৪০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 195.00, 150),
('GROC-019', N'তাজা ব্ল্যাক টি ২০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 98.00, 180),
('GROC-020', N'ম্যাগি মাসালা নুডলস ৮ প্যাক', N'মুদির দোকান', N'প্যাকেট', 145.00, 150),
('GROC-021', N'রাধুনী হলুদ গুঁড়া ২০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 68.00, 200),
('GROC-022', N'রাধুনী মরিচ গুঁড়া ২০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 105.00, 200),
('GROC-023', N'রাধুনী ধনিয়া গুঁড়া ২০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 72.00, 200),
('GROC-024', N'রাধুনী জিরা গুঁড়া ১০০ গ্রাম', N'মুদির দোকান', N'প্যাকেট', 85.00, 180),
('GROC-025', N'প্রান টমেটো সস ৩৪০ গ্রাম', N'মুদির দোকান', N'বোতল', 95.00, 120),
('GROC-026', N'ফার্মের লাল ডিম ১ ডজন', N'মুদির দোকান', N'হালি/ডজন', 150.00, 300),

-- 2. কসমেটিক্স (Cosmetics) - 25 items
('COSM-001', N'Fair & Lovely Advanced Multi-Vitamin 50g', N'কসমেটিক্স', N'পিস', 125.00, 150),
('COSM-002', N'Ponds Bright Beauty Cream 50g', N'কসমেটিক্স', N'পিস', 165.00, 120),
('COSM-003', N'Garnier Men TurboBright Face Wash 100g', N'কসমেটিক্স', N'টিউব', 230.00, 100),
('COSM-004', N'Himalaya Purifying Neem Face Wash 100ml', N'কসমেটিক্স', N'টিউব', 155.00, 150),
('COSM-005', N'Nivea Soft Moisturizing Cream 100ml', N'কসমেটিক্স', N'পট', 285.00, 80),
('COSM-006', N'Vaseline Healthy Bright Body Lotion 200ml', N'কসমেটিক্স', N'বোতল', 265.00, 100),
('COSM-007', N'Dove Intense Repair Shampoo 340ml', N'কসমেটিক্স', N'বোতল', 390.00, 80),
('COSM-008', N'Sunsilk Black Shine Shampoo 375ml', N'কসমেটিক্স', N'বোতল', 360.00, 100),
('COSM-009', N'Clear Men Cool Sport Shampoo 170ml', N'কসমেটিক্স', N'বোতল', 225.00, 120),
('COSM-010', N'Pantene Total Damage Care 340ml', N'কসমেটিক্স', N'বোতল', 395.00, 70),
('COSM-011', N'Parachute Coconut Oil 200ml', N'কসমেটিক্স', N'বোতল', 125.00, 200),
('COSM-012', N'Kumarika Ayurvedic Hair Oil 100ml', N'কসমেটিক্স', N'বোতল', 98.00, 150),
('COSM-013', N'Vatika Enriched Coconut Hair Oil 200ml', N'কসমেটিক্স', N'বোতল', 185.00, 100),
('COSM-014', N'Lux Velvet Touch Beauty Soap 100g', N'কসমেটিক্স', N'পিস', 48.00, 300),
('COSM-015', N'Dove White Beauty Bar 100g', N'কসমেটিক্স', N'পিস', 98.00, 150),
('COSM-016', N'Sandalina Sandal Soap 100g', N'কসমেটিক্স', N'পিস', 52.00, 200),
('COSM-017', N'Dettol Original Bath Soap 100g', N'কসমেটিক্স', N'পিস', 62.00, 250),
('COSM-018', N'Close Up Red Hot Gel Toothpaste 100g', N'কসমেটিক্স', N'টিউব', 68.00, 200),
('COSM-019', N'Pepsodent Expert Protection 100g', N'কসমেটিক্স', N'টিউব', 68.00, 200),
('COSM-020', N'Sensodyne Rapid Relief Toothpaste 100g', N'কসমেটিক্স', N'টিউব', 185.00, 100),
('COSM-021', N'Fogg Marco Fragrance Body Spray 120ml', N'কসমেটিক্স', N'বোতল', 360.00, 80),
('COSM-022', N'Axe Dark Temptation Deodorant 150ml', N'কসমেটিক্স', N'বোতল', 330.00, 100),
('COSM-023', N'Gillette Classic Shaving Foam 200g', N'কসমেটিক্স', N'বোতল', 285.00, 60),
('COSM-024', N'Gillette Mach3 Razor with Blade', N'কসমেটিক্স', N'পিস', 255.00, 100),
('COSM-025', N'Enchanteur Romantic Talcum Powder 200g', N'কসমেটিক্স', N'পিস', 225.00, 80),

-- 3. ফার্মেসি (Pharmacy) - 25 items
('PHARM-001', N'Napa Extend Tablet 665mg (Beximco)', N'ফার্মেসি', N'বক্স', 15.00, 500),
('PHARM-002', N'Seclo 20mg Capsule (Square)', N'ফার্মেসি', N'বক্স', 50.00, 300),
('PHARM-003', N'Maxpro 20mg Capsule (Renata)', N'ফার্মেসি', N'বক্স', 60.00, 300),
('PHARM-004', N'Sergel 20mg Capsule (Healthcare)', N'ফার্মেসি', N'বক্স', 70.00, 300),
('PHARM-005', N'Fexo 120mg Tablet (Square)', N'ফার্মেসি', N'বক্স', 80.00, 200),
('PHARM-006', N'Alatrol 10mg Tablet (Square)', N'ফার্মেসি', N'বক্স', 30.00, 400),
('PHARM-007', N'Monas 10mg Tablet (Acme)', N'ফার্মেসি', N'বক্স', 155.00, 200),
('PHARM-008', N'Azithromycin 500mg (Zithrin)', N'ফার্মেসি', N'বক্স', 350.00, 100),
('PHARM-009', N'Cefuroxime 500mg (Kilbac)', N'ফার্মেসি', N'বক্স', 460.00, 100),
('PHARM-010', N'Ciprofloxacin 500mg (Neofloxin)', N'ফার্মেসি', N'বক্স', 150.00, 150),
('PHARM-011', N'Entacyd Plus Antacid Suspension 200ml', N'ফার্মেসি', N'বোতল', 88.00, 200),
('PHARM-012', N'Gaviscon Liquid Dual Action 150ml', N'ফার্মেসি', N'বোতল', 125.00, 150),
('PHARM-013', N'Tufnil 200mg Tablet (Incepta)', N'ফার্মেসি', N'বক্স', 105.00, 200),
('PHARM-014', N'Ecosprin 75mg Tablet (Acme)', N'ফার্মেসি', N'বক্স', 50.00, 300),
('PHARM-015', N'Losartan Potassium 50mg (Osartil)', N'ফার্মেসি', N'বক্স', 155.00, 200),
('PHARM-016', N'Amlodipine 5mg (Camlodin)', N'ফার্মেসি', N'বক্স', 100.00, 250),
('PHARM-017', N'Atorvastatin 10mg (Atova)', N'ফার্মেসি', N'বক্স', 185.00, 200),
('PHARM-018', N'Metformin 500mg (Comet)', N'ফার্মেসি', N'বক্স', 120.00, 300),
('PHARM-019', N'Vildagliptin 50mg (Galvus)', N'ফার্মেসি', N'বক্স', 255.00, 150),
('PHARM-020', N'Cavit C Chewable Tablet (Square)', N'ফার্মেসি', N'বক্স', 95.00, 400),
('PHARM-021', N'Zinc B Tablet (Aristopharma)', N'ফার্মেসি', N'বক্স', 115.00, 300),
('PHARM-022', N'Aristocal D Tablet 500mg+200IU', N'ফার্মেসি', N'বক্স', 205.00, 200),
('PHARM-023', N'Orsaline-N Oral Saline (SMC)', N'ফার্মেসি', N'প্যাকেট', 6.00, 1000),
('PHARM-024', N'Savlon Antiseptic Cream 60g', N'ফার্মেসি', N'টিউব', 48.00, 200),
('PHARM-025', N'Burnsil Silver Sulfadiazine Cream 25g', N'ফার্মেসি', N'টিউব', 58.00, 150),

-- 4. জামা কাপড় (Apparel / Clothing) - 22 items
('CLOTH-001', N'মেনস প্রিমিয়াম কটন পাঞ্জাবি (সেমি-লং)', N'জামা কাপড়', N'পিস', 1250.00, 50),
('CLOTH-002', N'মেনস ফর্মাল সুতি শার্ট (ফুল স্লিভ)', N'জামা কাপড়', N'পিস', 850.00, 60),
('CLOTH-003', N'মেনস প্রিমিয়াম পোলো টি-শার্ট', N'জামা কাপড়', N'পিস', 480.00, 100),
('CLOTH-004', N'মেনস ড্রপ শোল্ডার ওভারসাইজড টি-শার্ট', N'জামা কাপড়', N'পিস', 380.00, 100),
('CLOTH-005', N'মেনস স্ট্রেচেবল ডেনিম জিন্স প্যান্ট', N'জামা কাপড়', N'পিস', 1150.00, 70),
('CLOTH-006', N'মেনস গ্যাবার্ডিন ফর্মাল ও ক্যাজুয়াল প্যান্ট', N'জামা কাপড়', N'পিস', 950.00, 60),
('CLOTH-007', N'মেনস আরামদায়ক কটন ট্রাউজার', N'জামা কাপড়', N'পিস', 450.00, 80),
('CLOTH-008', N'আমানত শাহ প্রিমিয়াম সুতি লুঙ্গি', N'জামা কাপড়', N'পিস', 550.00, 100),
('CLOTH-009', N'উইমেন্স সুতি বুটিক থ্রি-পিস', N'জামা কাপড়', N'সেট', 1350.00, 60),
('CLOTH-010', N'উইমেন্স জর্জেট এমব্রয়ডারি থ্রি-পিস', N'জামা কাপড়', N'সেট', 1850.00, 40),
('CLOTH-011', N'উইমেন্স স্টাইলিশ কটন কুর্তি', N'জামা কাপড়', N'পিস', 650.00, 80),
('CLOTH-012', N'টাঙ্গাইল সুতি হ্যান্ডলুম শাড়ি', N'জামা কাপড়', N'পিস', 950.00, 50),
('CLOTH-013', N'ঢাকাই প্রিমিয়াম জামদানি শাড়ি', N'জামা কাপড়', N'পিস', 2800.00, 30),
('CLOTH-014', N'উইমেন্স সফট কটন লেগিংস', N'জামা কাপড়', N'পিস', 280.00, 120),
('CLOTH-015', N'বেবি বয়েজ ক্যাজুয়াল টি-শার্ট ও শর্টস সেট', N'জামা কাপড়', N'সেট', 450.00, 80),
('CLOTH-016', N'বেবি বয়েজ ঈদ স্পেশাল পাঞ্জাবি সেট', N'জামা কাপড়', N'সেট', 750.00, 60),
('CLOTH-017', N'বেবি গার্লস কালারফুল পার্টি ফ্রক', N'জামা কাপড়', N'পিস', 650.00, 70),
('CLOTH-018', N'১০০% সুতি রুমাল প্যাক (৩ পিস)', N'জামা কাপড়', N'প্যাক', 120.00, 150),
('CLOTH-019', N'মেনস ফ্লিস উইন্টার হুডি', N'জামা কাপড়', N'পিস', 850.00, 50),
('CLOTH-020', N'উইন্ডব্রেকার লাইটওয়েট জ্যাকেট', N'জামা কাপড়', N'পিস', 1200.00, 40),
('CLOTH-021', N'উইমেন্স সুতি হিজাব ও স্কার্ফ', N'জামা কাপড়', N'পিস', 250.00, 100),
('CLOTH-022', N'মেনস ইনার ভিয়েস্ট (৩ পিস প্যাক)', N'জামা কাপড়', N'প্যাক', 350.00, 100),

-- 5. জুতার দোকান (Footwear) - 20 items
('FOOT-001', N'Apex মেনস প্রিমিয়াম লেদার ফর্মাল শু', N'জুতার দোকান', N'জোড়া', 2650.00, 30),
('FOOT-002', N'বাটা মেনস ড্রেস লেদার শু', N'জুতার দোকান', N'জোড়া', 2250.00, 35),
('FOOT-003', N'বাটা মেনস ক্যাজুয়াল স্নিকার্স', N'জুতার দোকান', N'জোড়া', 1450.00, 50),
('FOOT-004', N'Lotto মেনস স্পোর্টস রানিং শু', N'জুতার দোকান', N'জোড়া', 1850.00, 40),
('FOOT-005', N'Apex জেন্টস প্রিমিয়াম লেদার স্যান্ডেল', N'জুতার দোকান', N'জোড়া', 1650.00, 45),
('FOOT-006', N'জেন্টস ক্যাজুয়াল পিইউ স্লাইডার স্যান্ডেল', N'জুতার দোকান', N'জোড়া', 350.00, 100),
('FOOT-007', N'বাটা লেডিস ক্যাজুয়াল ফ্ল্যাট স্যান্ডেল', N'জুতার দোকান', N'জোড়া', 650.00, 60),
('FOOT-008', N'বাটা লেডিস আরামদায়ক পার্টি হিল', N'জুতার দোকান', N'জোড়া', 1250.00, 40),
('FOOT-009', N'Apex লেডিস এলিগ্যান্ট লেদার স্যান্ডেল', N'জুতার দোকান', N'জোড়া', 1450.00, 40),
('FOOT-010', N'লেডিস সফট ইনডোর ও বাথরুম স্লিপার', N'জুতার দোকান', N'জোড়া', 180.00, 120),
('FOOT-011', N'স্কুল শু ছেলেদের (ব্ল্যাক লেদার)', N'জুতার দোকান', N'জোড়া', 750.00, 60),
('FOOT-012', N'স্কুল শু মেয়েদের (ব্ল্যাক বাকল)', N'জুতার দোকান', N'জোড়া', 700.00, 60),
('FOOT-013', N'বাটা কিডস লাইট স্পোর্টস স্নিকার্স', N'জুতার দোকান', N'জোড়া', 950.00, 50),
('FOOT-014', N'কটন স্পোর্টস মোজা কম্বো (৩ জোড়া)', N'জুতার দোকান', N'প্যাক', 180.00, 150),
('FOOT-015', N'মেনস জেনুইন লেদার ফর্মাল বেল্ট', N'জুতার দোকান', N'পিস', 450.00, 80),
('FOOT-016', N'ওয়াটারপ্রুফ রেইন গাম বুট', N'জুতার দোকান', N'জোড়া', 450.00, 50),
('FOOT-017', N'কিডস আরামদায়ক কার্টুন স্যান্ডেল', N'জুতার দোকান', N'জোড়া', 220.00, 80),
('FOOT-018', N'কিউই ব্ল্যাক শু পলিশ ও ব্রাশ সেট', N'জুতার দোকান', N'সেট', 140.00, 100),
('FOOT-019', N'লেডিস ট্রাভেল স্নিকার্স শু', N'জুতার দোকান', N'জোড়া', 1100.00, 40),
('FOOT-020', N'মেনস বিচ স্লিপার ওয়াটারপ্রুফ', N'জুতার দোকান', N'জোড়া', 250.00, 90),

-- 6. কাঁচা বাজার (Fresh Produce) - 21 items
('BAZAR-001', N'দেশি নতুন গোল আলু ১ কেজি', N'কাঁচা বাজার', N'কেজি', 40.00, 300),
('BAZAR-002', N'দেশি পেঁয়াজ ১ কেজি', N'কাঁচা বাজার', N'কেজি', 75.00, 250),
('BAZAR-003', N'দেশি রসুন ২৫০ গ্রাম', N'কাঁচা বাজার', N'প্যাকেট', 55.00, 150),
('BAZAR-004', N'তাজা আদা ২৫০ গ্রাম', N'কাঁচা বাজার', N'প্যাকেট', 60.00, 150),
('BAZAR-005', N'তাজা কাঁচা মরিচ ২৫০ গ্রাম', N'কাঁচা বাজার', N'প্যাকেট', 35.00, 150),
('BAZAR-006', N'পাকা লাল টমেটো ১ কেজি', N'কাঁচা বাজার', N'কেজি', 50.00, 200),
('BAZAR-007', N'দেশি তাজা শসা ১ কেজি', N'কাঁচা বাজার', N'কেজি', 45.00, 150),
('BAZAR-008', N'গোল বেগুন ১ কেজি', N'কাঁচা বাজার', N'কেজি', 60.00, 150),
('BAZAR-009', N'তাজা গাজর ৫০০ গ্রাম', N'কাঁচা বাজার', N'প্যাকেট', 35.00, 150),
('BAZAR-010', N'তাজা ফুলকপি ১ পিস', N'কাঁচা বাজার', N'পিস', 40.00, 100),
('BAZAR-011', N'তাজা বাঁধাকপি ১ পিস', N'কাঁচা বাজার', N'পিস', 35.00, 100),
('BAZAR-012', N'মিষ্টি কুমড়া ১ ফালি (১ কেজি)', N'কাঁচা বাজার', N'কেজি', 45.00, 100),
('BAZAR-013', N'কাঁচা কলা ৪ পিস (১ হালি)', N'কাঁচা বাজার', N'হালি', 30.00, 120),
('BAZAR-014', N'কাগজি লেবু ৪ পিস (১ হালি)', N'কাঁচা বাজার', N'হালি', 25.00, 150),
('BAZAR-015', N'তাজা নদীর রুই মাছ ১ কেজি (কাটা)', N'কাঁচা বাজার', N'কেজি', 380.00, 50),
('BAZAR-016', N'পাঙ্গাশ মাছ ১ কেজি (পরিষ্কার)', N'কাঁচা বাজার', N'কেজি', 190.00, 60),
('BAZAR-017', N'দেশি জ্যান্ত তেলাপিয়া ১ কেজি', N'কাঁচা বাজার', N'কেজি', 220.00, 50),
('BAZAR-018', N'ফার্মের ব্রয়লার মুরগি ১ কেজি (কাটা)', N'কাঁচা বাজার', N'কেজি', 195.00, 100),
('BAZAR-019', N'দেশি সোনালী মুরগি ১ কেজি (কাটা)', N'কাঁচা বাজার', N'কেজি', 320.00, 80),
('BAZAR-020', N'গরুর মাংস ১ কেজি (তাজা হাড়সহ)', N'কাঁচা বাজার', N'কেজি', 750.00, 50),
('BAZAR-021', N'খাসির মাংস ১ কেজি (তাজা)', N'কাঁচা বাজার', N'কেজি', 1100.00, 30),

-- 7. ইলেকট্রনিক্স শপ (Electronics) - 20 items
('ELEC-001', N'Walton LED Bulb 15W Daylight', N'ইলেকট্রনিক্স শপ', N'পিস', 250.00, 100),
('ELEC-002', N'Super Star LED Bulb 20W', N'ইলেকট্রনিক্স শপ', N'পিস', 300.00, 100),
('ELEC-003', N'Energypac Tube Light 20W LED', N'ইলেকট্রনিক্স শপ', N'পিস', 180.00, 150),
('ELEC-004', N'Walton Ceiling Fan 56" High Speed', N'ইলেকট্রনিক্স শপ', N'পিস', 2850.00, 30),
('ELEC-005', N'BRB Ceiling Fan 56" Energy Saving', N'ইলেকট্রনিক্স শপ', N'পিস', 3250.00, 25),
('ELEC-006', N'Super Star 4-Port Multiplug with Switch', N'ইলেকট্রনিক্স শপ', N'পিস', 450.00, 80),
('ELEC-007', N'Walton 5-Port Multiplug Spike Guard', N'ইলেকট্রনিক্স শপ', N'পিস', 550.00, 60),
('ELEC-008', N'TP-Link Archer C6 AC1200 Gigabit Router', N'ইলেকট্রনিক্স শপ', N'পিস', 2850.00, 20),
('ELEC-009', N'Tenda F3 300Mbps Wireless Router', N'ইলেকট্রনিক্স শপ', N'পিস', 1280.00, 30),
('ELEC-010', N'Vision Automatic Dry Iron 1000W', N'ইলেকট্রনিক্স শপ', N'পিস', 1250.00, 25),
('ELEC-011', N'Miyako Blender 3 in 1 (750W)', N'ইলেকট্রনিক্স শপ', N'পিস', 3600.00, 15),
('ELEC-012', N'Singer Non-Stick Rice Cooker 2.8L', N'ইলেকট্রনিক্স শপ', N'পিস', 2950.00, 20),
('ELEC-013', N'Walton Cordless Electric Kettle 1.8L', N'ইলেকট্রনিক্স শপ', N'পিস', 950.00, 40),
('ELEC-014', N'Walton PTC Room Heater 1500W', N'ইলেকট্রনিক্স শপ', N'পিস', 2450.00, 15),
('ELEC-015', N'Super Star LED Emergency Light', N'ইলেকট্রনিক্স শপ', N'পিস', 850.00, 40),
('ELEC-016', N'Havells Exhaust Fan 8 Inch', N'ইলেকট্রনিক্স শপ', N'পিস', 1450.00, 20),
('ELEC-017', N'Philips 1000W Hair Dryer Compact', N'ইলেকট্রনিক্স শপ', N'পিস', 1650.00, 25),
('ELEC-018', N'Kemei Rechargeable Hair Trimmer KM-6330', N'ইলেকট্রনিক্স শপ', N'পিস', 650.00, 50),
('ELEC-019', N'Transtec Table Fan 16 Inch', N'ইলেকট্রনিক্স শপ', N'পিস', 2150.00, 20),
('ELEC-020', N'Singer 2-Slice Pop Up Toaster', N'ইলেকট্রনিক্স শপ', N'পিস', 1750.00, 20),

-- 8. মোবাইল ফোনের দোকান (Mobile Phones & Gadgets) - 20 items
('MOBI-001', N'Samsung Galaxy A05 (4GB/64GB Official)', N'মোবাইল ফোনের দোকান', N'পিস', 13499.00, 10),
('MOBI-002', N'Xiaomi Redmi 13C (6GB/128GB Official)', N'মোবাইল ফোনের দোকান', N'পিস', 14999.00, 10),
('MOBI-003', N'Realme Note 50 (4GB/64GB Official)', N'মোবাইল ফোনের দোকান', N'পিস', 10999.00, 12),
('MOBI-004', N'Vivo Y18 (6GB/128GB Official)', N'মোবাইল ফোনের দোকান', N'পিস', 15999.00, 8),
('MOBI-005', N'Walton Primo HM7 (4GB/64GB)', N'মোবাইল ফোনের দোকান', N'পিস', 8990.00, 15),
('MOBI-006', N'20W PD Type-C Fast Mobile Charger', N'মোবাইল ফোনের দোকান', N'পিস', 450.00, 80),
('MOBI-007', N'Micro USB 2.4A Standard Mobile Charger', N'মোবাইল ফোনের দোকান', N'পিস', 250.00, 100),
('MOBI-008', N'Baseus 60W Type-C to Type-C Braided Cable', N'মোবাইল ফোনের দোকান', N'পিস', 350.00, 80),
('MOBI-009', N'Havit USB to Lightning Cable for iPhone', N'মোবাইল ফোনের দোকান', N'পিস', 280.00, 80),
('MOBI-010', N'Samsung Original 3.5mm Earphones IG935', N'মোবাইল ফোনের দোকান', N'পিস', 380.00, 100),
('MOBI-011', N'Awei T13 Pro TWS Bluetooth Earbuds', N'মোবাইল ফোনের দোকান', N'পিস', 1250.00, 40),
('MOBI-012', N'Haylou Solar Plus RT3 AMOLED Smartwatch', N'মোবাইল ফোনের দোকান', N'পিস', 3450.00, 20),
('MOBI-013', N'Remax 10000mAh Dual USB Power Bank', N'মোবাইল ফোনের দোকান', N'পিস', 1150.00, 30),
('MOBI-014', N'Xiaomi Redmi 20000mAh 18W Fast Power Bank', N'মোবাইল ফোনের দোকান', N'পিস', 2150.00, 25),
('MOBI-015', N'SanDisk Ultra 64GB MicroSD Card Class 10', N'মোবাইল ফোনের দোকান', N'পিস', 550.00, 60),
('MOBI-016', N'SanDisk Ultra 128GB MicroSD Card', N'মোবাইল ফোনের দোকান', N'পিস', 950.00, 40),
('MOBI-017', N'SanDisk Ultra Dual Drive 64GB Type-C OTG', N'মোবাইল ফোনের দোকান', N'পিস', 750.00, 50),
('MOBI-018', N'Universal Adjustable Mobile Desk Stand Holder', N'মোবাইল ফোনের দোকান', N'পিস', 180.00, 100),
('MOBI-019', N'9D Tempered Glass Screen Protector (All Model)', N'মোবাইল ফোনের দোকান', N'পিস', 100.00, 200),
('MOBI-020', N'Transparent Shockproof Silicon Phone Case', N'মোবাইল ফোনের দোকান', N'পিস', 120.00, 150);

-- Insert into tbl_CompanyProducts
MERGE dbo.tbl_CompanyProducts AS Target
USING #TempProducts AS Source
ON (Target.ProductCode = Source.ProductCode)
WHEN MATCHED THEN
    UPDATE SET 
        Target.Name = Source.Name,
        Target.Category = Source.Category,
        Target.Uom = Source.Uom,
        Target.UnitPrice = Source.UnitPrice,
        Target.IsActive = 1
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ProductCode, Name, Category, Uom, UnitPrice, OpeningStock, ShopkeeperPercentage, CompanyPercentage, AgentPercentage, FieldForcePercentage, CustomerPercentage, CreatedByUserId, IsActive)
    VALUES (Source.ProductCode, Source.Name, Source.Category, Source.Uom, Source.UnitPrice, Source.OpeningStock, 10.0, 5.0, 0, 0, 0, @CompanyUserId, 1);

-- Also synchronize with tbl_CustomerOrderProducts
MERGE dbo.tbl_CustomerOrderProducts AS Target
USING #TempProducts AS Source
ON (Target.Sku = Source.ProductCode)
WHEN MATCHED THEN
    UPDATE SET 
        Target.Name = Source.Name,
        Target.Category = Source.Category,
        Target.UnitPrice = Source.UnitPrice,
        Target.IsActive = 1
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Name, Sku, Category, UnitPrice, IsActive)
    VALUES (Source.Name, Source.ProductCode, Source.Category, Source.UnitPrice, 1);

DROP TABLE #TempProducts;
