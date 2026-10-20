using Microsoft.Data.SqlClient;
using PromotionWeb.Models;
using System.Data;

namespace PromotionWeb.Services;

public sealed class CustomerOrderStore(
    IConfiguration configuration,
    ProductDistributionStore distributionStore,
    ShopkeeperWalletCreditService walletCreditService)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");

    private static (DateTime expiresAt, IReadOnlyList<ShopCategoryViewModel> items)? _categoryCache;
    private static (DateTime expiresAt, Dictionary<int, CustomerProductCatalogBuilder> items)? _rawCatalogCache;
    private static (DateTime expiresAt, Dictionary<string, DistrictPricingDetailViewModel> items)? _pricingCache;
    private static readonly object _cacheLock = new();
    private static readonly object SchemaLock = new();
    private static bool _schemaReady;

    /// <summary>
    /// Persists the district-based final price (base + district adjustment + company margin + shopkeeper
    /// margin) and the delivery/service/platform charge breakdown on every order, and widens
    /// dbo.CustomerOrderDetailInput so sp_CustomerOrder_Create stores exactly the price this store already
    /// computed in GetProducts() instead of re-reading the raw (un-marked-up) catalog price. Also adds
    /// customer Latitude/Longitude for nearby-shop lookups without a query-string round trip.
    /// </summary>
    public void EnsureSchema()
    {
        if (_schemaReady) return;
        lock (SchemaLock)
        {
            if (_schemaReady) return;
            using var connection = CreateConnection();
            connection.Open();

            // DDL/CREATE PROCEDURE statements can legitimately take longer than the default 30s command
            // timeout on first run against a remote server (observed: first-ever migration timed out and
            // 500'd /Customer/Shops). Give this one-time schema setup more headroom.
            ExecuteDdl(connection, """
                IF COL_LENGTH(N'dbo.tbl_CustomerOrders', N'DistrictName') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrders ADD DistrictName NVARCHAR(100) NULL;
                IF COL_LENGTH(N'dbo.tbl_CustomerOrders', N'DeliveryCharge') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrders ADD DeliveryCharge DECIMAL(18,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrders_DeliveryCharge DEFAULT (0);
                IF COL_LENGTH(N'dbo.tbl_CustomerOrders', N'ServiceCharge') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrders ADD ServiceCharge DECIMAL(18,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrders_ServiceCharge DEFAULT (0);
                IF COL_LENGTH(N'dbo.tbl_CustomerOrders', N'PlatformCharge') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrders ADD PlatformCharge DECIMAL(18,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrders_PlatformCharge DEFAULT (0);
                IF COL_LENGTH(N'dbo.tbl_CustomerOrders', N'DeliveryType') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrders ADD DeliveryType NVARCHAR(50) NULL;
                IF COL_LENGTH(N'dbo.tbl_CustomerOrders', N'CompanyMarginAmount') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrders ADD CompanyMarginAmount DECIMAL(18,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrders_CompanyMarginAmount DEFAULT (0);
                IF COL_LENGTH(N'dbo.tbl_CustomerOrders', N'ShopkeeperMarginAmount') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrders ADD ShopkeeperMarginAmount DECIMAL(18,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrders_ShopkeeperMarginAmount DEFAULT (0);

                IF COL_LENGTH(N'dbo.tbl_CustomerOrderDetails', N'BasePrice') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrderDetails ADD BasePrice DECIMAL(18,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrderDetails_BasePrice DEFAULT (0);
                IF COL_LENGTH(N'dbo.tbl_CustomerOrderDetails', N'DistrictAdjustment') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrderDetails ADD DistrictAdjustment DECIMAL(18,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrderDetails_DistrictAdjustment DEFAULT (0);
                IF COL_LENGTH(N'dbo.tbl_CustomerOrderDetails', N'CompanyMargin') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrderDetails ADD CompanyMargin DECIMAL(18,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrderDetails_CompanyMargin DEFAULT (0);
                IF COL_LENGTH(N'dbo.tbl_CustomerOrderDetails', N'ShopkeeperMargin') IS NULL
                    ALTER TABLE dbo.tbl_CustomerOrderDetails ADD ShopkeeperMargin DECIMAL(18,2) NOT NULL
                        CONSTRAINT DF_tbl_CustomerOrderDetails_ShopkeeperMargin DEFAULT (0);

                IF COL_LENGTH(N'dbo.tbl_Customers', N'Latitude') IS NULL
                    ALTER TABLE dbo.tbl_Customers ADD Latitude DECIMAL(9,6) NULL;
                IF COL_LENGTH(N'dbo.tbl_Customers', N'Longitude') IS NULL
                    ALTER TABLE dbo.tbl_Customers ADD Longitude DECIMAL(9,6) NULL;
                IF COL_LENGTH(N'dbo.tbl_Customers', N'LocationUpdatedAt') IS NULL
                    ALTER TABLE dbo.tbl_Customers ADD LocationUpdatedAt DATETIME2(0) NULL;
                """);

            bool typeNeedsRebuild;
            using (var command = new SqlCommand("""
                SELECT CASE WHEN EXISTS (
                    SELECT 1 FROM sys.table_types tt
                    INNER JOIN sys.columns c ON c.object_id = tt.type_table_object_id
                    WHERE tt.name = N'CustomerOrderDetailInput' AND c.name = N'BasePrice'
                ) THEN 1 ELSE 0 END;
                """, connection) { CommandTimeout = DdlTimeoutSeconds })
            {
                typeNeedsRebuild = Convert.ToInt32(command.ExecuteScalar()) == 0;
            }

            if (typeNeedsRebuild)
            {
                ExecuteDdl(connection,
                    "IF OBJECT_ID(N'dbo.sp_CustomerOrder_Create', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_CustomerOrder_Create;");
                ExecuteDdl(connection,
                    "IF TYPE_ID(N'dbo.CustomerOrderDetailInput') IS NOT NULL DROP TYPE dbo.CustomerOrderDetailInput;");
                ExecuteDdl(connection, """
                    CREATE TYPE dbo.CustomerOrderDetailInput AS TABLE
                    (
                        ProductId INT NOT NULL,
                        Quantity INT NOT NULL,
                        BasePrice DECIMAL(18,2) NOT NULL,
                        DistrictAdjustment DECIMAL(18,2) NOT NULL,
                        CompanyMargin DECIMAL(18,2) NOT NULL,
                        ShopkeeperMargin DECIMAL(18,2) NOT NULL
                    );
                    """);
            }

            ExecuteDdl(connection, """
                CREATE OR ALTER PROCEDURE dbo.sp_CustomerOrder_Create
                    @CustomerUserId INT,
                    @CustomerName NVARCHAR(150),
                    @CustomerPhone NVARCHAR(20),
                    @ShopkeeperId INT,
                    @CustomerLatitude DECIMAL(9,6) = NULL,
                    @CustomerLongitude DECIMAL(9,6) = NULL,
                    @DistrictName NVARCHAR(100) = NULL,
                    @DeliveryType NVARCHAR(50) = NULL,
                    @DeliveryCharge DECIMAL(18,2) = 0,
                    @ServiceCharge DECIMAL(18,2) = 0,
                    @PlatformCharge DECIMAL(18,2) = 0,
                    @Remarks NVARCHAR(500) = NULL,
                    @Items dbo.CustomerOrderDetailInput READONLY
                AS
                BEGIN
                    SET NOCOUNT ON;
                    SET XACT_ABORT ON;

                    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Users WHERE Id = @CustomerUserId AND Role = N'Customer' AND IsActive = 1)
                        THROW 51020, N'Invalid customer.', 1;

                    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Shopkeepers WHERE Id = @ShopkeeperId)
                        THROW 51021, N'Invalid shopkeeper.', 1;

                    IF NOT EXISTS (SELECT 1 FROM @Items)
                        THROW 51022, N'At least one product is required.', 1;

                    IF EXISTS (
                        SELECT 1
                        FROM @Items AS i
                        LEFT JOIN dbo.tbl_CustomerOrderProducts AS p ON p.Id = i.ProductId AND p.IsActive = 1
                        WHERE p.Id IS NULL OR i.Quantity <= 0
                    )
                        THROW 51023, N'Valid product selection is required.', 1;

                    DECLARE @OrderId INT;
                    DECLARE @TotalAmount DECIMAL(18,2);
                    DECLARE @DiscountAmount DECIMAL(18,2);
                    DECLARE @CompanyMarginAmount DECIMAL(18,2);
                    DECLARE @ShopkeeperMarginAmount DECIMAL(18,2);

                    -- Trust only server-computed unit economics for each line (BasePrice/DistrictAdjustment/
                    -- CompanyMargin/ShopkeeperMargin come from CustomerOrderStore.GetProducts(), the same
                    -- district-pricing formula used for display); the customer can never influence price here.
                    SELECT
                        @TotalAmount = SUM(i.Quantity * (i.BasePrice + i.DistrictAdjustment + i.CompanyMargin + i.ShopkeeperMargin)),
                        @CompanyMarginAmount = SUM(i.Quantity * i.CompanyMargin),
                        @ShopkeeperMarginAmount = SUM(i.Quantity * i.ShopkeeperMargin)
                    FROM @Items AS i;

                    SET @DiscountAmount = CASE WHEN @TotalAmount >= 1000 THEN ROUND(@TotalAmount * 0.03, 2) ELSE 0 END;

                    BEGIN TRANSACTION;

                    INSERT INTO dbo.tbl_CustomerOrders
                        (CustomerUserId, CustomerName, CustomerPhone, ShopkeeperId, CustomerLatitude, CustomerLongitude,
                         DistrictName, DeliveryType, DeliveryCharge, ServiceCharge, PlatformCharge,
                         CompanyMarginAmount, ShopkeeperMarginAmount,
                         TotalAmount, DiscountAmount, Status, Remarks)
                    VALUES
                        (@CustomerUserId, @CustomerName, @CustomerPhone, @ShopkeeperId, @CustomerLatitude, @CustomerLongitude,
                         @DistrictName, @DeliveryType, @DeliveryCharge, @ServiceCharge, @PlatformCharge,
                         @CompanyMarginAmount, @ShopkeeperMarginAmount,
                         @TotalAmount, @DiscountAmount, N'Pending', @Remarks);

                    SET @OrderId = SCOPE_IDENTITY();

                    INSERT INTO dbo.tbl_CustomerOrderDetails
                        (OrderMasterId, ProductId, ProductName, Sku, Quantity, UnitPrice,
                         BasePrice, DistrictAdjustment, CompanyMargin, ShopkeeperMargin)
                    SELECT
                        @OrderId,
                        p.Id,
                        p.Name,
                        p.Sku,
                        i.Quantity,
                        i.BasePrice + i.DistrictAdjustment + i.CompanyMargin + i.ShopkeeperMargin,
                        i.BasePrice, i.DistrictAdjustment, i.CompanyMargin, i.ShopkeeperMargin
                    FROM @Items AS i
                    INNER JOIN dbo.tbl_CustomerOrderProducts AS p ON p.Id = i.ProductId;

                    COMMIT TRANSACTION;

                    EXEC dbo.sp_CustomerOrder_ListByCustomer @CustomerUserId = @CustomerUserId, @OrderId = @OrderId;
                END
                """);

            ExecuteDdl(connection, """
                CREATE OR ALTER PROCEDURE dbo.sp_CustomerOrder_ListByCustomer
                    @CustomerUserId INT,
                    @OrderId INT = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        o.Id, o.CustomerUserId AS CustomerId, o.CustomerName, o.CustomerPhone,
                        o.ShopkeeperId, s.ShopName AS ShopkeeperName, o.OrderDate,
                        o.TotalAmount, o.DiscountAmount, o.Status, o.Remarks,
                        o.DistrictName, o.DeliveryType, o.DeliveryCharge, o.ServiceCharge, o.PlatformCharge
                    FROM dbo.tbl_CustomerOrders AS o
                    INNER JOIN dbo.tbl_Shopkeepers AS s ON s.Id = o.ShopkeeperId
                    WHERE o.CustomerUserId = @CustomerUserId
                      AND (@OrderId IS NULL OR o.Id = @OrderId)
                    ORDER BY o.OrderDate DESC, o.Id DESC;

                    SELECT
                        d.Id, d.OrderMasterId, d.ProductId, d.ProductName, d.Sku, d.Quantity, d.UnitPrice,
                        d.BasePrice, d.DistrictAdjustment, d.CompanyMargin, d.ShopkeeperMargin
                    FROM dbo.tbl_CustomerOrderDetails AS d
                    INNER JOIN dbo.tbl_CustomerOrders AS o ON o.Id = d.OrderMasterId
                    WHERE o.CustomerUserId = @CustomerUserId
                      AND (@OrderId IS NULL OR o.Id = @OrderId)
                    ORDER BY d.Id;
                END
                """);

            ExecuteDdl(connection, """
                CREATE OR ALTER PROCEDURE dbo.sp_CustomerOrder_ListByShopkeeper
                    @ShopkeeperId INT
                AS
                BEGIN
                    SET NOCOUNT ON;

                    SELECT
                        o.Id, o.CustomerUserId AS CustomerId, o.CustomerName, o.CustomerPhone,
                        o.ShopkeeperId, s.ShopName AS ShopkeeperName, o.OrderDate,
                        o.TotalAmount, o.DiscountAmount, o.Status, o.Remarks,
                        o.DistrictName, o.DeliveryType, o.DeliveryCharge, o.ServiceCharge, o.PlatformCharge
                    FROM dbo.tbl_CustomerOrders AS o
                    INNER JOIN dbo.tbl_Shopkeepers AS s ON s.Id = o.ShopkeeperId
                    WHERE o.ShopkeeperId = @ShopkeeperId
                    ORDER BY CASE WHEN o.Status = N'Pending' THEN 0 ELSE 1 END, o.OrderDate DESC, o.Id DESC;

                    SELECT
                        d.Id, d.OrderMasterId, d.ProductId, d.ProductName, d.Sku, d.Quantity, d.UnitPrice,
                        d.BasePrice, d.DistrictAdjustment, d.CompanyMargin, d.ShopkeeperMargin
                    FROM dbo.tbl_CustomerOrderDetails AS d
                    INNER JOIN dbo.tbl_CustomerOrders AS o ON o.Id = d.OrderMasterId
                    WHERE o.ShopkeeperId = @ShopkeeperId
                    ORDER BY d.Id;
                END
                """);

            _schemaReady = true;
        }
    }

    private const int DdlTimeoutSeconds = 120;

    private static void ExecuteDdl(SqlConnection connection, string sql)
    {
        using var command = new SqlCommand(sql, connection) { CommandTimeout = DdlTimeoutSeconds };
        command.ExecuteNonQuery();
    }

    public IReadOnlyList<ShopCategoryViewModel> GetCategories()
    {
        lock (_cacheLock)
        {
            if (_categoryCache is { } cached && DateTime.UtcNow < cached.expiresAt)
            {
                return cached.items;
            }
        }

        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_ShopCategories')
            BEGIN
                SELECT c.Id, c.Name, c.BanglaName, c.Icon, c.Description,
                       ProductCount = (SELECT COUNT(1) FROM dbo.tbl_CustomerOrderProducts p WHERE p.Category = c.Name AND p.IsActive = 1)
                FROM dbo.tbl_ShopCategories c
                WHERE c.IsActive = 1
                ORDER BY c.DisplayOrder, c.Id;
            END
            ELSE
            BEGIN
                SELECT 1 AS Id, N'মুদির দোকান' AS Name, N'মুদি দোকান' AS BanglaName, N'🛒' AS Icon, N'' AS Description, 25 AS ProductCount
                UNION ALL SELECT 2, N'কসমেটিক্স', N'কসমেটিক্স', N'💄', N'', 25
                UNION ALL SELECT 3, N'ফার্মেসি', N'ফার্মেসি', N'💊', N'', 25
                UNION ALL SELECT 4, N'জামা-কাপড়', N'পোশাক', N'👕', N'', 20
                UNION ALL SELECT 5, N'জুতার দোকান', N'জুতা ও স্যান্ডেল', N'👟', N'', 20
                UNION ALL SELECT 6, N'কাঁচা বাজার', N'কাঁচা বাজার', N'🥬', N'', 20
                UNION ALL SELECT 7, N'ইলেকট্রনিক্স শপ', N'ইলেকট্রনিক্স', N'⚡', N'', 20
                UNION ALL SELECT 8, N'মোবাইল ফোনের দোকান', N'মোবাইল ও গ্যাজেট', N'📱', N'', 20;
            END
            """, connection);

        connection.Open();
        using var reader = command.ExecuteReader();
        var list = new List<ShopCategoryViewModel>();
        while (reader.Read())
        {
            list.Add(new ShopCategoryViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                BanglaName = reader.GetString(reader.GetOrdinal("BanglaName")),
                Icon = reader.GetString(reader.GetOrdinal("Icon")),
                Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
                ProductCount = reader.GetInt32(reader.GetOrdinal("ProductCount"))
            });
        }

        lock (_cacheLock)
        {
            _categoryCache = (DateTime.UtcNow.AddMinutes(2), list);
        }

        return list;
    }

    public DistrictPricingDetailViewModel GetDistrictPricing(string? districtName)
    {
        if (string.IsNullOrWhiteSpace(districtName)) districtName = "Dhaka";
        var normalizedDistrict = districtName.Trim();

        lock (_cacheLock)
        {
            if (_pricingCache is { } cached && DateTime.UtcNow < cached.expiresAt && cached.items.TryGetValue(normalizedDistrict, out var cachedPricing))
            {
                return cachedPricing;
            }
        }

        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'tbl_DistrictPricingConfig')
            BEGIN
                SELECT TOP 1 DistrictName, TransportMultiplier, DistrictAdjustmentAmount,
                             DefaultDeliveryCharge, ServiceCharge, PlatformCharge,
                             ShopkeeperMarginPercent, CompanyMarginPercent
                FROM dbo.tbl_DistrictPricingConfig
                WHERE DistrictName = @DistrictName AND IsActive = 1;
            END
            """, connection);
        command.Parameters.AddWithValue("@DistrictName", normalizedDistrict);

        connection.Open();
        using var reader = command.ExecuteReader();
        DistrictPricingDetailViewModel result;
        if (reader.Read())
        {
            result = new DistrictPricingDetailViewModel
            {
                DistrictName = reader.GetString(0),
                TransportMultiplier = reader.GetDecimal(1),
                DistrictAdjustmentAmount = reader.GetDecimal(2),
                DefaultDeliveryCharge = reader.GetDecimal(3),
                ServiceCharge = reader.GetDecimal(4),
                PlatformCharge = reader.GetDecimal(5),
                ShopkeeperMarginPercent = reader.GetDecimal(6),
                CompanyMarginPercent = reader.GetDecimal(7)
            };
        }
        else
        {
            result = new DistrictPricingDetailViewModel
            {
                DistrictName = normalizedDistrict,
                TransportMultiplier = 1.0000m,
                DistrictAdjustmentAmount = 0.00m,
                DefaultDeliveryCharge = 35.00m,
                ServiceCharge = 10.00m,
                PlatformCharge = 5.00m,
                ShopkeeperMarginPercent = 10.00m,
                CompanyMarginPercent = 5.00m
            };
        }

        lock (_cacheLock)
        {
            var dict = _pricingCache?.items is not null
                ? new Dictionary<string, DistrictPricingDetailViewModel>(_pricingCache.Value.items, StringComparer.OrdinalIgnoreCase)
                : new Dictionary<string, DistrictPricingDetailViewModel>(StringComparer.OrdinalIgnoreCase);
            dict[normalizedDistrict] = result;
            _pricingCache = (DateTime.UtcNow.AddMinutes(5), dict);
        }

        return result;
    }

    public IReadOnlyList<CustomerProductOptionViewModel> GetProducts(string? districtName = null)
    {
        var pricingConfig = GetDistrictPricing(districtName);
        Dictionary<int, CustomerProductCatalogBuilder>? products = null;

        lock (_cacheLock)
        {
            if (_rawCatalogCache is { } cached && DateTime.UtcNow < cached.expiresAt)
            {
                products = cached.items;
            }
        }

        if (products is null)
        {
            distributionStore.SyncCustomerCatalog();

            using var connection = CreateConnection();
            using var command = new SqlCommand("""
                SELECT
                    catalog.Id,
                    catalog.Name,
                    catalog.Sku,
                    catalog.Category,
                    catalog.UnitPrice AS BasePrice,
                    inventory.ShopkeeperId,
                    COALESCE(
                        NULLIF(LTRIM(RTRIM(inventory.ImageUrl)), N''),
                        NULLIF(LTRIM(RTRIM(catalog.ImageUrl)), N''),
                        companyProduct.ImageUrl
                    ) AS ImageUrl,
                    companyProduct.Uom
                FROM dbo.tbl_CustomerOrderProducts AS catalog
                LEFT JOIN dbo.tbl_Products AS inventory
                    ON inventory.IsActive = 1
                   AND (
                        inventory.Sku = catalog.Sku
                        OR catalog.Sku = CONCAT(N'SP', inventory.ShopkeeperId, N'-', inventory.Sku)
                   )
                LEFT JOIN dbo.tbl_CompanyProducts AS companyProduct
                    ON companyProduct.ProductCode = catalog.Sku
                WHERE catalog.IsActive = 1
                ORDER BY catalog.Category, catalog.Name;
                """, connection);
            var loadedProducts = new Dictionary<int, CustomerProductCatalogBuilder>();

            connection.Open();
            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                var id = reader.GetInt32(reader.GetOrdinal("Id"));
                if (!loadedProducts.TryGetValue(id, out var product))
                {
                    var basePrice = reader.GetDecimal(reader.GetOrdinal("BasePrice"));
                    product = new CustomerProductCatalogBuilder
                    {
                        Id = id,
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        Sku = reader.GetString(reader.GetOrdinal("Sku")),
                        Category = reader.GetString(reader.GetOrdinal("Category")),
                        BasePrice = basePrice,
                        Uom = reader.IsDBNull(reader.GetOrdinal("Uom")) ? "পিস" : reader.GetString(reader.GetOrdinal("Uom"))
                    };
                    loadedProducts[id] = product;
                }

                if (!reader.IsDBNull(reader.GetOrdinal("ShopkeeperId")))
                {
                    product.ShopkeeperIds.Add(reader.GetInt32(reader.GetOrdinal("ShopkeeperId")));
                }
                if (string.IsNullOrWhiteSpace(product.ImageUrl)
                    && !reader.IsDBNull(reader.GetOrdinal("ImageUrl")))
                {
                    product.ImageUrl = reader.GetString(reader.GetOrdinal("ImageUrl"));
                }
            }

            lock (_cacheLock)
            {
                _rawCatalogCache = (DateTime.UtcNow.AddMinutes(2), loadedProducts);
            }
            products = loadedProducts;
        }

        var result = new List<CustomerProductOptionViewModel>();
        var index = 0;
        foreach (var p in products.Values)
        {
            // Automatic District-Based Pricing Calculation:
            // Base Price + District Adjustment + Company Margin + Shopkeeper Margin
            var basePrice = p.BasePrice;
            var districtAdj = pricingConfig.DistrictAdjustmentAmount > 0 
                ? pricingConfig.DistrictAdjustmentAmount 
                : Math.Round(basePrice * (pricingConfig.TransportMultiplier - 1.0m), 2);
            var compMargin = Math.Round(basePrice * (pricingConfig.CompanyMarginPercent / 100.0m), 2);
            var shopMargin = Math.Round(basePrice * (pricingConfig.ShopkeeperMarginPercent / 100.0m), 2);
            var finalUnitPrice = basePrice + districtAdj + compMargin + shopMargin;

            result.Add(new CustomerProductOptionViewModel
            {
                Id = p.Id,
                Name = p.Name,
                Sku = p.Sku,
                Category = p.Category,
                Uom = p.Uom,
                BasePrice = basePrice,
                DistrictAdjustment = districtAdj,
                CompanyMargin = compMargin,
                ShopkeeperMargin = shopMargin,
                UnitPrice = finalUnitPrice,
                ImageUrl = p.ImageUrl,
                DistrictName = pricingConfig.DistrictName,
                AvailableShopkeeperIds = p.ShopkeeperIds.OrderBy(id => id).ToArray(),
                IsPopular = (index % 3 == 0),
                IsRecommended = (index % 4 == 0)
            });
            index++;
        }

        return result;
    }

    public IReadOnlyList<CustomerShopkeeperOptionViewModel> GetNearbyShops(
        double? customerLat,
        double? customerLon,
        string? districtName = null,
        string? category = null)
    {
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_Shopkeeper_List");
        command.Parameters.AddWithValue("@FieldOfficerUserId", DBNull.Value);

        connection.Open();
        using var reader = command.ExecuteReader();
        var shops = new List<CustomerShopkeeperOptionViewModel>();

        while (reader.Read())
        {
            var district = reader.GetString(reader.GetOrdinal("DistrictName"));
            var shopType = reader.GetString(reader.GetOrdinal("ShopType"));

            if (!string.IsNullOrWhiteSpace(districtName) && !string.Equals(district, districtName.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            if (!string.IsNullOrWhiteSpace(category) && !shopType.Contains(category.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            var lat = reader.GetDecimal(reader.GetOrdinal("Latitude"));
            var lon = reader.GetDecimal(reader.GetOrdinal("Longitude"));

            double? distance = null;
            if (customerLat.HasValue && customerLon.HasValue)
            {
                distance = LoanStore.CalculateDistanceKm(customerLat.Value, customerLon.Value, (double)lat, (double)lon);
            }

            shops.Add(new CustomerShopkeeperOptionViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
                OwnerName = reader.GetString(reader.GetOrdinal("OwnerName")),
                Phone = reader.GetString(reader.GetOrdinal("Phone")),
                Area = reader.GetString(reader.GetOrdinal("Area")),
                Address = reader.GetString(reader.GetOrdinal("Address")),
                ThanaName = reader.GetString(reader.GetOrdinal("ThanaName")),
                DistrictName = district,
                Latitude = lat,
                Longitude = lon,
                ShopType = shopType,
                FieldOfficerName = reader.GetString(reader.GetOrdinal("FieldOfficerName")),
                FieldOfficerPhone = reader.GetString(reader.GetOrdinal("FieldOfficerPhone")),
                AvailableProductCount = 0,
                DistanceKm = distance
            });
        }

        // Sort nearest shops first if distance available
        if (customerLat.HasValue && customerLon.HasValue)
        {
            return shops.OrderBy(s => s.DistanceKm ?? 999999).ToList();
        }

        return shops;
    }

    public IReadOnlyList<CustomerOrderMaster> GetOrdersByCustomer(int customerId)
    {
        EnsureSchema();
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_CustomerOrder_ListByCustomer");
        command.Parameters.AddWithValue("@CustomerUserId", customerId);
        command.Parameters.AddWithValue("@OrderId", DBNull.Value);

        connection.Open();
        using var reader = command.ExecuteReader();
        return ReadOrders(reader);
    }

    public IReadOnlyList<CustomerOrderMaster> GetOrdersByShopkeeper(int shopkeeperId)
    {
        EnsureSchema();
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_CustomerOrder_ListByShopkeeper");
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);

        connection.Open();
        using var reader = command.ExecuteReader();
        return ReadOrders(reader);
    }

    public CustomerOrderMaster? GetOrderByIdAndPhone(int orderId, string phone)
    {
        EnsureSchema();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            SELECT o.Id, o.CustomerUserId AS CustomerId, o.CustomerName, o.CustomerPhone, o.ShopkeeperId,
                   s.ShopName AS ShopkeeperName, o.OrderDate, o.TotalAmount, o.DiscountAmount, o.Status, o.Remarks,
                   o.DistrictName, o.DeliveryType, o.DeliveryCharge, o.ServiceCharge, o.PlatformCharge
            FROM dbo.tbl_CustomerOrders AS o
            INNER JOIN dbo.tbl_Shopkeepers AS s ON s.Id = o.ShopkeeperId
            WHERE o.Id = @OrderId AND o.CustomerPhone = @Phone;

            SELECT d.Id, d.OrderMasterId, d.ProductId, d.ProductName, d.Sku, d.Quantity, d.UnitPrice,
                   d.BasePrice, d.DistrictAdjustment, d.CompanyMargin, d.ShopkeeperMargin
            FROM dbo.tbl_CustomerOrderDetails AS d
            INNER JOIN dbo.tbl_CustomerOrders AS o ON o.Id = d.OrderMasterId
            WHERE d.OrderMasterId = @OrderId AND o.CustomerPhone = @Phone;
            """, connection);
        command.Parameters.AddWithValue("@OrderId", orderId);
        command.Parameters.AddWithValue("@Phone", phone.Trim());

        connection.Open();
        using var reader = command.ExecuteReader();
        return ReadOrders(reader).FirstOrDefault();
    }

    public void UpdateOrderStatus(int shopkeeperId, int orderId, string status)
    {
        EnsureSchema();
        distributionStore.EnsureSchema();
        walletCreditService.EnsureSchema();
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_CustomerOrder_UpdateStatus");
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@OrderId", orderId);
        command.Parameters.AddWithValue("@Status", status);

        try
        {
            connection.Open();
            command.ExecuteNonQuery();
        }
        catch (SqlException ex) when (ex.Number is 51024 or 51025 or 51110)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    public CustomerOrderMaster CreateOrder(
        int customerId,
        string customerName,
        string customerPhone,
        Shopkeeper shopkeeper,
        CustomerOrderInputModel input)
    {
        EnsureSchema();

        var requestedItems = input.Items
            .Where(item => item.ProductId is not null && item.Quantity is > 0)
            .ToList();

        if (requestedItems.Count == 0)
        {
            throw new InvalidOperationException("Select at least one product before placing the order.");
        }

        var districtName = input.DistrictName ?? shopkeeper.DistrictName ?? "Dhaka";
        var catalog = GetProducts(districtName);
        var catalogMap = catalog.ToDictionary(p => p.Id);

        var requestedProductIds = requestedItems.Select(item => item.ProductId!.Value).Distinct().ToArray();
        var shopProductIds = catalog
            .Where(product => product.AvailableShopkeeperIds.Contains(shopkeeper.Id))
            .Select(product => product.Id)
            .ToHashSet();

        if (requestedProductIds.Any(productId => !shopProductIds.Contains(productId)))
        {
            throw new InvalidOperationException("One or more selected products are not available from this shopkeeper.");
        }

        // Calculate charges
        var pricing = GetDistrictPricing(districtName);
        var deliveryCharge = input.DeliveryType == "হোম ডেলিভারি" ? pricing.DefaultDeliveryCharge : 0.00m;
        var serviceCharge = pricing.ServiceCharge;
        var platformCharge = pricing.PlatformCharge;

        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_CustomerOrder_Create");
        command.Parameters.AddWithValue("@CustomerUserId", customerId);
        command.Parameters.AddWithValue("@CustomerName", customerName.Trim());
        command.Parameters.AddWithValue("@CustomerPhone", customerPhone.Trim());
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeper.Id);
        command.Parameters.AddWithValue("@CustomerLatitude", (object?)input.CustomerLatitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@CustomerLongitude", (object?)input.CustomerLongitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@DistrictName", districtName);
        command.Parameters.AddWithValue("@DeliveryType", input.DeliveryType);
        command.Parameters.AddWithValue("@DeliveryCharge", deliveryCharge);
        command.Parameters.AddWithValue("@ServiceCharge", serviceCharge);
        command.Parameters.AddWithValue("@PlatformCharge", platformCharge);

        var deliveryNote = $"[ডেলিভারি: {input.DeliveryType}{(deliveryCharge > 0 ? $" (চার্জ: ৳{deliveryCharge:N0})" : " (পিকআপ ফ্রি)")} | সার্ভিস চার্জ: ৳{serviceCharge:N0} | পেমেন্ট: {input.PaymentMethod}] {(string.IsNullOrWhiteSpace(input.Remarks) ? "" : input.Remarks.Trim())}".Trim();
        command.Parameters.AddWithValue("@Remarks", deliveryNote);

        var itemsParameter = command.Parameters.Add("@Items", SqlDbType.Structured);
        itemsParameter.TypeName = "dbo.CustomerOrderDetailInput";
        itemsParameter.Value = BuildItemsTable(requestedItems, catalogMap);

        try
        {
            connection.Open();
            using var reader = command.ExecuteReader();
            var orders = ReadOrders(reader);
            return orders.FirstOrDefault()
                ?? throw new InvalidOperationException("Order creation failed.");
        }
        catch (SqlException ex) when (ex.Number is 51020 or 51021 or 51022 or 51023)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    private static SqlCommand CreateCommand(SqlConnection connection, string procedureName)
    {
        return new SqlCommand(procedureName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };
    }

    private static DataTable BuildItemsTable(
        IEnumerable<CustomerOrderItemInputModel> items,
        IReadOnlyDictionary<int, CustomerProductOptionViewModel> catalogMap)
    {
        var table = new DataTable();
        table.Columns.Add("ProductId", typeof(int));
        table.Columns.Add("Quantity", typeof(int));
        table.Columns.Add("BasePrice", typeof(decimal));
        table.Columns.Add("DistrictAdjustment", typeof(decimal));
        table.Columns.Add("CompanyMargin", typeof(decimal));
        table.Columns.Add("ShopkeeperMargin", typeof(decimal));

        foreach (var item in items.Where(item => item.ProductId is not null && item.Quantity is > 0))
        {
            var product = catalogMap[item.ProductId!.Value];
            table.Rows.Add(
                item.ProductId.Value,
                item.Quantity!.Value,
                product.BasePrice,
                product.DistrictAdjustment,
                product.CompanyMargin,
                product.ShopkeeperMargin);
        }

        return table;
    }

    private static IReadOnlyList<CustomerOrderMaster> ReadOrders(SqlDataReader reader)
    {
        var orderRows = new List<CustomerOrderRow>();
        while (reader.Read())
        {
            orderRows.Add(new CustomerOrderRow
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                CustomerId = reader.GetInt32(reader.GetOrdinal("CustomerId")),
                CustomerName = reader.GetString(reader.GetOrdinal("CustomerName")),
                CustomerPhone = reader.GetString(reader.GetOrdinal("CustomerPhone")),
                ShopkeeperId = reader.GetInt32(reader.GetOrdinal("ShopkeeperId")),
                ShopkeeperName = reader.GetString(reader.GetOrdinal("ShopkeeperName")),
                OrderDate = reader.GetDateTime(reader.GetOrdinal("OrderDate")),
                TotalAmount = reader.GetDecimal(reader.GetOrdinal("TotalAmount")),
                DiscountAmount = reader.GetDecimal(reader.GetOrdinal("DiscountAmount")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                Remarks = reader.IsDBNull(reader.GetOrdinal("Remarks")) ? null : reader.GetString(reader.GetOrdinal("Remarks")),
                DistrictName = reader.IsDBNull(reader.GetOrdinal("DistrictName")) ? null : reader.GetString(reader.GetOrdinal("DistrictName")),
                DeliveryType = reader.IsDBNull(reader.GetOrdinal("DeliveryType")) ? "পিকআপ" : reader.GetString(reader.GetOrdinal("DeliveryType")),
                DeliveryCharge = reader.GetDecimal(reader.GetOrdinal("DeliveryCharge")),
                ServiceCharge = reader.GetDecimal(reader.GetOrdinal("ServiceCharge")),
                PlatformCharge = reader.GetDecimal(reader.GetOrdinal("PlatformCharge"))
            });
        }

        reader.NextResult();

        var detailsByOrder = new Dictionary<int, List<CustomerOrderDetail>>();
        while (reader.Read())
        {
            var orderId = reader.GetInt32(reader.GetOrdinal("OrderMasterId"));
            if (!detailsByOrder.TryGetValue(orderId, out var details))
            {
                details = [];
                detailsByOrder[orderId] = details;
            }

            details.Add(new CustomerOrderDetail
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                OrderMasterId = orderId,
                ProductId = reader.GetInt32(reader.GetOrdinal("ProductId")),
                ProductName = reader.GetString(reader.GetOrdinal("ProductName")),
                Sku = reader.GetString(reader.GetOrdinal("Sku")),
                Quantity = reader.GetInt32(reader.GetOrdinal("Quantity")),
                UnitPrice = reader.GetDecimal(reader.GetOrdinal("UnitPrice")),
                BasePrice = reader.GetDecimal(reader.GetOrdinal("BasePrice")),
                DistrictAdjustment = reader.GetDecimal(reader.GetOrdinal("DistrictAdjustment")),
                CompanyMargin = reader.GetDecimal(reader.GetOrdinal("CompanyMargin")),
                ShopkeeperMargin = reader.GetDecimal(reader.GetOrdinal("ShopkeeperMargin"))
            });
        }

        return orderRows
            .Select(order => new CustomerOrderMaster
            {
                Id = order.Id,
                CustomerId = order.CustomerId,
                CustomerName = order.CustomerName,
                CustomerPhone = order.CustomerPhone,
                ShopkeeperId = order.ShopkeeperId,
                ShopkeeperName = order.ShopkeeperName,
                OrderDate = order.OrderDate,
                TotalAmount = order.TotalAmount,
                DiscountAmount = order.DiscountAmount,
                Status = order.Status,
                Remarks = order.Remarks,
                DistrictName = order.DistrictName,
                DeliveryType = order.DeliveryType,
                DeliveryCharge = order.DeliveryCharge,
                ServiceCharge = order.ServiceCharge,
                PlatformCharge = order.PlatformCharge,
                Details = detailsByOrder.GetValueOrDefault(order.Id) ?? []
            })
            .ToList();
    }

    private sealed class CustomerOrderRow
    {
        public int Id { get; init; }
        public int CustomerId { get; init; }
        public string CustomerName { get; init; } = "";
        public string CustomerPhone { get; init; } = "";
        public int ShopkeeperId { get; init; }
        public string ShopkeeperName { get; init; } = "";
        public DateTime OrderDate { get; init; }
        public decimal TotalAmount { get; init; }
        public decimal DiscountAmount { get; init; }
        public string? DistrictName { get; init; }
        public string DeliveryType { get; init; } = "পিকআপ";
        public decimal DeliveryCharge { get; init; }
        public decimal ServiceCharge { get; init; }
        public decimal PlatformCharge { get; init; }
        public string Status { get; init; } = "";
        public string? Remarks { get; init; }
    }

    private sealed class CustomerProductCatalogBuilder
    {
        public int Id { get; init; }
        public string Name { get; init; } = "";
        public string Sku { get; init; } = "";
        public string Category { get; init; } = "";
        public string Uom { get; init; } = "পিস";
        public decimal BasePrice { get; init; }
        public string? ImageUrl { get; set; }
        public HashSet<int> ShopkeeperIds { get; } = [];
    }
}


