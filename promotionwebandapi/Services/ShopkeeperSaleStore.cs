using Microsoft.Data.SqlClient;
using PromotionWeb.Models;
using System.Data;
using System.Text.Json;

namespace PromotionWeb.Services;

public sealed class ShopkeeperSaleStore(
    IConfiguration configuration,
    ProductDistributionStore distributionStore)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");
    private static readonly object SaleProcedureLock = new();
    private static bool _saleProcedureReady;
    private static readonly object PendingPaymentSchemaLock = new();
    private static bool _pendingPaymentSchemaReady;

    public (bool CurrentMonthPaid, bool NextMonthPaid) GetSubscriptionStatus(int shopkeeperId, string currentMonthYear, string nextMonthYear)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("dbo.sp_ShopkeeperSubscription_Check", connection);
        command.CommandType = CommandType.StoredProcedure;
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@CurrentMonthYear", currentMonthYear);
        command.Parameters.AddWithValue("@NextMonthYear", nextMonthYear);

        connection.Open();
        using var reader = command.ExecuteReader();
        if (reader.Read())
        {
            return (reader.GetBoolean(0), reader.GetBoolean(1));
        }
        return (false, false);
    }

    public void MarkSubscriptionPaid(int shopkeeperId, string monthYear, decimal amount, string transactionId)
    {
        const string sql = """
            IF NOT EXISTS (SELECT 1 FROM dbo.tbl_ShopkeeperSubscriptions WHERE ShopkeeperId = @ShopkeeperId AND MonthYear = @MonthYear)
            BEGIN
                INSERT INTO dbo.tbl_ShopkeeperSubscriptions (ShopkeeperId, MonthYear, Amount, IsPaid, TransactionId, PaidAt)
                VALUES (@ShopkeeperId, @MonthYear, @Amount, 1, @TransactionId, SYSUTCDATETIME());
            END
            ELSE
            BEGIN
                UPDATE dbo.tbl_ShopkeeperSubscriptions
                SET IsPaid = 1, TransactionId = @TransactionId, PaidAt = SYSUTCDATETIME(), Amount = @Amount
                WHERE ShopkeeperId = @ShopkeeperId AND MonthYear = @MonthYear;
            END
            """;

        using var connection = new SqlConnection(_connectionString);
        using var command = CreateCommand(connection, sql);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@MonthYear", monthYear);
        command.Parameters.AddWithValue("@Amount", amount);
        command.Parameters.AddWithValue("@TransactionId", (object?)transactionId ?? DBNull.Value);

        connection.Open();
        command.ExecuteNonQuery();
    }

    public void AddProduct(int shopkeeperId, ProductInputModel input)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = CreateCommand(connection, "dbo.sp_Product_Add");
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@Name", input.Name.Trim());
        command.Parameters.AddWithValue("@Sku", input.Sku.Trim().ToUpper());
        command.Parameters.AddWithValue("@Category", input.Category.Trim());
        command.Parameters.AddWithValue("@UnitPrice", input.UnitPrice);
        command.Parameters.AddWithValue("@StockQuantity", input.StockQuantity);
        command.Parameters.AddWithValue("@CommissionPercentage", 0m);
        command.Parameters.AddWithValue("@ImageUrl", (object?)input.ImageUrl ?? DBNull.Value);

        try
        {
            connection.Open();
            command.ExecuteNonQuery();
        }
        catch (SqlException ex) when (ex.Number is 51010)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    public void RestockProduct(int shopkeeperId, int productId, int addQuantity, decimal? newPrice)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_Products
            SET StockQuantity = StockQuantity + @AddQuantity,
                UnitPrice = COALESCE(@NewPrice, UnitPrice)
            WHERE Id = @ProductId AND ShopkeeperId = @ShopkeeperId;
            """, connection);
        command.Parameters.AddWithValue("@AddQuantity", addQuantity);
        command.Parameters.AddWithValue("@NewPrice", (object?)newPrice ?? DBNull.Value);
        command.Parameters.AddWithValue("@ProductId", productId);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);

        connection.Open();
        command.ExecuteNonQuery();
    }

    public IReadOnlyList<ShopkeeperProductViewModel> GetProducts(int shopkeeperId)
    {
        distributionStore.SyncCatalogForShop(shopkeeperId);
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var command = new SqlCommand("""
            SELECT p.Id, p.Name, p.Sku, p.Category, p.UnitPrice, p.PurchasePrice, p.StockQuantity,
                   COALESCE(NULLIF(LTRIM(RTRIM(p.ImageUrl)), N''), cp.ImageUrl) AS ImageUrl,
                   COALESCE(cp.ShopkeeperPercentage, 100) AS ShopkeeperPercentage,
                   COALESCE(cp.CompanyPercentage, 0) AS CompanyPercentage,
                   COALESCE(cp.AgentPercentage, 0) AS AgentPercentage,
                   COALESCE(cp.FieldForcePercentage, 0) AS FieldForcePercentage,
                   COALESCE(cp.CustomerPercentage, 0) AS CustomerPercentage
            FROM dbo.tbl_Products p
            LEFT JOIN dbo.tbl_CompanyProducts cp
                ON cp.ProductCode = p.Sku
            WHERE p.ShopkeeperId = @ShopkeeperId
              AND p.IsActive = 1
              AND (
                  cp.Id IS NULL
                  OR EXISTS (
                      SELECT 1
                      FROM dbo.tbl_ShopkeeperProductSelections choice
                      WHERE choice.ShopkeeperId = @ShopkeeperId
                        AND choice.CompanyProductId = cp.Id
                  )
              )
            ORDER BY p.Name, p.Id;
            """, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        using var reader = command.ExecuteReader();
        var products = new List<ShopkeeperProductViewModel>();
        while (reader.Read())
        {
            products.Add(new ShopkeeperProductViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Sku = reader.GetString(reader.GetOrdinal("Sku")),
                Category = reader.GetString(reader.GetOrdinal("Category")),
                UnitPrice = reader.GetDecimal(reader.GetOrdinal("UnitPrice")),
                PurchasePrice = reader.GetDecimal(reader.GetOrdinal("PurchasePrice")),
                StockQuantity = reader.GetInt32(reader.GetOrdinal("StockQuantity")),
                ShopkeeperPercentage = reader.GetDecimal(reader.GetOrdinal("ShopkeeperPercentage")),
                CompanyPercentage = reader.GetDecimal(reader.GetOrdinal("CompanyPercentage")),
                AgentPercentage = reader.GetDecimal(reader.GetOrdinal("AgentPercentage")),
                FieldForcePercentage = reader.GetDecimal(reader.GetOrdinal("FieldForcePercentage")),
                CustomerPercentage = reader.GetDecimal(reader.GetOrdinal("CustomerPercentage")),
                ImageUrl = reader.IsDBNull(reader.GetOrdinal("ImageUrl")) ? null : reader.GetString(reader.GetOrdinal("ImageUrl"))
            });
        }

        return products;
    }

    public IReadOnlyList<ShopkeeperWalletDeductionLogViewModel> GetWalletDeductionLogs(int shopkeeperId)
    {
        const string sql = """
            SELECT 
                l.Id,
                l.SaleId,
                s.InvoiceNo,
                l.ProductId,
                p.Name AS ProductName,
                l.AmountDeducted,
                l.CreatedAt
            FROM dbo.tbl_ShopkeeperWalletDeductionLogs AS l
            INNER JOIN dbo.tbl_Sales AS s ON s.Id = l.SaleId
            INNER JOIN dbo.tbl_Products AS p ON p.Id = l.ProductId
            WHERE l.ShopkeeperId = @ShopkeeperId
            ORDER BY l.Id DESC;
            """;

        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);

        connection.Open();
        using var reader = command.ExecuteReader();
        var logs = new List<ShopkeeperWalletDeductionLogViewModel>();
        while (reader.Read())
        {
            logs.Add(new ShopkeeperWalletDeductionLogViewModel
            {
                Id = reader.GetInt32(0),
                SaleId = reader.GetInt32(1),
                InvoiceNo = reader.GetString(2),
                ProductId = reader.GetInt32(3),
                ProductName = reader.GetString(4),
                AmountDeducted = reader.GetDecimal(5),
                CreatedAt = reader.GetDateTime(6)
            });
        }
        return logs;
    }

    public IReadOnlyList<ShopkeeperTransactionViewModel> GetTransactions(int shopkeeperId)
    {
        const string sql = """
            SELECT
                s.Id,
                s.InvoiceNo,
                c.Name AS CustomerName,
                c.Phone AS CustomerPhone,
                s.GrossAmount,
                s.CashbackAmount,
                s.SystemCommission,
                s.PaymentMethod,
                s.SoldAt,
                s.Status
            FROM dbo.tbl_Sales AS s
            INNER JOIN dbo.tbl_Customers AS c ON c.Id = s.CustomerId
            WHERE s.ShopkeeperId = @ShopkeeperId
            ORDER BY s.SoldAt DESC, s.Id DESC;

            SELECT
                d.SaleId,
                p.Name AS ProductName,
                d.Quantity,
                d.UnitPrice
            FROM dbo.tbl_SaleDetails AS d
            INNER JOIN dbo.tbl_Sales AS s ON s.Id = d.SaleId
            INNER JOIN dbo.tbl_Products AS p ON p.Id = d.ProductId
            WHERE s.ShopkeeperId = @ShopkeeperId
            ORDER BY d.SaleId DESC, d.Id;
            """;

        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);

        connection.Open();
        using var reader = command.ExecuteReader();

        var sales = new List<SaleHeader>();
        while (reader.Read())
        {
            sales.Add(new SaleHeader
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                InvoiceNo = reader.GetString(reader.GetOrdinal("InvoiceNo")),
                CustomerName = reader.GetString(reader.GetOrdinal("CustomerName")),
                CustomerPhone = reader.GetString(reader.GetOrdinal("CustomerPhone")),
                SaleAmount = reader.GetDecimal(reader.GetOrdinal("GrossAmount")),
                CashbackAmount = reader.GetDecimal(reader.GetOrdinal("CashbackAmount")),
                SystemCommission = reader.GetDecimal(reader.GetOrdinal("SystemCommission")),
                PaymentMethod = reader.GetString(reader.GetOrdinal("PaymentMethod")),
                TransactionAt = reader.GetDateTime(reader.GetOrdinal("SoldAt")),
                Status = reader.GetString(reader.GetOrdinal("Status"))
            });
        }

        reader.NextResult();
        var itemsBySale = new Dictionary<int, List<ShopkeeperTransactionItemViewModel>>();
        while (reader.Read())
        {
            var saleId = reader.GetInt32(reader.GetOrdinal("SaleId"));
            if (!itemsBySale.TryGetValue(saleId, out var items))
            {
                items = [];
                itemsBySale[saleId] = items;
            }

            items.Add(new ShopkeeperTransactionItemViewModel
            {
                ProductName = reader.GetString(reader.GetOrdinal("ProductName")),
                Quantity = reader.GetInt32(reader.GetOrdinal("Quantity")),
                UnitPrice = reader.GetDecimal(reader.GetOrdinal("UnitPrice"))
            });
        }

        return sales
            .Select(sale => new ShopkeeperTransactionViewModel
            {
                Id = sale.Id,
                InvoiceNo = sale.InvoiceNo,
                CustomerName = sale.CustomerName,
                CustomerPhone = sale.CustomerPhone,
                SaleAmount = sale.SaleAmount,
                CashbackAmount = sale.CashbackAmount,
                SystemCommission = sale.SystemCommission,
                PaymentMethod = sale.PaymentMethod,
                TransactionAt = sale.TransactionAt,
                Status = sale.Status,
                Items = itemsBySale.GetValueOrDefault(sale.Id, [])
            })
            .ToList();
    }

    public ShopkeeperSaleResult CreateSale(int shopkeeperId, ShopkeeperSaleInputModel input)
    {
        distributionStore.EnsureSchema();
        EnsureSaleProcedure();
        var products = GetProducts(shopkeeperId).ToDictionary(product => product.Id);
        foreach (var item in input.Items)
        {
            if (!products.ContainsKey(item.ProductId))
            {
                throw new InvalidOperationException("নির্বাচিত product পাওয়া যায়নি।");
            }

        }

        using var connection = new SqlConnection(_connectionString);
        using var command = CreateCommand(connection, "dbo.sp_Sale_Create");
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@CustomerName", input.CustomerName.Trim());
        command.Parameters.AddWithValue("@CustomerPhone", input.CustomerPhone.Trim());
        command.Parameters.AddWithValue("@PaymentMethod", input.PaymentMethod.Trim());

        var itemsParameter = command.Parameters.Add("@Items", SqlDbType.Structured);
        itemsParameter.TypeName = "dbo.SaleDetailInput";
        itemsParameter.Value = BuildItemsTable(input.Items, products);

        try
        {
            connection.Open();
            using var reader = command.ExecuteReader();
            if (!reader.Read())
            {
                throw new InvalidOperationException("Sale save করা যায়নি।");
            }

            return new ShopkeeperSaleResult
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                InvoiceNo = reader.GetString(reader.GetOrdinal("InvoiceNo")),
                GrossAmount = reader.GetDecimal(reader.GetOrdinal("GrossAmount")),
                CashbackAmount = reader.GetDecimal(reader.GetOrdinal("CashbackAmount")),
                SystemCommission = reader.GetDecimal(reader.GetOrdinal("SystemCommission"))
            };
        }
        catch (SqlException ex) when (ex.Number is 51010 or 51011 or 51012 or 51013 or 51014 or 51110)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    public decimal CalculateSaleTotal(int shopkeeperId, ShopkeeperSaleInputModel input)
    {
        var products = GetProducts(shopkeeperId).ToDictionary(x => x.Id);
        decimal total = 0;
        decimal maximumCommission = 0;
        foreach (var item in input.Items)
        {
            if (!products.TryGetValue(item.ProductId, out var product) || item.Quantity <= 0)
                throw new InvalidOperationException("Invalid product details.");
            total += product.UnitPrice * item.Quantity;
            maximumCommission += Math.Max(0, product.UnitPrice - product.PurchasePrice)
                * item.Quantity
                * product.TotalCommissionPercentage / 100m;
        }
        if (distributionStore.GetShopWalletBalance(shopkeeperId) < Math.Round(maximumCommission,2))
            throw new InvalidOperationException("Insufficient wallet balance for product commission.");
        return Math.Round(total, 2);
    }

    public void CreatePendingPosPayment(string transactionId, int shopkeeperId, decimal amount, ShopkeeperSaleInputModel input)
    {
        EnsurePendingPaymentSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            INSERT dbo.tbl_ShopkeeperPosPayments(TransactionId,ShopkeeperId,Amount,SalePayload)
            VALUES(@TransactionId,@ShopkeeperId,@Amount,@Payload);
            """, connection);
        command.Parameters.AddWithValue("@TransactionId",transactionId); command.Parameters.AddWithValue("@ShopkeeperId",shopkeeperId);
        command.Parameters.AddWithValue("@Amount",amount); command.Parameters.AddWithValue("@Payload",JsonSerializer.Serialize(input));
        connection.Open(); command.ExecuteNonQuery();
    }

    public PendingPosPayment? ClaimPendingPosPayment(string transactionId, decimal verifiedAmount)
    {
        EnsurePendingPaymentSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_ShopkeeperPosPayments WITH(UPDLOCK,ROWLOCK)
            SET Status=N'Processing'
            OUTPUT INSERTED.TransactionId,INSERTED.ShopkeeperId,INSERTED.Amount,INSERTED.SalePayload
            WHERE TransactionId=@TransactionId AND Status=N'Pending' AND Amount=@Amount;
            """, connection);
        command.Parameters.AddWithValue("@TransactionId",transactionId); command.Parameters.AddWithValue("@Amount",verifiedAmount);
        connection.Open(); using var reader=command.ExecuteReader();
        if (!reader.Read()) return null;
        return new PendingPosPayment { TransactionId=reader.GetString(0),ShopkeeperId=reader.GetInt32(1),Amount=reader.GetDecimal(2),
            Sale=JsonSerializer.Deserialize<ShopkeeperSaleInputModel>(reader.GetString(3)) ?? new() };
    }

    public void CompletePendingPosPayment(string transactionId, int saleId, bool success)
    {
        EnsurePendingPaymentSchema();
        using var connection=new SqlConnection(_connectionString);
        using var command=new SqlCommand("""
            UPDATE dbo.tbl_ShopkeeperPosPayments SET Status=@Status,SaleId=@SaleId,
                PaidAt=CASE WHEN @Status=N'Paid' THEN SYSUTCDATETIME() ELSE PaidAt END
            WHERE TransactionId=@TransactionId AND Status=N'Processing';
            """,connection);
        command.Parameters.AddWithValue("@Status",success?"Paid":"Pending");
        command.Parameters.AddWithValue("@SaleId",success?saleId:DBNull.Value);
        command.Parameters.AddWithValue("@TransactionId",transactionId); connection.Open(); command.ExecuteNonQuery();
    }

    public void FailPendingPosPayment(string transactionId)
    {
        EnsurePendingPaymentSchema();
        using var connection=new SqlConnection(_connectionString);
        using var command=new SqlCommand("UPDATE dbo.tbl_ShopkeeperPosPayments SET Status=N'Failed' WHERE TransactionId=@Id AND Status=N'Pending';",connection);
        command.Parameters.AddWithValue("@Id",transactionId); connection.Open(); command.ExecuteNonQuery();
    }

    public string? GetPendingPosPaymentStatus(string transactionId)
    {
        EnsurePendingPaymentSchema();
        using var connection=new SqlConnection(_connectionString);
        using var command=new SqlCommand("SELECT Status FROM dbo.tbl_ShopkeeperPosPayments WHERE TransactionId=@Id;",connection);
        command.Parameters.AddWithValue("@Id",transactionId);connection.Open();return Convert.ToString(command.ExecuteScalar());
    }

    public decimal GetWalletBalance(int shopkeeperId) =>
        distributionStore.GetShopWalletBalance(shopkeeperId);

    private void EnsureSaleProcedure()
    {
        if (_saleProcedureReady) return;
        lock (SaleProcedureLock)
        {
            if (_saleProcedureReady) return;
            const string sql = """
                CREATE OR ALTER PROCEDURE dbo.sp_Sale_Create
                    @ShopkeeperId INT,
                    @CustomerName NVARCHAR(150),
                    @CustomerPhone NVARCHAR(20),
                    @PaymentMethod NVARCHAR(30),
                    @Items dbo.SaleDetailInput READONLY
                AS
                BEGIN
                    SET NOCOUNT ON;
                    SET XACT_ABORT ON;

                    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_Shopkeepers WHERE Id = @ShopkeeperId)
                        THROW 51010, N'Invalid shopkeeper.', 1;
                    IF NOT EXISTS (SELECT 1 FROM @Items)
                        THROW 51011, N'At least one product is required.', 1;
                    IF EXISTS (
                        SELECT 1 FROM @Items i
                        LEFT JOIN dbo.tbl_Products p
                          ON p.Id=i.ProductId AND p.ShopkeeperId=@ShopkeeperId AND p.IsActive=1
                        WHERE p.Id IS NULL OR i.Quantity<=0 OR i.UnitPrice<=0)
                        THROW 51012, N'Invalid product details.', 1;
                    DECLARE @CustomerId INT, @CustomerUserId INT, @SaleId INT,
                            @FieldForceUserId INT, @AgentUserId INT;
                    DECLARE @GrossAmount DECIMAL(18,2), @CashbackAmount DECIMAL(18,2),
                            @SystemCommission DECIMAL(18,2), @CurrentWalletBalance DECIMAL(18,2);

                    BEGIN TRANSACTION;

                    SELECT @CustomerId=Id FROM dbo.tbl_Customers WHERE Phone=@CustomerPhone;
                    IF @CustomerId IS NULL
                    BEGIN
                        INSERT dbo.tbl_Customers(Name,Phone) VALUES(@CustomerName,@CustomerPhone);
                        SET @CustomerId=CONVERT(INT,SCOPE_IDENTITY());
                    END
                    ELSE
                        UPDATE dbo.tbl_Customers SET Name=@CustomerName WHERE Id=@CustomerId;

                    SELECT @CustomerUserId=Id FROM dbo.tbl_Users
                    WHERE Phone=@CustomerPhone AND Role=N'Customer' AND IsActive=1;
                    SELECT @FieldForceUserId=fo.Id,@AgentUserId=fo.ParentUserId
                    FROM dbo.tbl_Shopkeepers sh
                    JOIN dbo.tbl_Users fo ON fo.Id=sh.FieldOfficerUserId
                    WHERE sh.Id=@ShopkeeperId;

                    SELECT @GrossAmount=SUM(i.Quantity*i.UnitPrice),
                           @CashbackAmount=COALESCE(SUM(ROUND(i.Quantity*
                               CASE WHEN i.UnitPrice>p.PurchasePrice THEN i.UnitPrice-p.PurchasePrice ELSE 0 END*
                               (CASE WHEN @CustomerUserId IS NULL THEN 0 ELSE cp.CustomerPercentage END)/100.0,2)),0),
                           @SystemCommission=COALESCE(SUM(ROUND(i.Quantity*
                               CASE WHEN i.UnitPrice>p.PurchasePrice THEN i.UnitPrice-p.PurchasePrice ELSE 0 END*
                               (cp.CompanyPercentage+
                                CASE WHEN @AgentUserId IS NULL THEN 0 ELSE cp.AgentPercentage END+
                                CASE WHEN @FieldForceUserId IS NULL THEN 0 ELSE cp.FieldForcePercentage END+
                                CASE WHEN @CustomerUserId IS NULL THEN 0 ELSE cp.CustomerPercentage END)/100.0,2)),0)
                    FROM @Items i
                    JOIN dbo.tbl_Products p ON p.Id=i.ProductId
                    LEFT JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=p.Sku AND cp.IsActive=1;

                    SELECT @CurrentWalletBalance=COALESCE(Balance,0)
                    FROM dbo.tbl_ShopkeeperWallets WITH(UPDLOCK,HOLDLOCK)
                    WHERE ShopkeeperId=@ShopkeeperId;
                    IF COALESCE(@CurrentWalletBalance,0)<@SystemCommission
                        THROW 51014, N'Insufficient wallet balance. Please add funds via SSL Commerz.', 1;

                    DECLARE @PaidAmount DECIMAL(18,2) = CASE WHEN @PaymentMethod = N'বকেয়া' THEN 0 ELSE @GrossAmount END;

                    INSERT dbo.tbl_Sales
                        (InvoiceNo,ShopkeeperId,CustomerId,PaymentMethod,GrossAmount,CashbackAmount,SystemCommission,Status,PaidAmount)
                    VALUES(N'TEMP',@ShopkeeperId,@CustomerId,@PaymentMethod,@GrossAmount,@CashbackAmount,@SystemCommission,N'Paid',@PaidAmount);
                    SET @SaleId=CONVERT(INT,SCOPE_IDENTITY());
                    UPDATE dbo.tbl_Sales SET InvoiceNo=CONCAT(N'INV',FORMAT(@SaleId+100000,N'000000')) WHERE Id=@SaleId;

                    -- The distribution trigger performs the single wallet debit and credits each recipient.
                    INSERT dbo.tbl_SaleDetails(SaleId,ProductId,Quantity,UnitPrice)
                    SELECT @SaleId,ProductId,Quantity,UnitPrice FROM @Items;

                    UPDATE p SET StockQuantity=CASE
                        WHEN p.StockQuantity>i.Quantity THEN p.StockQuantity-i.Quantity ELSE 0 END
                    FROM dbo.tbl_Products p JOIN @Items i ON i.ProductId=p.Id;

                    INSERT dbo.tbl_ShopkeeperWalletDeductionLogs
                        (ShopkeeperId,SaleId,ProductId,AmountDeducted)
                    SELECT @ShopkeeperId,@SaleId,i.ProductId,
                           ROUND(i.Quantity*
                               CASE WHEN i.UnitPrice>p.PurchasePrice THEN i.UnitPrice-p.PurchasePrice ELSE 0 END*
                               (COALESCE(cp.CompanyPercentage,0)+
                                CASE WHEN @AgentUserId IS NULL THEN 0 ELSE COALESCE(cp.AgentPercentage,0) END+
                                CASE WHEN @FieldForceUserId IS NULL THEN 0 ELSE COALESCE(cp.FieldForcePercentage,0) END+
                                CASE WHEN @CustomerUserId IS NULL THEN 0 ELSE COALESCE(cp.CustomerPercentage,0) END)/100.0,2)
                    FROM @Items i
                    JOIN dbo.tbl_Products p ON p.Id=i.ProductId
                    LEFT JOIN dbo.tbl_CompanyProducts cp ON cp.ProductCode=p.Sku AND cp.IsActive=1;

                    COMMIT TRANSACTION;

                    SELECT s.Id,s.InvoiceNo,c.Name CustomerName,c.Phone CustomerPhone,s.PaymentMethod,
                           s.GrossAmount,s.CashbackAmount,s.SystemCommission,s.Status,s.SoldAt
                    FROM dbo.tbl_Sales s JOIN dbo.tbl_Customers c ON c.Id=s.CustomerId
                    WHERE s.Id=@SaleId;
                END
                """;
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            connection.Open();
            command.ExecuteNonQuery();
            _saleProcedureReady = true;
        }
    }

    private void EnsurePendingPaymentSchema()
    {
        if (_pendingPaymentSchemaReady) return;
        lock(PendingPaymentSchemaLock)
        {
            if (_pendingPaymentSchemaReady) return;
            using var connection=new SqlConnection(_connectionString);
            using var command=new SqlCommand("""
                IF OBJECT_ID(N'dbo.tbl_ShopkeeperPosPayments',N'U') IS NULL
                CREATE TABLE dbo.tbl_ShopkeeperPosPayments(
                    Id INT IDENTITY(1,1) PRIMARY KEY,TransactionId NVARCHAR(50) NOT NULL UNIQUE,
                    ShopkeeperId INT NOT NULL,Amount DECIMAL(18,2) NOT NULL,SalePayload NVARCHAR(MAX) NOT NULL,
                    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_PosPayment_Status DEFAULT N'Pending',
                    SaleId INT NULL,CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_PosPayment_Created DEFAULT SYSUTCDATETIME(),PaidAt DATETIME2(0) NULL,
                    CONSTRAINT FK_PosPayment_Shop FOREIGN KEY(ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id));
                """,connection);
            connection.Open();command.ExecuteNonQuery();_pendingPaymentSchemaReady=true;
        }
    }

    public List<PromotionWeb.Models.ShopkeeperDueViewModel> GetShopkeeperDues(int shopkeeperId)
    {
        var dues = new List<PromotionWeb.Models.ShopkeeperDueViewModel>();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(@"
            SELECT s.Id, s.InvoiceNo, c.Id AS CustomerId, c.Name AS CustomerName, c.Phone AS CustomerPhone, 
                   s.GrossAmount, s.PaidAmount, s.DueAmount, s.SoldAt 
            FROM dbo.tbl_Sales s 
            JOIN dbo.tbl_Customers c ON c.Id = s.CustomerId
            WHERE s.ShopkeeperId = @ShopkeeperId AND s.DueAmount > 0
            ORDER BY s.SoldAt DESC", connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        
        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            dues.Add(new PromotionWeb.Models.ShopkeeperDueViewModel
            {
                SaleId = reader.GetInt32(0),
                InvoiceNo = reader.GetString(1),
                CustomerId = reader.GetInt32(2),
                CustomerName = reader.GetString(3),
                CustomerPhone = reader.GetString(4),
                GrossAmount = reader.GetDecimal(5),
                PaidAmount = reader.GetDecimal(6),
                DueAmount = reader.GetDecimal(7),
                SoldAt = reader.GetDateTime(8)
            });
        }
        return dues;
    }

    public List<CustomerDueItemViewModel> GetCustomerDues(string customerPhone)
    {
        var dues = new List<CustomerDueItemViewModel>();
        if (string.IsNullOrWhiteSpace(customerPhone)) return dues;

        const string sql = """
            SELECT s.Id, s.InvoiceNo, sh.Id AS ShopkeeperId, sh.ShopName,
                   COALESCE(NULLIF(sh.Phone, N''), u.Phone, N'') AS ShopkeeperPhone, 
                   s.GrossAmount, s.PaidAmount, s.DueAmount, s.SoldAt, s.PaymentMethod
            FROM dbo.tbl_Sales s 
            INNER JOIN dbo.tbl_Customers c ON c.Id = s.CustomerId
            INNER JOIN dbo.tbl_Shopkeepers sh ON sh.Id = s.ShopkeeperId
            LEFT JOIN dbo.tbl_Users u ON u.Id = sh.UserId
            WHERE c.Phone = @Phone AND s.DueAmount > 0
            ORDER BY s.SoldAt DESC;

            SELECT d.SaleId, p.Name AS ProductName, d.Quantity, d.UnitPrice
            FROM dbo.tbl_SaleDetails d
            INNER JOIN dbo.tbl_Sales s ON s.Id = d.SaleId
            INNER JOIN dbo.tbl_Customers c ON c.Id = s.CustomerId
            INNER JOIN dbo.tbl_Products p ON p.Id = d.ProductId
            WHERE c.Phone = @Phone AND s.DueAmount > 0
            ORDER BY d.SaleId DESC, d.Id;
            """;

        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        command.Parameters.AddWithValue("@Phone", customerPhone.Trim());

        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            dues.Add(new CustomerDueItemViewModel
            {
                SaleId = reader.GetInt32(0),
                InvoiceNo = reader.GetString(1),
                ShopkeeperId = reader.GetInt32(2),
                ShopName = reader.GetString(3),
                ShopkeeperPhone = reader.GetString(4),
                GrossAmount = reader.GetDecimal(5),
                PaidAmount = reader.GetDecimal(6),
                DueAmount = reader.GetDecimal(7),
                SoldAt = reader.GetDateTime(8),
                PaymentMethod = reader.GetString(9),
                Items = []
            });
        }

        reader.NextResult();
        var itemsBySale = new Dictionary<int, List<ShopkeeperTransactionItemViewModel>>();
        while (reader.Read())
        {
            var saleId = reader.GetInt32(0);
            if (!itemsBySale.TryGetValue(saleId, out var items))
            {
                items = [];
                itemsBySale[saleId] = items;
            }
            items.Add(new ShopkeeperTransactionItemViewModel
            {
                ProductName = reader.GetString(1),
                Quantity = reader.GetInt32(2),
                UnitPrice = reader.GetDecimal(3)
            });
        }

        return dues.Select(due => new CustomerDueItemViewModel
        {
            SaleId = due.SaleId,
            InvoiceNo = due.InvoiceNo,
            ShopkeeperId = due.ShopkeeperId,
            ShopName = due.ShopName,
            ShopkeeperPhone = due.ShopkeeperPhone,
            GrossAmount = due.GrossAmount,
            PaidAmount = due.PaidAmount,
            DueAmount = due.DueAmount,
            SoldAt = due.SoldAt,
            PaymentMethod = due.PaymentMethod,
            Items = itemsBySale.GetValueOrDefault(due.SaleId, [])
        }).ToList();
    }

    public void PayDue(int shopkeeperId, int saleId, decimal amount, string paymentMethod)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("dbo.sp_Sale_PayDue", connection);
        command.CommandType = CommandType.StoredProcedure;
        command.Parameters.AddWithValue("@SaleId", saleId);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@Amount", amount);
        command.Parameters.AddWithValue("@PaymentMethod", paymentMethod);
        connection.Open();
        command.ExecuteNonQuery();
    }

    public List<PromotionWeb.Models.DailyReportViewModel> GetDailyReport(int shopkeeperId)
    {
        var reports = new List<PromotionWeb.Models.DailyReportViewModel>();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(@"
            WITH SalesData AS (
                SELECT CONVERT(DATE, SoldAt) AS Date, COUNT(Id) AS TotalSalesCount, SUM(GrossAmount) AS TotalSalesAmount,
                       SUM(CASE WHEN PaymentMethod != N'বকেয়া' THEN GrossAmount ELSE 0 END) AS CashAtSale
                FROM dbo.tbl_Sales
                WHERE ShopkeeperId = @ShopkeeperId
                GROUP BY CONVERT(DATE, SoldAt)
            ),
            PaymentsData AS (
                SELECT CONVERT(DATE, p.PaidAt) AS Date, SUM(p.Amount) AS TotalDueCollected
                FROM dbo.tbl_SalePayments p
                JOIN dbo.tbl_Sales s ON s.Id = p.SaleId
                WHERE s.ShopkeeperId = @ShopkeeperId
                GROUP BY CONVERT(DATE, p.PaidAt)
            ),
            AllDates AS (
                SELECT Date FROM SalesData
                UNION
                SELECT Date FROM PaymentsData
            )
            SELECT d.Date, 
                   ISNULL(s.TotalSalesCount, 0), 
                   ISNULL(s.TotalSalesAmount, 0), 
                   ISNULL(s.CashAtSale, 0), 
                   ISNULL(p.TotalDueCollected, 0)
            FROM AllDates d
            LEFT JOIN SalesData s ON s.Date = d.Date
            LEFT JOIN PaymentsData p ON p.Date = d.Date
            ORDER BY d.Date DESC", connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        
        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            var date = reader.GetDateTime(0);
            var cashAtSale = reader.GetDecimal(3);
            var dueCollected = reader.GetDecimal(4);
            reports.Add(new PromotionWeb.Models.DailyReportViewModel
            {
                Date = date,
                TotalSalesCount = reader.GetInt32(1),
                TotalSalesAmount = reader.GetDecimal(2),
                TotalCashCollected = cashAtSale + dueCollected,
                TotalDueCollected = dueCollected
            });
        }
        return reports;
    }

    private static DataTable BuildItemsTable(
        IEnumerable<ShopkeeperSaleItemInputModel> items,
        IReadOnlyDictionary<int, ShopkeeperProductViewModel> products)
    {
        var table = new DataTable();
        table.Columns.Add("ProductId", typeof(int));
        table.Columns.Add("Quantity", typeof(int));
        table.Columns.Add("UnitPrice", typeof(decimal));

        foreach (var item in items)
        {
            table.Rows.Add(item.ProductId, item.Quantity, products[item.ProductId].UnitPrice);
        }

        return table;
    }

    private static SqlCommand CreateCommand(SqlConnection connection, string procedureName) =>
        new(procedureName, connection) { CommandType = CommandType.StoredProcedure };

    private sealed class SaleHeader
    {
        public int Id { get; init; }
        public string InvoiceNo { get; init; } = "";
        public string CustomerName { get; init; } = "";
        public string CustomerPhone { get; init; } = "";
        public decimal SaleAmount { get; init; }
        public decimal CashbackAmount { get; init; }
        public decimal SystemCommission { get; init; }
        public string PaymentMethod { get; init; } = "";
        public DateTime TransactionAt { get; init; }
        public string Status { get; init; } = "";
    }
}
