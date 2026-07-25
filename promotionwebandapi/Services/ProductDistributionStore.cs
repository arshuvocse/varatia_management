using Microsoft.Data.SqlClient;
using PromotionWeb.Models;

namespace PromotionWeb.Services;

public sealed class ProductDistributionStore(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");
    private static readonly object SchemaLock = new();
    private static bool _schemaReady;

    public void EnsureSchema()
    {
        if (_schemaReady) return;
        lock (SchemaLock)
        {
            if (_schemaReady) return;
            using var connection = new SqlConnection(_connectionString);
            connection.Open();
            using var command = new SqlCommand(SchemaSql, connection);
            command.ExecuteNonQuery();
            _schemaReady = true;
        }
    }

    public string CreateProduct(int companyUserId, CompanyDistributionProductInputModel input)
    {
        EnsureSchema();
        ValidateProduct(input);

        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            const string insertSql = """
                INSERT INTO dbo.tbl_CompanyProducts
                    (ProductCode, Name, Category, Uom, UnitPrice, OpeningStock,
                     ShopkeeperPercentage, CompanyPercentage, AgentPercentage, FieldForcePercentage,
                     CustomerPercentage, CreatedByUserId, ImageUrl)
                VALUES
                    (N'TEMP', @Name, @Category, @Uom, @UnitPrice, @OpeningStock,
                     @ShopkeeperPercentage, @CompanyPercentage, @AgentPercentage, @FieldForcePercentage,
                     @CustomerPercentage, @CompanyUserId, @ImageUrl);

                DECLARE @Id INT = CONVERT(INT, SCOPE_IDENTITY());
                DECLARE @Code NVARCHAR(50) = CONCAT(N'PRD-', FORMAT(@Id, N'000000'));
                UPDATE dbo.tbl_CompanyProducts SET ProductCode = @Code WHERE Id = @Id;

                INSERT INTO dbo.tbl_CustomerOrderProducts (Name, Sku, Category, UnitPrice, ImageUrl)
                SELECT @Name, @Code, @Category, @UnitPrice, @ImageUrl
                WHERE NOT EXISTS (SELECT 1 FROM dbo.tbl_CustomerOrderProducts WHERE Sku = @Code);

                SELECT @Code;
                """;
            using var command = new SqlCommand(insertSql, connection, transaction);
            command.Parameters.AddWithValue("@Name", input.Name.Trim());
            command.Parameters.AddWithValue("@Category", input.Category.Trim());
            command.Parameters.AddWithValue("@Uom", input.Uom.Trim());
            command.Parameters.AddWithValue("@UnitPrice", input.UnitPrice);
            command.Parameters.AddWithValue("@OpeningStock", input.OpeningStock);
            command.Parameters.AddWithValue("@ShopkeeperPercentage", 100m);
            command.Parameters.AddWithValue("@CompanyPercentage", 0m);
            command.Parameters.AddWithValue("@AgentPercentage", 0m);
            command.Parameters.AddWithValue("@FieldForcePercentage", 0m);
            command.Parameters.AddWithValue("@CustomerPercentage", 0m);
            command.Parameters.AddWithValue("@CompanyUserId", companyUserId);
            command.Parameters.AddWithValue("@ImageUrl", input.ImageUrl ?? (object)DBNull.Value);
            var code = Convert.ToString(command.ExecuteScalar()) ?? "";
            transaction.Commit();
            return code;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public IReadOnlyList<CompanyDistributionProductViewModel> GetProducts(int companyUserId)
    {
        EnsureSchema();
        SyncExistingProducts(companyUserId);
        const string sql = """
            SELECT Id, ProductCode, Name, Category, Uom, UnitPrice, OpeningStock,
                   ShopkeeperPercentage, CompanyPercentage, AgentPercentage, FieldForcePercentage,
                   CustomerPercentage, IsActive, CreatedAt, ImageUrl
            FROM dbo.tbl_CompanyProducts
            ORDER BY Id DESC;
            """;
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        connection.Open();
        using var reader = command.ExecuteReader();
        var items = new List<CompanyDistributionProductViewModel>();
        while (reader.Read())
        {
            items.Add(new CompanyDistributionProductViewModel
            {
                Id = reader.GetInt32(0),
                ProductCode = reader.GetString(1),
                Name = reader.GetString(2),
                Category = reader.GetString(3),
                Uom = reader.GetString(4),
                UnitPrice = reader.GetDecimal(5),
                OpeningStock = reader.GetInt32(6),
                ShopkeeperPercentage = reader.GetDecimal(7),
                CompanyPercentage = reader.GetDecimal(8),
                AgentPercentage = reader.GetDecimal(9),
                FieldForcePercentage = reader.GetDecimal(10),
                CustomerPercentage = reader.GetDecimal(11),
                IsActive = reader.GetBoolean(12),
                CreatedAt = reader.GetDateTime(13),
                ImageUrl = reader.IsDBNull(14) ? null : reader.GetString(14)
            });
        }
        return items;
    }

    private void SyncExistingProducts(int companyUserId)
    {
        if (companyUserId <= 0) return;

        const string sql = """
            ;WITH Catalog AS (
                SELECT
                    p.Sku,
                    p.Name,
                    p.Category,
                    p.UnitPrice,
                    ROW_NUMBER() OVER (PARTITION BY p.Sku ORDER BY p.Id DESC) AS RowNumber
                FROM dbo.tbl_Products p
                WHERE p.IsActive = 1
                  AND NULLIF(LTRIM(RTRIM(p.Sku)), N'') IS NOT NULL
            )
            INSERT INTO dbo.tbl_CompanyProducts
                (ProductCode, Name, Category, Uom, UnitPrice, OpeningStock,
                 ShopkeeperPercentage, CompanyPercentage, AgentPercentage, FieldForcePercentage,
                 CustomerPercentage, CreatedByUserId, ImageUrl)
            SELECT
                catalog.Sku, catalog.Name, catalog.Category, N'pcs',
                catalog.UnitPrice, 0, 100, 0, 0, 0, 0, @CompanyUserId, NULL
            FROM Catalog catalog
            WHERE catalog.RowNumber = 1
              AND NOT EXISTS (
                  SELECT 1
                  FROM dbo.tbl_CompanyProducts companyProduct
                  WHERE companyProduct.ProductCode = catalog.Sku
              );
            """;
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@CompanyUserId", companyUserId);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public void UpdateProductAllocation(CompanyProductAllocationInputModel input)
    {
        EnsureSchema();
        if (input.ProductId <= 0)
            throw new InvalidOperationException("Select a valid product.");
        if (input.ShopkeeperPercentage < 0
            || input.CompanyPercentage < 0
            || input.AgentPercentage < 0
            || input.FieldForcePercentage < 0
            || input.CustomerPercentage < 0)
            throw new InvalidOperationException("Allocation percentages cannot be negative.");
        if (Math.Abs(input.TotalPercentage - 100m) > 0.0001m)
            throw new InvalidOperationException("Total profit percentage must be exactly 100%.");

        const string sql = """
            IF NOT EXISTS (
                SELECT 1 FROM dbo.tbl_CompanyProducts
                WHERE Id = @ProductId AND IsActive = 1
            )
                THROW 51120, N'Product was not found.', 1;

            IF ABS(@TotalPercentage - @NewTotal) > 0.0001
                THROW 51121, N'Shopkeeper, company, agent, field force and customer shares must equal 100% of product profit.', 1;

            UPDATE dbo.tbl_CompanyProducts
            SET ShopkeeperPercentage = @ShopkeeperPercentage,
                CompanyPercentage = @CompanyPercentage,
                AgentPercentage = @AgentPercentage,
                FieldForcePercentage = @FieldForcePercentage,
                CustomerPercentage = @CustomerPercentage,
                ImageUrl = COALESCE(@ImageUrl, ImageUrl)
            WHERE Id = @ProductId;
            """;
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@ProductId", input.ProductId);
        command.Parameters.AddWithValue("@TotalPercentage", input.TotalPercentage);
        command.Parameters.AddWithValue("@ShopkeeperPercentage", input.ShopkeeperPercentage);
        command.Parameters.AddWithValue("@CompanyPercentage", input.CompanyPercentage);
        command.Parameters.AddWithValue("@AgentPercentage", input.AgentPercentage);
        command.Parameters.AddWithValue("@FieldForcePercentage", input.FieldForcePercentage);
        command.Parameters.AddWithValue("@CustomerPercentage", input.CustomerPercentage);
        command.Parameters.AddWithValue("@ImageUrl", input.ImageUrl ?? (object)DBNull.Value);
        command.Parameters.AddWithValue("@NewTotal",
            input.ShopkeeperPercentage + input.CompanyPercentage + input.AgentPercentage
            + input.FieldForcePercentage + input.CustomerPercentage);
        connection.Open();
        try
        {
            command.ExecuteNonQuery();
        }
        catch (SqlException ex) when (ex.Number is 51120 or 51121)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    public void UpdateProductForFieldOfficer(int fieldOfficerUserId, FieldOfficerProductEditInputModel input)
    {
        EnsureSchema();
        if (fieldOfficerUserId <= 0 || input.ProductId <= 0)
            throw new InvalidOperationException("Invalid field force or product.");
        if (string.IsNullOrWhiteSpace(input.Name)
            || string.IsNullOrWhiteSpace(input.Category)
            || string.IsNullOrWhiteSpace(input.Uom))
            throw new InvalidOperationException("Product name, category and UOM are required.");
        if (input.UnitPrice <= 0 || input.OpeningStock < 0)
            throw new InvalidOperationException("Default price must be positive and stock cannot be negative.");

        var percentages = new[]
        {
            input.ShopkeeperPercentage,
            input.CompanyPercentage,
            input.AgentPercentage,
            input.FieldForcePercentage,
            input.CustomerPercentage
        };
        if (percentages.Any(value => value < 0) || Math.Abs(percentages.Sum() - 100m) > 0.0001m)
            throw new InvalidOperationException("Percentages cannot be negative and their total must equal 100% of product profit.");

        const string sql = """
            IF NOT EXISTS (
                SELECT 1 FROM dbo.tbl_Users
                WHERE Id = @FieldOfficerUserId AND Role = N'FieldOfficer' AND IsActive = 1
            )
                THROW 51140, N'Invalid field force account.', 1;
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_CompanyProducts WHERE Id = @ProductId AND IsActive = 1)
                THROW 51141, N'Product was not found.', 1;

            DECLARE @ProductCode NVARCHAR(50);
            SELECT @ProductCode = ProductCode FROM dbo.tbl_CompanyProducts WHERE Id = @ProductId;

            UPDATE dbo.tbl_CompanyProducts
            SET Name = @Name,
                Category = @Category,
                Uom = @Uom,
                UnitPrice = @UnitPrice,
                OpeningStock = @OpeningStock,
                ShopkeeperPercentage = @ShopkeeperPercentage,
                CompanyPercentage = @CompanyPercentage,
                AgentPercentage = @AgentPercentage,
                FieldForcePercentage = @FieldForcePercentage,
                CustomerPercentage = @CustomerPercentage,
                ImageUrl = COALESCE(@ImageUrl, ImageUrl)
            WHERE Id = @ProductId;

            -- Preserve every shop's own prices while keeping shared product details in sync.
            UPDATE dbo.tbl_Products
            SET Name = @Name, Category = @Category, ImageUrl = COALESCE(@ImageUrl, ImageUrl)
            WHERE Sku = @ProductCode;

            UPDATE dbo.tbl_CustomerOrderProducts
            SET Name = @Name, Category = @Category, UnitPrice = @UnitPrice,
                ImageUrl = COALESCE(@ImageUrl, ImageUrl)
            WHERE Sku = @ProductCode;
            """;
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@FieldOfficerUserId", fieldOfficerUserId);
        command.Parameters.AddWithValue("@ProductId", input.ProductId);
        command.Parameters.AddWithValue("@Name", input.Name.Trim());
        command.Parameters.AddWithValue("@Category", input.Category.Trim());
        command.Parameters.AddWithValue("@Uom", input.Uom.Trim());
        command.Parameters.AddWithValue("@UnitPrice", input.UnitPrice);
        command.Parameters.AddWithValue("@OpeningStock", input.OpeningStock);
        command.Parameters.AddWithValue("@ShopkeeperPercentage", input.ShopkeeperPercentage);
        command.Parameters.AddWithValue("@CompanyPercentage", input.CompanyPercentage);
        command.Parameters.AddWithValue("@AgentPercentage", input.AgentPercentage);
        command.Parameters.AddWithValue("@FieldForcePercentage", input.FieldForcePercentage);
        command.Parameters.AddWithValue("@CustomerPercentage", input.CustomerPercentage);
        command.Parameters.AddWithValue("@ImageUrl", input.ImageUrl ?? (object)DBNull.Value);
        try
        {
            connection.Open();
            command.ExecuteNonQuery();
        }
        catch (SqlException ex) when (ex.Number is 51140 or 51141)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    public void FundShopWallet(
        int shopkeeperId,
        ShopkeeperWalletFundingInputModel input,
        int shopkeeperUserId)
    {
        EnsureSchema();
        if (shopkeeperId <= 0 || input.Amount <= 0)
            throw new InvalidOperationException("শূন্যের চেয়ে বেশি টাকার পরিমাণ দিন।");

        const string sql = """
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Shopkeepers WHERE Id = @ShopkeeperId)
                THROW 51101, N'Shopkeeper was not found.', 1;

            MERGE dbo.tbl_ShopkeeperWallets AS target
            USING (SELECT @ShopkeeperId AS ShopkeeperId) AS source
                ON target.ShopkeeperId = source.ShopkeeperId
            WHEN MATCHED THEN UPDATE SET
                Balance = target.Balance + @Amount,
                WithdrawableBalance = target.WithdrawableBalance + @Amount,
                UpdatedAt = SYSUTCDATETIME()
            WHEN NOT MATCHED THEN INSERT
                (ShopkeeperId, Balance, WithdrawableBalance, PendingBalance)
                VALUES (@ShopkeeperId, @Amount, @Amount, 0);

            INSERT INTO dbo.tbl_DistributionLedger
                (UserId, ShopkeeperId, EntryType, RecipientType, Amount, SourceType, SourceId, ProductCode, Note)
            VALUES
                (@CompanyUserId, @ShopkeeperId, N'Credit', N'ShopkeeperFunding',
                 @Amount, N'WalletFunding', 0, N'', @Note);
            """;
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        using var command = new SqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@Amount", input.Amount);
        if (shopkeeperUserId > 0)
            command.Parameters.AddWithValue("@CompanyUserId", shopkeeperUserId);
        else
            command.Parameters.AddWithValue("@CompanyUserId", DBNull.Value);
        command.Parameters.AddWithValue("@Note",
            string.IsNullOrWhiteSpace(input.Note) ? DBNull.Value : input.Note.Trim());
        try
        {
            command.ExecuteNonQuery();
            transaction.Commit();
        }
        catch (SqlException ex) when (ex.Number == 51101)
        {
            transaction.Rollback();
            throw new InvalidOperationException(ex.Message, ex);
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public decimal GetShopWalletBalance(int shopkeeperId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(
            "SELECT COALESCE((SELECT Balance FROM dbo.tbl_ShopkeeperWallets WHERE ShopkeeperId = @ShopkeeperId), 0);",
            connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        connection.Open();
        return Convert.ToDecimal(command.ExecuteScalar());
    }

    public decimal GetUserWalletBalance(int userId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(
            "SELECT COALESCE((SELECT Balance FROM dbo.tbl_UserWallets WHERE UserId = @UserId), 0);",
            connection);
        command.Parameters.AddWithValue("@UserId", userId);
        connection.Open();
        return Convert.ToDecimal(command.ExecuteScalar());
    }

    public void SyncCatalogForShop(int shopkeeperId)
    {
        EnsureSchema();
        const string sql = """
            INSERT INTO dbo.tbl_Products
                (ShopkeeperId, Name, Sku, Category, PurchasePrice, UnitPrice, StockQuantity, ImageUrl)
            SELECT @ShopkeeperId, cp.Name, cp.ProductCode, cp.Category, cp.UnitPrice, cp.UnitPrice, cp.OpeningStock, cp.ImageUrl
            FROM dbo.tbl_CompanyProducts cp
            INNER JOIN dbo.tbl_Shopkeepers s ON s.Id = @ShopkeeperId
            WHERE cp.IsActive = 1
              AND cp.Category = s.ShopType
              AND EXISTS (
                  SELECT 1 FROM dbo.tbl_ShopkeeperProductSelections choice
                  WHERE choice.ShopkeeperId = @ShopkeeperId
                    AND choice.CompanyProductId = cp.Id
              )
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.tbl_Products p
                  WHERE p.ShopkeeperId = @ShopkeeperId AND p.Sku = cp.ProductCode
              );
            """;
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public void AssignProductsToShop(int shopkeeperId, string category, IReadOnlyCollection<int> productIds)
    {
        EnsureSchema();
        var selectedIds = productIds.Where(id => id > 0).Distinct().ToArray();
        if (selectedIds.Length == 0)
            throw new InvalidOperationException("Select at least one product.");

        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            foreach (var productId in selectedIds)
            {
                using var command = new SqlCommand("""
                    IF NOT EXISTS (
                        SELECT 1 FROM dbo.tbl_CompanyProducts
                        WHERE Id = @ProductId AND IsActive = 1 AND Category = @Category
                    )
                        THROW 51130, N'An invalid product was selected for this category.', 1;

                    IF NOT EXISTS (
                        SELECT 1 FROM dbo.tbl_ShopkeeperProductSelections
                        WHERE ShopkeeperId = @ShopkeeperId AND CompanyProductId = @ProductId
                    )
                        INSERT INTO dbo.tbl_ShopkeeperProductSelections (ShopkeeperId, CompanyProductId)
                        VALUES (@ShopkeeperId, @ProductId);

                    INSERT INTO dbo.tbl_Products
                        (ShopkeeperId, Name, Sku, Category, PurchasePrice, UnitPrice, StockQuantity, ImageUrl)
                    SELECT @ShopkeeperId, Name, ProductCode, Category, UnitPrice, UnitPrice, OpeningStock, ImageUrl
                    FROM dbo.tbl_CompanyProducts cp
                    WHERE cp.Id = @ProductId
                      AND NOT EXISTS (
                          SELECT 1 FROM dbo.tbl_Products p
                          WHERE p.ShopkeeperId = @ShopkeeperId AND p.Sku = cp.ProductCode
                      );
                    """, connection, transaction);
                command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
                command.Parameters.AddWithValue("@ProductId", productId);
                command.Parameters.AddWithValue("@Category", category.Trim());
                command.ExecuteNonQuery();
            }
            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public IReadOnlyList<ShopProductAssignmentViewModel> GetShopProductAssignments(int fieldOfficerUserId)
    {
        EnsureSchema();
        const string sql = """
            SELECT choice.ShopkeeperId, choice.CompanyProductId,
                   COALESCE(product.PurchasePrice, companyProduct.UnitPrice) AS PurchasePrice,
                   COALESCE(product.UnitPrice, companyProduct.UnitPrice) AS SalesPrice
            FROM dbo.tbl_ShopkeeperProductSelections choice
            INNER JOIN dbo.tbl_Shopkeepers shop ON shop.Id = choice.ShopkeeperId
            INNER JOIN dbo.tbl_CompanyProducts companyProduct ON companyProduct.Id = choice.CompanyProductId
            LEFT JOIN dbo.tbl_Products product
                ON product.ShopkeeperId = choice.ShopkeeperId
               AND product.Sku = companyProduct.ProductCode
            WHERE shop.FieldOfficerUserId = @FieldOfficerUserId;
            """;
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@FieldOfficerUserId", fieldOfficerUserId);
        connection.Open();
        using var reader = command.ExecuteReader();
        var result = new List<ShopProductAssignmentViewModel>();
        while (reader.Read())
        {
            result.Add(new ShopProductAssignmentViewModel
            {
                ShopkeeperId = reader.GetInt32(0),
                CompanyProductId = reader.GetInt32(1),
                PurchasePrice = reader.GetDecimal(2),
                SalesPrice = reader.GetDecimal(3)
            });
        }
        return result;
    }

    public void UpdateShopProductAssignments(
        int fieldOfficerUserId,
        int shopkeeperId,
        string category,
        IReadOnlyCollection<int> productIds,
        IReadOnlyCollection<ShopProductPriceInputModel> prices)
    {
        EnsureSchema();
        var selectedIds = productIds.Where(id => id > 0).Distinct().ToArray();
        var priceMap = prices
            .Where(item => item.CompanyProductId > 0)
            .GroupBy(item => item.CompanyProductId)
            .ToDictionary(group => group.Key, group => group.Last());
        foreach (var productId in selectedIds)
        {
            if (!priceMap.TryGetValue(productId, out var price)
                || price.PurchasePrice < 0
                || price.SalesPrice <= 0
                || price.SalesPrice < price.PurchasePrice)
                throw new InvalidOperationException("Every selected product needs valid purchase and sales prices; sales price cannot be below purchase price.");
        }

        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        try
        {
            using (var guard = new SqlCommand("""
                IF NOT EXISTS (
                    SELECT 1 FROM dbo.tbl_Shopkeepers
                    WHERE Id = @ShopkeeperId AND FieldOfficerUserId = @FieldOfficerUserId
                )
                    THROW 51150, N'You can edit only your own shopkeepers.', 1;
                IF EXISTS (
                    SELECT value.Id
                    FROM (SELECT CAST([value] AS INT) AS Id FROM OPENJSON(@ProductIds)) value
                    LEFT JOIN dbo.tbl_CompanyProducts product ON product.Id = value.Id
                    WHERE product.Id IS NULL OR product.IsActive = 0 OR product.Category <> @Category
                )
                    THROW 51151, N'An invalid product was selected for this shop category.', 1;

                DELETE choice
                FROM dbo.tbl_ShopkeeperProductSelections choice
                WHERE choice.ShopkeeperId = @ShopkeeperId
                  AND NOT EXISTS (
                      SELECT 1 FROM OPENJSON(@ProductIds) selected
                      WHERE CAST(selected.[value] AS INT) = choice.CompanyProductId
                  );

                UPDATE product
                SET IsActive = 0
                FROM dbo.tbl_Products product
                INNER JOIN dbo.tbl_CompanyProducts companyProduct ON companyProduct.ProductCode = product.Sku
                WHERE product.ShopkeeperId = @ShopkeeperId
                  AND NOT EXISTS (
                      SELECT 1 FROM OPENJSON(@ProductIds) selected
                      WHERE CAST(selected.[value] AS INT) = companyProduct.Id
                  );
                """, connection, transaction))
            {
                guard.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
                guard.Parameters.AddWithValue("@FieldOfficerUserId", fieldOfficerUserId);
                guard.Parameters.AddWithValue("@Category", category.Trim());
                guard.Parameters.AddWithValue("@ProductIds", System.Text.Json.JsonSerializer.Serialize(selectedIds));
                guard.ExecuteNonQuery();
            }

            foreach (var productId in selectedIds)
            {
                var price = priceMap[productId];
                using var command = new SqlCommand("""
                    IF NOT EXISTS (
                        SELECT 1 FROM dbo.tbl_ShopkeeperProductSelections
                        WHERE ShopkeeperId = @ShopkeeperId AND CompanyProductId = @ProductId
                    )
                        INSERT dbo.tbl_ShopkeeperProductSelections (ShopkeeperId, CompanyProductId)
                        VALUES (@ShopkeeperId, @ProductId);

                    IF EXISTS (
                        SELECT 1 FROM dbo.tbl_Products product
                        INNER JOIN dbo.tbl_CompanyProducts companyProduct ON companyProduct.ProductCode = product.Sku
                        WHERE product.ShopkeeperId = @ShopkeeperId AND companyProduct.Id = @ProductId
                    )
                        UPDATE product
                        SET product.PurchasePrice = @PurchasePrice,
                            product.UnitPrice = @SalesPrice,
                            product.IsActive = 1,
                            product.Name = companyProduct.Name,
                            product.Category = companyProduct.Category,
                            product.ImageUrl = COALESCE(companyProduct.ImageUrl, product.ImageUrl)
                        FROM dbo.tbl_Products product
                        INNER JOIN dbo.tbl_CompanyProducts companyProduct ON companyProduct.ProductCode = product.Sku
                        WHERE product.ShopkeeperId = @ShopkeeperId AND companyProduct.Id = @ProductId;
                    ELSE
                        INSERT dbo.tbl_Products
                            (ShopkeeperId, Name, Sku, Category, PurchasePrice, UnitPrice, StockQuantity, ImageUrl)
                        SELECT @ShopkeeperId, Name, ProductCode, Category, @PurchasePrice, @SalesPrice, OpeningStock, ImageUrl
                        FROM dbo.tbl_CompanyProducts WHERE Id = @ProductId;
                    """, connection, transaction);
                command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
                command.Parameters.AddWithValue("@ProductId", productId);
                command.Parameters.AddWithValue("@PurchasePrice", price.PurchasePrice);
                command.Parameters.AddWithValue("@SalesPrice", price.SalesPrice);
                command.ExecuteNonQuery();
            }
            transaction.Commit();
        }
        catch (SqlException ex) when (ex.Number is 51150 or 51151)
        {
            transaction.Rollback();
            throw new InvalidOperationException(ex.Message, ex);
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public void SyncCustomerCatalog()
    {
        EnsureSchema();
        const string sql = """
            INSERT INTO dbo.tbl_CustomerOrderProducts (Name, Sku, Category, UnitPrice, ImageUrl)
            SELECT cp.Name, cp.ProductCode, cp.Category, cp.UnitPrice, cp.ImageUrl
            FROM dbo.tbl_CompanyProducts cp
            WHERE cp.IsActive = 1
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.tbl_CustomerOrderProducts p WHERE p.Sku = cp.ProductCode
              );

            -- Shopkeepers can also add their own products directly (dbo.sp_Product_Add), separate from
            -- company-distributed products above. Mirror those into the same global catalog so customers
            -- can see and order them too. The Sku is namespaced per shopkeeper because tbl_CustomerOrderProducts.Sku
            -- is globally unique, while tbl_Products only guarantees uniqueness per (ShopkeeperId, Sku).
            INSERT INTO dbo.tbl_CustomerOrderProducts (Name, Sku, Category, UnitPrice, ImageUrl)
            SELECT p.Name, CONCAT(N'SP', p.ShopkeeperId, N'-', p.Sku), p.Category, p.UnitPrice, p.ImageUrl
            FROM dbo.tbl_Products p
            WHERE p.IsActive = 1
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.tbl_CompanyProducts cp WHERE cp.ProductCode = p.Sku AND cp.IsActive = 1
              )
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.tbl_CustomerOrderProducts ex
                  WHERE ex.Sku = CONCAT(N'SP', p.ShopkeeperId, N'-', p.Sku)
              );
            """;
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        connection.Open();
        command.ExecuteNonQuery();
    }

    private static void ValidateProduct(CompanyDistributionProductInputModel input)
    {
        if (string.IsNullOrWhiteSpace(input.Name)
            || string.IsNullOrWhiteSpace(input.Category)
            || string.IsNullOrWhiteSpace(input.Uom))
            throw new InvalidOperationException("Product name, category and UOM are required.");
        if (input.UnitPrice <= 0 || input.OpeningStock < 0)
            throw new InvalidOperationException("Unit price must be positive and stock cannot be negative.");
    }

    private const string SchemaSql = """
        IF OBJECT_ID(N'dbo.tbl_CompanyProducts', N'U') IS NULL
        CREATE TABLE dbo.tbl_CompanyProducts (
            Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_CompanyProducts PRIMARY KEY,
            ProductCode NVARCHAR(50) NOT NULL CONSTRAINT UQ_tbl_CompanyProducts_Code UNIQUE,
            Name NVARCHAR(150) NOT NULL,
            Category NVARCHAR(100) NOT NULL,
            Uom NVARCHAR(30) NOT NULL,
            UnitPrice DECIMAL(18,2) NOT NULL,
            OpeningStock INT NOT NULL,
            ShopkeeperPercentage DECIMAL(7,4) NOT NULL,
            CompanyPercentage DECIMAL(7,4) NOT NULL,
            AgentPercentage DECIMAL(7,4) NOT NULL,
            FieldForcePercentage DECIMAL(7,4) NOT NULL,
            CustomerPercentage DECIMAL(7,4) NOT NULL,
            CreatedByUserId INT NOT NULL,
            IsActive BIT NOT NULL CONSTRAINT DF_tbl_CompanyProducts_Active DEFAULT (1),
            CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_CompanyProducts_Created DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_tbl_CompanyProducts_User FOREIGN KEY (CreatedByUserId) REFERENCES dbo.tbl_Users(Id)
        );

        IF COL_LENGTH(N'dbo.tbl_CompanyProducts', N'ImageUrl') IS NULL
            ALTER TABLE dbo.tbl_CompanyProducts ADD ImageUrl NVARCHAR(500) NULL;

        IF COL_LENGTH(N'dbo.tbl_CompanyProducts', N'ShopkeeperPercentage') IS NULL
        BEGIN
            ALTER TABLE dbo.tbl_CompanyProducts
            ADD ShopkeeperPercentage DECIMAL(7,4) NOT NULL
                CONSTRAINT DF_tbl_CompanyProducts_ShopkeeperPercentage DEFAULT (100);
            EXEC(N'UPDATE dbo.tbl_CompanyProducts
                   SET ShopkeeperPercentage =
                       CASE
                           WHEN 100 - (CompanyPercentage + AgentPercentage + FieldForcePercentage + CustomerPercentage) < 0
                           THEN 0
                           ELSE 100 - (CompanyPercentage + AgentPercentage + FieldForcePercentage + CustomerPercentage)
                       END;');
        END;

        IF COL_LENGTH(N'dbo.tbl_Products', N'ImageUrl') IS NULL
            ALTER TABLE dbo.tbl_Products ADD ImageUrl NVARCHAR(500) NULL;

        IF COL_LENGTH(N'dbo.tbl_CustomerOrderProducts', N'ImageUrl') IS NULL
            ALTER TABLE dbo.tbl_CustomerOrderProducts ADD ImageUrl NVARCHAR(500) NULL;

        IF COL_LENGTH(N'dbo.tbl_CompanyProducts', N'FieldForcePercentage') IS NULL
            ALTER TABLE dbo.tbl_CompanyProducts
            ADD FieldForcePercentage DECIMAL(7,4) NOT NULL
                CONSTRAINT DF_tbl_CompanyProducts_FieldForcePercentage DEFAULT (0);

        IF OBJECT_ID(N'dbo.tbl_ShopkeeperProductSelections', N'U') IS NULL
        CREATE TABLE dbo.tbl_ShopkeeperProductSelections (
            ShopkeeperId INT NOT NULL,
            CompanyProductId INT NOT NULL,
            CreatedAt DATETIME2(0) NOT NULL
                CONSTRAINT DF_tbl_ShopkeeperProductSelections_Created DEFAULT SYSUTCDATETIME(),
            CONSTRAINT PK_tbl_ShopkeeperProductSelections PRIMARY KEY (ShopkeeperId, CompanyProductId),
            CONSTRAINT FK_tbl_ShopkeeperProductSelections_Shopkeeper
                FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
            CONSTRAINT FK_tbl_ShopkeeperProductSelections_Product
                FOREIGN KEY (CompanyProductId) REFERENCES dbo.tbl_CompanyProducts(Id)
        );

        IF COL_LENGTH(N'dbo.tbl_Products', N'PurchasePrice') IS NULL
        BEGIN
            ALTER TABLE dbo.tbl_Products ADD PurchasePrice DECIMAL(18,2) NOT NULL
                CONSTRAINT DF_tbl_Products_PurchasePrice DEFAULT (0);
            EXEC(N'UPDATE dbo.tbl_Products
                   SET PurchasePrice = UnitPrice
                   WHERE PurchasePrice = 0;');
        END;

        IF OBJECT_ID(N'dbo.tbl_UserWallets', N'U') IS NULL
        CREATE TABLE dbo.tbl_UserWallets (
            UserId INT NOT NULL CONSTRAINT PK_tbl_UserWallets PRIMARY KEY,
            Balance DECIMAL(18,2) NOT NULL CONSTRAINT DF_tbl_UserWallets_Balance DEFAULT (0),
            UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_UserWallets_Updated DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_tbl_UserWallets_User FOREIGN KEY (UserId) REFERENCES dbo.tbl_Users(Id)
        );

        IF OBJECT_ID(N'dbo.tbl_DistributionLedger', N'U') IS NULL
        CREATE TABLE dbo.tbl_DistributionLedger (
            Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_DistributionLedger PRIMARY KEY,
            UserId INT NULL,
            ShopkeeperId INT NOT NULL,
            EntryType NVARCHAR(20) NOT NULL,
            RecipientType NVARCHAR(30) NOT NULL,
            Amount DECIMAL(18,2) NOT NULL,
            SourceType NVARCHAR(30) NOT NULL,
            SourceId INT NOT NULL,
            ProductCode NVARCHAR(50) NOT NULL,
            Note NVARCHAR(250) NULL,
            CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_tbl_DistributionLedger_Created DEFAULT SYSUTCDATETIME(),
            CONSTRAINT FK_tbl_DistributionLedger_User FOREIGN KEY (UserId) REFERENCES dbo.tbl_Users(Id),
            CONSTRAINT FK_tbl_DistributionLedger_Shop FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id)
        );

        EXEC(N'
        CREATE OR ALTER TRIGGER dbo.tr_SaleDetails_Distribute
        ON dbo.tbl_SaleDetails
        AFTER INSERT
        AS
        BEGIN
            SET NOCOUNT ON;
            DECLARE @ShopkeeperId INT, @SaleId INT, @CustomerUserId INT,
                    @AgentUserId INT, @FieldForceUserId INT;
            DECLARE @Required DECIMAL(18,2);

            SELECT TOP (1) @SaleId = i.SaleId, @ShopkeeperId = s.ShopkeeperId
            FROM inserted i INNER JOIN dbo.tbl_Sales s ON s.Id = i.SaleId;

            SELECT @CustomerUserId = u.Id
            FROM dbo.tbl_Sales s
            INNER JOIN dbo.tbl_Customers c ON c.Id = s.CustomerId
            INNER JOIN dbo.tbl_Users u ON u.Phone = c.Phone AND u.Role = N''Customer''
            WHERE s.Id = @SaleId;

            SELECT @FieldForceUserId = fo.Id, @AgentUserId = fo.ParentUserId
            FROM dbo.tbl_Shopkeepers sh
            INNER JOIN dbo.tbl_Users fo ON fo.Id = sh.FieldOfficerUserId
            WHERE sh.Id = @ShopkeeperId;

            SELECT @Required = COALESCE(SUM(ROUND(i.Quantity *
                CASE WHEN i.UnitPrice > p.PurchasePrice THEN i.UnitPrice - p.PurchasePrice ELSE 0 END *
                (cp.CompanyPercentage +
                 CASE WHEN @AgentUserId IS NULL THEN 0 ELSE cp.AgentPercentage END +
                 CASE WHEN @FieldForceUserId IS NULL THEN 0 ELSE cp.FieldForcePercentage END +
                 CASE WHEN @CustomerUserId IS NULL THEN 0 ELSE cp.CustomerPercentage END) / 100.0, 2)), 0)
            FROM inserted i
            INNER JOIN dbo.tbl_Products p ON p.Id = i.ProductId
            INNER JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode = p.Sku AND cp.IsActive = 1;

            IF @Required > 0
            BEGIN
                UPDATE dbo.tbl_ShopkeeperWallets WITH (UPDLOCK, HOLDLOCK)
                SET Balance = Balance - @Required,
                    WithdrawableBalance = CASE WHEN WithdrawableBalance >= @Required
                        THEN WithdrawableBalance - @Required ELSE 0 END,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE ShopkeeperId = @ShopkeeperId AND Balance >= @Required;
                IF @@ROWCOUNT = 0 THROW 51110, N''Insufficient shopkeeper wallet balance for product distribution.'', 1;

                ;WITH Entries AS (
                    SELECT cp.CreatedByUserId UserId, N''Company'' RecipientType, p.Sku ProductCode,
                           ROUND(i.Quantity * CASE WHEN i.UnitPrice > p.PurchasePrice THEN i.UnitPrice - p.PurchasePrice ELSE 0 END * cp.CompanyPercentage / 100.0, 2) Amount
                    FROM inserted i JOIN dbo.tbl_Products p ON p.Id=i.ProductId
                    JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=p.Sku AND cp.IsActive=1
                    UNION ALL
                    SELECT @AgentUserId, N''Agent'', p.Sku,
                           ROUND(i.Quantity * CASE WHEN i.UnitPrice > p.PurchasePrice THEN i.UnitPrice - p.PurchasePrice ELSE 0 END * cp.AgentPercentage / 100.0, 2)
                    FROM inserted i JOIN dbo.tbl_Products p ON p.Id=i.ProductId
                    JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=p.Sku AND cp.IsActive=1
                    WHERE @AgentUserId IS NOT NULL
                    UNION ALL
                    SELECT @FieldForceUserId, N''FieldForce'', p.Sku,
                           ROUND(i.Quantity * CASE WHEN i.UnitPrice > p.PurchasePrice THEN i.UnitPrice - p.PurchasePrice ELSE 0 END * cp.FieldForcePercentage / 100.0, 2)
                    FROM inserted i JOIN dbo.tbl_Products p ON p.Id=i.ProductId
                    JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=p.Sku AND cp.IsActive=1
                    WHERE @FieldForceUserId IS NOT NULL
                    UNION ALL
                    SELECT @CustomerUserId, N''Customer'', p.Sku,
                           ROUND(i.Quantity * CASE WHEN i.UnitPrice > p.PurchasePrice THEN i.UnitPrice - p.PurchasePrice ELSE 0 END * cp.CustomerPercentage / 100.0, 2)
                    FROM inserted i JOIN dbo.tbl_Products p ON p.Id=i.ProductId
                    JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=p.Sku AND cp.IsActive=1
                    WHERE @CustomerUserId IS NOT NULL
                )
                SELECT * INTO #Entries FROM Entries WHERE Amount > 0 AND UserId IS NOT NULL;

                MERGE dbo.tbl_UserWallets t USING
                    (SELECT UserId, SUM(Amount) Amount FROM #Entries GROUP BY UserId) s
                ON t.UserId=s.UserId
                WHEN MATCHED THEN UPDATE SET Balance=t.Balance+s.Amount, UpdatedAt=SYSUTCDATETIME()
                WHEN NOT MATCHED THEN INSERT(UserId,Balance) VALUES(s.UserId,s.Amount);

                INSERT dbo.tbl_DistributionLedger
                    (UserId,ShopkeeperId,EntryType,RecipientType,Amount,SourceType,SourceId,ProductCode)
                SELECT UserId,@ShopkeeperId,N''Credit'',RecipientType,Amount,N''Sale'',@SaleId,ProductCode FROM #Entries;
                INSERT dbo.tbl_DistributionLedger
                    (ShopkeeperId,EntryType,RecipientType,Amount,SourceType,SourceId,ProductCode)
                VALUES(@ShopkeeperId,N''Debit'',N''Shopkeeper'',@Required,N''Sale'',@SaleId,N'''');
            END
        END');

        EXEC(N'
        CREATE OR ALTER TRIGGER dbo.tr_CustomerOrders_Distribute
        ON dbo.tbl_CustomerOrders
        AFTER UPDATE
        AS
        BEGIN
            SET NOCOUNT ON;
            DECLARE @OrderId INT, @ShopkeeperId INT, @CustomerUserId INT,
                    @AgentUserId INT, @FieldForceUserId INT, @Required DECIMAL(18,2);
            SELECT TOP(1) @OrderId=i.Id,@ShopkeeperId=i.ShopkeeperId,@CustomerUserId=i.CustomerUserId
            FROM inserted i JOIN deleted d ON d.Id=i.Id
            WHERE d.Status=N''Pending'' AND i.Status=N''Approved'';
            IF @OrderId IS NULL RETURN;

            SELECT @FieldForceUserId=fo.Id,@AgentUserId=fo.ParentUserId FROM dbo.tbl_Shopkeepers sh
            JOIN dbo.tbl_Users fo ON fo.Id=sh.FieldOfficerUserId WHERE sh.Id=@ShopkeeperId;
            SELECT @Required=COALESCE(SUM(ROUND(d.Quantity*
                CASE WHEN d.UnitPrice > product.PurchasePrice THEN d.UnitPrice - product.PurchasePrice ELSE 0 END*
                (cp.CompanyPercentage+
                 CASE WHEN @AgentUserId IS NULL THEN 0 ELSE cp.AgentPercentage END+
                 CASE WHEN @FieldForceUserId IS NULL THEN 0 ELSE cp.FieldForcePercentage END+
                 cp.CustomerPercentage)/100.0,2)),0)
            FROM dbo.tbl_CustomerOrderDetails d
            JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=d.Sku AND cp.IsActive=1
            JOIN dbo.tbl_Products product ON product.ShopkeeperId=@ShopkeeperId AND product.Sku=d.Sku
            WHERE d.OrderMasterId=@OrderId;

            IF @Required > 0
            BEGIN
                UPDATE dbo.tbl_ShopkeeperWallets WITH (UPDLOCK,HOLDLOCK)
                SET Balance=Balance-@Required,
                    WithdrawableBalance=CASE WHEN WithdrawableBalance>=@Required THEN WithdrawableBalance-@Required ELSE 0 END,
                    UpdatedAt=SYSUTCDATETIME()
                WHERE ShopkeeperId=@ShopkeeperId AND Balance>=@Required;
                IF @@ROWCOUNT=0 THROW 51110,N''Insufficient shopkeeper wallet balance for product distribution.'',1;

                ;WITH Entries AS (
                    SELECT cp.CreatedByUserId UserId,N''Company'' RecipientType,d.Sku ProductCode,
                        ROUND(d.Quantity*CASE WHEN d.UnitPrice > product.PurchasePrice THEN d.UnitPrice - product.PurchasePrice ELSE 0 END*cp.CompanyPercentage/100.0,2) Amount
                    FROM dbo.tbl_CustomerOrderDetails d JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=d.Sku AND cp.IsActive=1
                    JOIN dbo.tbl_Products product ON product.ShopkeeperId=@ShopkeeperId AND product.Sku=d.Sku
                    WHERE d.OrderMasterId=@OrderId
                    UNION ALL
                    SELECT @AgentUserId,N''Agent'',d.Sku,ROUND(d.Quantity*CASE WHEN d.UnitPrice > product.PurchasePrice THEN d.UnitPrice - product.PurchasePrice ELSE 0 END*cp.AgentPercentage/100.0,2)
                    FROM dbo.tbl_CustomerOrderDetails d JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=d.Sku AND cp.IsActive=1
                    JOIN dbo.tbl_Products product ON product.ShopkeeperId=@ShopkeeperId AND product.Sku=d.Sku
                    WHERE d.OrderMasterId=@OrderId AND @AgentUserId IS NOT NULL
                    UNION ALL
                    SELECT @FieldForceUserId,N''FieldForce'',d.Sku,ROUND(d.Quantity*CASE WHEN d.UnitPrice > product.PurchasePrice THEN d.UnitPrice - product.PurchasePrice ELSE 0 END*cp.FieldForcePercentage/100.0,2)
                    FROM dbo.tbl_CustomerOrderDetails d JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=d.Sku AND cp.IsActive=1
                    JOIN dbo.tbl_Products product ON product.ShopkeeperId=@ShopkeeperId AND product.Sku=d.Sku
                    WHERE d.OrderMasterId=@OrderId AND @FieldForceUserId IS NOT NULL
                    UNION ALL
                    SELECT @CustomerUserId,N''Customer'',d.Sku,ROUND(d.Quantity*CASE WHEN d.UnitPrice > product.PurchasePrice THEN d.UnitPrice - product.PurchasePrice ELSE 0 END*cp.CustomerPercentage/100.0,2)
                    FROM dbo.tbl_CustomerOrderDetails d JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=d.Sku AND cp.IsActive=1
                    JOIN dbo.tbl_Products product ON product.ShopkeeperId=@ShopkeeperId AND product.Sku=d.Sku
                    WHERE d.OrderMasterId=@OrderId
                )
                SELECT * INTO #Entries FROM Entries WHERE Amount>0 AND UserId IS NOT NULL;
                MERGE dbo.tbl_UserWallets t USING
                    (SELECT UserId,SUM(Amount) Amount FROM #Entries GROUP BY UserId) s ON t.UserId=s.UserId
                WHEN MATCHED THEN UPDATE SET Balance=t.Balance+s.Amount,UpdatedAt=SYSUTCDATETIME()
                WHEN NOT MATCHED THEN INSERT(UserId,Balance) VALUES(s.UserId,s.Amount);
                INSERT dbo.tbl_DistributionLedger
                    (UserId,ShopkeeperId,EntryType,RecipientType,Amount,SourceType,SourceId,ProductCode)
                SELECT UserId,@ShopkeeperId,N''Credit'',RecipientType,Amount,N''Order'',@OrderId,ProductCode FROM #Entries;
                INSERT dbo.tbl_DistributionLedger
                    (ShopkeeperId,EntryType,RecipientType,Amount,SourceType,SourceId,ProductCode)
                VALUES(@ShopkeeperId,N''Debit'',N''Shopkeeper'',@Required,N''Order'',@OrderId,N'''');
            END
        END');

        EXEC(N'
        CREATE OR ALTER PROCEDURE dbo.sp_CustomerProduct_List
        AS
        BEGIN
            SET NOCOUNT ON;

            SELECT
                Id,
                Name,
                Sku,
                Category,
                UnitPrice
            FROM dbo.tbl_CustomerOrderProducts
            WHERE IsActive = 1
            ORDER BY Name;
        END');
        """;
}
