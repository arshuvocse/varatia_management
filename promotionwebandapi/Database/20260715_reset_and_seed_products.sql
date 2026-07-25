SET NOCOUNT ON;
SET XACT_ABORT ON;

IF COL_LENGTH(N'dbo.tbl_CustomerOrderProducts', N'ImageUrl') IS NULL
    ALTER TABLE dbo.tbl_CustomerOrderProducts ADD ImageUrl NVARCHAR(500) NULL;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @CompanyUserId INT = (
        SELECT TOP (1) Id
        FROM dbo.tbl_Users
        WHERE Role = N'Company' AND IsActive = 1
        ORDER BY Id
    );

    IF @CompanyUserId IS NULL
        THROW 51200, N'An active company user is required to seed products.', 1;

    DECLARE @ReferencedProductIds TABLE (Id INT PRIMARY KEY);
    INSERT INTO @ReferencedProductIds (Id)
    SELECT DISTINCT ProductId FROM dbo.tbl_SaleDetails;

    DECLARE @ReferencedCatalogIds TABLE (Id INT PRIMARY KEY);
    INSERT INTO @ReferencedCatalogIds (Id)
    SELECT DISTINCT ProductId FROM dbo.tbl_CustomerOrderDetails;

    DECLARE @ReferencedCodes TABLE (ProductCode NVARCHAR(50) PRIMARY KEY);
    INSERT INTO @ReferencedCodes (ProductCode)
    SELECT DISTINCT p.Sku
    FROM dbo.tbl_Products p
    INNER JOIN @ReferencedProductIds r ON r.Id = p.Id
    WHERE NULLIF(LTRIM(RTRIM(p.Sku)), N'') IS NOT NULL
    UNION
    SELECT DISTINCT p.Sku
    FROM dbo.tbl_CustomerOrderProducts p
    INNER JOIN @ReferencedCatalogIds r ON r.Id = p.Id
    WHERE NULLIF(LTRIM(RTRIM(p.Sku)), N'') IS NOT NULL;

    IF OBJECT_ID(N'dbo.tbl_ShopkeeperProductSelections', N'U') IS NOT NULL
        EXEC sys.sp_executesql N'DELETE FROM dbo.tbl_ShopkeeperProductSelections;';

    -- Preserve only rows required by sale/order history, but hide all old products.
    UPDATE p SET IsActive = 0
    FROM dbo.tbl_Products p
    INNER JOIN @ReferencedProductIds r ON r.Id = p.Id;

    DELETE p
    FROM dbo.tbl_Products p
    WHERE NOT EXISTS (SELECT 1 FROM @ReferencedProductIds r WHERE r.Id = p.Id);

    UPDATE p SET IsActive = 0
    FROM dbo.tbl_CustomerOrderProducts p
    INNER JOIN @ReferencedCatalogIds r ON r.Id = p.Id;

    DELETE p
    FROM dbo.tbl_CustomerOrderProducts p
    WHERE NOT EXISTS (SELECT 1 FROM @ReferencedCatalogIds r WHERE r.Id = p.Id);

    UPDATE p SET IsActive = 0
    FROM dbo.tbl_CompanyProducts p
    WHERE EXISTS (SELECT 1 FROM @ReferencedCodes r WHERE r.ProductCode = p.ProductCode);

    DELETE p
    FROM dbo.tbl_CompanyProducts p
    WHERE NOT EXISTS (SELECT 1 FROM @ReferencedCodes r WHERE r.ProductCode = p.ProductCode);

    DECLARE @ProductsJson NVARCHAR(MAX) = N'[
      {"category":"মুদির দোকান","prefix":"GRO","basePrice":55,"image":"https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=900&q=80","names":["মিনিকেট চাল ৫ কেজি","নাজিরশাইল চাল ৫ কেজি","বাসমতি চাল ১ কেজি","আতপ চাল ৫ কেজি","মোটা চাল ৫ কেজি","মসুর ডাল ১ কেজি","মুগ ডাল ১ কেজি","ছোলার ডাল ১ কেজি","বুট ১ কেজি","মটর ডাল ১ কেজি","সয়াবিন তেল ১ লিটার","সয়াবিন তেল ৫ লিটার","সরিষার তেল ১ লিটার","আটা ২ কেজি","ময়দা ১ কেজি","সুজি ৫০০ গ্রাম","চিনি ১ কেজি","লবণ ১ কেজি","গুঁড়া দুধ ৫০০ গ্রাম","তরল দুধ ১ লিটার","ডিম ১২টি","পাউরুটি বড়","টোস্ট বিস্কুট ৩০০ গ্রাম","ক্রিম বিস্কুট ২০০ গ্রাম","নুডলস ৮ প্যাক","সেমাই ৫০০ গ্রাম","মুড়ি ৫০০ গ্রাম","চিঁড়া ১ কেজি","চানাচুর ৫০০ গ্রাম","আলুর চিপস বড়","চা পাতা ৪০০ গ্রাম","কফি ২০০ গ্রাম","হলুদ গুঁড়া ২০০ গ্রাম","মরিচ গুঁড়া ২০০ গ্রাম","ধনিয়া গুঁড়া ২০০ গ্রাম","জিরা গুঁড়া ১০০ গ্রাম","গরম মসলা ১০০ গ্রাম","আদা বাটা ২০০ গ্রাম","রসুন বাটা ২০০ গ্রাম","টমেটো সস ৫০০ গ্রাম","সয়া সস ৩০০ মিলি","ভিনেগার ৩০০ মিলি","মেয়োনিজ ৫০০ মিলি","জ্যাম ৫০০ গ্রাম","মধু ২৫০ গ্রাম","খেজুর ৫০০ গ্রাম","ছোলা ভাজা ৫০০ গ্রাম","টিস্যু বক্স","ডিশওয়াশ লিকুইড ৫০০ মিলি","লন্ড্রি ডিটারজেন্ট ১ কেজি"]},
      {"category":"ফার্মেসি","prefix":"PHA","basePrice":30,"image":"https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=900&q=80","names":["প্যারাসিটামল ৫০০ মিগ্রা ১০ ট্যাবলেট","প্যারাসিটামল সিরাপ ৬০ মিলি","ওআরএস ১০ প্যাক","অ্যান্টাসিড ২০ ট্যাবলেট","অ্যান্টাসিড সাসপেনশন ২০০ মিলি","ভিটামিন সি ১০ ট্যাবলেট","মাল্টিভিটামিন ৩০ ট্যাবলেট","ক্যালসিয়াম ও ভিটামিন ডি ৩০ ট্যাবলেট","জিংক ২০ মিগ্রা ১০ ট্যাবলেট","আয়রন সাপ্লিমেন্ট ৩০ ট্যাবলেট","ব্যান্ডেজ রোল ৩ ইঞ্চি","স্টেরাইল গজ ১০ পিস","কটন রোল ১০০ গ্রাম","অ্যাডহেসিভ ব্যান্ডেজ ২০ পিস","অ্যান্টিসেপটিক লিকুইড ১০০ মিলি","হ্যান্ড স্যানিটাইজার ২০০ মিলি","ডিজিটাল থার্মোমিটার","ব্লাড প্রেসার মনিটর","গ্লুকোমিটার সেট","গ্লুকোজ টেস্ট স্ট্রিপ ২৫ পিস","ডিসপোজেবল মাস্ক ৫০ পিস","এন৯৫ মাস্ক","হ্যান্ড গ্লাভস ১০০ পিস","হট ওয়াটার ব্যাগ","নেবুলাইজার মেশিন","স্যালাইন ন্যাজাল ড্রপ ১০ মিলি","কাশির সিরাপ ১০০ মিলি","অ্যালার্জি রিলিফ ১০ ট্যাবলেট","ব্যথা উপশম বাম ২৫ গ্রাম","পেইন রিলিফ স্প্রে ১০০ মিলি","অ্যান্টিফাঙ্গাল ক্রিম ১৫ গ্রাম","অ্যান্টিসেপটিক ক্রিম ২০ গ্রাম","ক্যালামাইন লোশন ১০০ মিলি","পেট্রোলিয়াম জেলি ৫০ গ্রাম","বেবি ডায়াপার ছোট ২০ পিস","বেবি ডায়াপার মাঝারি ২০ পিস","অ্যাডাল্ট ডায়াপার মাঝারি ১০ পিস","স্যানিটারি ন্যাপকিন ১৬ পিস","প্রেগন্যান্সি টেস্ট কিট","মেডিকেল টেপ ১ ইঞ্চি","ইলাস্টিক নি ক্যাপ","অ্যাঙ্কেল সাপোর্ট","ল্যাম্বার সাপোর্ট বেল্ট","সার্জিক্যাল কাঁচি","মেডিসিন বক্স","আই ড্রপ লুব্রিকেন্ট ১০ মিলি","ইয়ার প্লাগ এক জোড়া","ইনহেলার স্পেসার","ফার্স্ট এইড কিট","পালস অক্সিমিটার"]},
      {"category":"কসমেটিকস","prefix":"COS","basePrice":120,"image":"https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=900&q=80","names":["ফেসওয়াশ ১০০ মিলি","ময়েশ্চারাইজার ১০০ মিলি","সানস্ক্রিন এসপিএফ ৫০","ফেস সিরাম ৩০ মিলি","মাইসেলার ওয়াটার ২০০ মিলি","ফেস টোনার ১৫০ মিলি","ক্লিনজিং মিল্ক ১৫০ মিলি","ফেস স্ক্রাব ১০০ গ্রাম","ফেস মাস্ক ১০০ গ্রাম","অ্যালোভেরা জেল ২০০ মিলি","বডি লোশন ২০০ মিলি","বডি ওয়াশ ২৫০ মিলি","বডি স্ক্রাব ২০০ গ্রাম","হ্যান্ড ক্রিম ৫০ মিলি","ফুট ক্রিম ৫০ মিলি","শ্যাম্পু ৩৫০ মিলি","কন্ডিশনার ৩০০ মিলি","হেয়ার অয়েল ২০০ মিলি","হেয়ার সিরাম ১০০ মিলি","হেয়ার মাস্ক ২০০ গ্রাম","হেয়ার কালার কালো","হেয়ার কালার বাদামি","লিপ বাম","লিপস্টিক ম্যাট","লিপ গ্লস","লিপ লাইনার","ফাউন্ডেশন ৩০ মিলি","কনসিলার","কমপ্যাক্ট পাউডার","লুজ পাউডার","বিবি ক্রিম ৩০ মিলি","ব্লাশ প্যালেট","হাইলাইটার প্যালেট","আইশ্যাডো প্যালেট","আইলাইনার","কাজল","মাসকারা","আইব্রো পেন্সিল","মেকআপ ব্রাশ সেট","বিউটি ব্লেন্ডার","নেইল পলিশ","নেইল পলিশ রিমুভার","পারফিউম ১০০ মিলি","বডি স্প্রে ২০০ মিলি","ডিওডোরেন্ট রোল অন","শেভিং ফোম ২০০ মিলি","আফটার শেভ লোশন","রেজর সেট","ফেসিয়াল টিস্যু","কসমেটিক অর্গানাইজার"]},
      {"category":"ইলেকট্রনিক্স","prefix":"ELE","basePrice":180,"image":"https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=900&q=80","names":["এলইডি বাল্ব ৯ ওয়াট","এলইডি বাল্ব ১২ ওয়াট","এলইডি টিউব লাইট ২০ ওয়াট","রিচার্জেবল ইমার্জেন্সি লাইট","টেবিল ল্যাম্প","সিলিং ফ্যান ৪৮ ইঞ্চি","টেবিল ফ্যান ১২ ইঞ্চি","এক্সহস্ট ফ্যান ৮ ইঞ্চি","ইলেকট্রিক কেটলি ১.৮ লিটার","রাইস কুকার ১.৮ লিটার","ইনডাকশন কুকার","ব্লেন্ডার ৩ ইন ১","ইলেকট্রিক আয়রন","হেয়ার ড্রায়ার","হেয়ার স্ট্রেইটনার","ডিজিটাল ওয়েট স্কেল","এক্সটেনশন বোর্ড ৪ সকেট","মাল্টিপ্লাগ অ্যাডাপ্টার","ইউএসবি চার্জার ২০ ওয়াট","ফাস্ট চার্জার ৩৩ ওয়াট","টাইপ-সি কেবল ১ মিটার","মাইক্রো ইউএসবি কেবল ১ মিটার","লাইটনিং কেবল ১ মিটার","পাওয়ার ব্যাংক ১০০০০ এমএএইচ","ওয়্যারলেস ইয়ারবাড","ব্লুটুথ হেডফোন","ওয়্যার্ড ইয়ারফোন","ব্লুটুথ স্পিকার","পোর্টেবল এফএম রেডিও","স্মার্ট ওয়াচ","ফিটনেস ব্যান্ড","ওয়্যারলেস মাউস","ইউএসবি কিবোর্ড","কিবোর্ড মাউস কম্বো","ইউএসবি হাব ৪ পোর্ট","মেমোরি কার্ড ৩২ জিবি","পেনড্রাইভ ৬৪ জিবি","ওয়াইফাই রাউটার","ল্যান কেবল ৫ মিটার","এইচডিএমআই কেবল ২ মিটার","ইউনিভার্সাল টিভি রিমোট","ডিজিটাল সেট টপ বক্স","সিসিটিভি ক্যামেরা","স্মার্ট ডোর বেল","ইলেকট্রিক মশা মারার ব্যাট","রিচার্জেবল টর্চ লাইট","ডিজিটাল অ্যালার্ম ঘড়ি","ক্যালকুলেটর","এএ ব্যাটারি ৪ পিস","ভোল্টেজ স্ট্যাবিলাইজার"]}
    ]';

    DECLARE @Seed TABLE (
        ProductCode NVARCHAR(50) PRIMARY KEY,
        Name NVARCHAR(150) NOT NULL,
        Category NVARCHAR(100) NOT NULL,
        Uom NVARCHAR(30) NOT NULL,
        UnitPrice DECIMAL(18,2) NOT NULL,
        OpeningStock INT NOT NULL,
        ImageUrl NVARCHAR(500) NOT NULL
    );

    INSERT INTO @Seed (ProductCode, Name, Category, Uom, UnitPrice, OpeningStock, ImageUrl)
    SELECT
        CONCAT(N'SB260715-', category.prefix, N'-', RIGHT(N'000' + CONVERT(NVARCHAR(3), CONVERT(INT, product.[key]) + 1), 3)),
        CONVERT(NVARCHAR(150), product.value),
        category.category,
        CASE
            WHEN category.prefix = N'PHA' THEN N'pack'
            WHEN category.prefix = N'ELE' THEN N'pcs'
            ELSE N'unit'
        END,
        CONVERT(DECIMAL(18,2), category.basePrice + (CONVERT(INT, product.[key]) * CASE category.prefix WHEN N'ELE' THEN 35 WHEN N'COS' THEN 12 ELSE 7 END)),
        100 + (CONVERT(INT, product.[key]) % 5) * 25,
        CONCAT(category.image, N'&sig=', category.prefix, CONVERT(INT, product.[key]) + 1)
    FROM OPENJSON(@ProductsJson)
    WITH (
        category NVARCHAR(100) N'$.category',
        prefix NVARCHAR(10) N'$.prefix',
        basePrice DECIMAL(18,2) N'$.basePrice',
        image NVARCHAR(450) N'$.image',
        names NVARCHAR(MAX) N'$.names' AS JSON
    ) category
    CROSS APPLY OPENJSON(category.names) product;

    IF (SELECT COUNT(*) FROM @Seed) <> 200
        THROW 51201, N'The product seed must contain exactly 200 rows.', 1;

    IF EXISTS (
        SELECT 1 FROM @Seed GROUP BY Category HAVING COUNT(*) <> 50
    ) OR (SELECT COUNT(DISTINCT Category) FROM @Seed) <> 4
        THROW 51202, N'Every shop category must contain exactly 50 products.', 1;

    INSERT INTO dbo.tbl_CompanyProducts
        (ProductCode, Name, Category, Uom, UnitPrice, OpeningStock,
         CompanyPercentage, AgentPercentage, FieldForcePercentage,
         CustomerPercentage, CreatedByUserId, IsActive, ImageUrl)
    SELECT ProductCode, Name, Category, Uom, UnitPrice, OpeningStock,
           0, 0, 0, 0, @CompanyUserId, 1, ImageUrl
    FROM @Seed;

    INSERT INTO dbo.tbl_CustomerOrderProducts
        (Name, Sku, Category, UnitPrice, IsActive, ImageUrl)
    SELECT Name, ProductCode, Category, UnitPrice, 1, ImageUrl
    FROM @Seed;

    INSERT INTO dbo.tbl_Products
        (ShopkeeperId, Name, Sku, Category, UnitPrice, StockQuantity,
         CommissionPercentage, IsActive, ImageUrl)
    SELECT shop.Id, seed.Name, seed.ProductCode, seed.Category,
           seed.UnitPrice, seed.OpeningStock, 3.0, 1, seed.ImageUrl
    FROM dbo.tbl_Shopkeepers shop
    INNER JOIN @Seed seed ON seed.Category = shop.ShopType;

    COMMIT TRANSACTION;

    SELECT Category, COUNT(*) AS ActiveCompanyProducts,
           SUM(CASE WHEN ImageUrl IS NOT NULL THEN 1 ELSE 0 END) AS ProductsWithImage
    FROM dbo.tbl_CompanyProducts
    WHERE IsActive = 1
    GROUP BY Category
    ORDER BY Category;

    SELECT shop.Id AS ShopkeeperId, shop.ShopName, shop.ShopType,
           COUNT(product.Id) AS ActiveProducts,
           SUM(CASE WHEN product.ImageUrl IS NOT NULL THEN 1 ELSE 0 END) AS ProductsWithImage
    FROM dbo.tbl_Shopkeepers shop
    LEFT JOIN dbo.tbl_Products product
        ON product.ShopkeeperId = shop.Id AND product.IsActive = 1
    GROUP BY shop.Id, shop.ShopName, shop.ShopType
    ORDER BY shop.Id;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
