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

    public IReadOnlyList<CustomerProductOptionViewModel> GetProducts()
    {
        distributionStore.SyncCustomerCatalog();
        using var connection = CreateConnection();
        using var command = new SqlCommand("""
            SELECT
                catalog.Id,
                catalog.Name,
                catalog.Sku,
                catalog.Category,
                catalog.UnitPrice,
                inventory.ShopkeeperId,
                COALESCE(
                    NULLIF(LTRIM(RTRIM(inventory.ImageUrl)), N''),
                    NULLIF(LTRIM(RTRIM(catalog.ImageUrl)), N''),
                    companyProduct.ImageUrl
                ) AS ImageUrl
            FROM dbo.tbl_CustomerOrderProducts AS catalog
            INNER JOIN dbo.tbl_Products AS inventory
                ON inventory.IsActive = 1
               AND inventory.StockQuantity > 0
               AND (
                    inventory.Sku = catalog.Sku
                    OR catalog.Sku = CONCAT(N'SP', inventory.ShopkeeperId, N'-', inventory.Sku)
               )
            LEFT JOIN dbo.tbl_CompanyProducts AS companyProduct
                ON companyProduct.ProductCode = catalog.Sku
            WHERE catalog.IsActive = 1
            ORDER BY catalog.Name, inventory.ShopkeeperId;
            """, connection);
        var products = new Dictionary<int, CustomerProductCatalogBuilder>();

        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            var id = reader.GetInt32(reader.GetOrdinal("Id"));
            if (!products.TryGetValue(id, out var product))
            {
                product = new CustomerProductCatalogBuilder
                {
                    Id = id,
                    Name = reader.GetString(reader.GetOrdinal("Name")),
                    Sku = reader.GetString(reader.GetOrdinal("Sku")),
                    Category = reader.GetString(reader.GetOrdinal("Category")),
                    UnitPrice = reader.GetDecimal(reader.GetOrdinal("UnitPrice"))
                };
                products[id] = product;
            }

            product.ShopkeeperIds.Add(reader.GetInt32(reader.GetOrdinal("ShopkeeperId")));
            if (string.IsNullOrWhiteSpace(product.ImageUrl)
                && !reader.IsDBNull(reader.GetOrdinal("ImageUrl")))
            {
                product.ImageUrl = reader.GetString(reader.GetOrdinal("ImageUrl"));
            }
        }

        return products.Values
            .Select(product => new CustomerProductOptionViewModel
            {
                Id = product.Id,
                Name = product.Name,
                Sku = product.Sku,
                Category = product.Category,
                UnitPrice = product.UnitPrice,
                ImageUrl = product.ImageUrl,
                AvailableShopkeeperIds = product.ShopkeeperIds.OrderBy(id => id).ToArray()
            })
            .ToList();
    }

    public IReadOnlyList<CustomerOrderMaster> GetOrdersByCustomer(int customerId)
    {
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
        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_CustomerOrder_ListByShopkeeper");
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);

        connection.Open();
        using var reader = command.ExecuteReader();
        return ReadOrders(reader);
    }

    public void UpdateOrderStatus(int shopkeeperId, int orderId, string status)
    {
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
        var requestedProductIds = input.Items
            .Where(item => item.ProductId is not null && item.Quantity is > 0)
            .Select(item => item.ProductId!.Value)
            .Distinct()
            .ToArray();
        if (requestedProductIds.Length == 0)
        {
            throw new InvalidOperationException("Select at least one product before placing the order.");
        }

        var shopProductIds = GetProducts()
            .Where(product => product.AvailableShopkeeperIds.Contains(shopkeeper.Id))
            .Select(product => product.Id)
            .ToHashSet();
        if (requestedProductIds.Any(productId => !shopProductIds.Contains(productId)))
        {
            throw new InvalidOperationException(
                "One or more selected products are not available from this shopkeeper.");
        }

        using var connection = CreateConnection();
        using var command = CreateCommand(connection, "dbo.sp_CustomerOrder_Create");
        command.Parameters.AddWithValue("@CustomerUserId", customerId);
        command.Parameters.AddWithValue("@CustomerName", customerName.Trim());
        command.Parameters.AddWithValue("@CustomerPhone", customerPhone.Trim());
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeper.Id);
        command.Parameters.AddWithValue("@CustomerLatitude", (object?)input.CustomerLatitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@CustomerLongitude", (object?)input.CustomerLongitude ?? DBNull.Value);
        command.Parameters.AddWithValue("@Remarks", string.IsNullOrWhiteSpace(input.Remarks) ? DBNull.Value : input.Remarks.Trim());

        var itemsParameter = command.Parameters.Add("@Items", SqlDbType.Structured);
        itemsParameter.TypeName = "dbo.CustomerOrderDetailInput";
        itemsParameter.Value = BuildItemsTable(input.Items);

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

    private static DataTable BuildItemsTable(IEnumerable<CustomerOrderItemInputModel> items)
    {
        var table = new DataTable();
        table.Columns.Add("ProductId", typeof(int));
        table.Columns.Add("Quantity", typeof(int));

        foreach (var item in items.Where(item => item.ProductId is not null && item.Quantity is > 0))
        {
            table.Rows.Add(item.ProductId!.Value, item.Quantity!.Value);
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
                Remarks = reader.IsDBNull(reader.GetOrdinal("Remarks")) ? null : reader.GetString(reader.GetOrdinal("Remarks"))
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
                UnitPrice = reader.GetDecimal(reader.GetOrdinal("UnitPrice"))
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
        public string Status { get; init; } = "";
        public string? Remarks { get; init; }
    }

    private sealed class CustomerProductCatalogBuilder
    {
        public int Id { get; init; }
        public string Name { get; init; } = "";
        public string Sku { get; init; } = "";
        public string Category { get; init; } = "";
        public decimal UnitPrice { get; init; }
        public string? ImageUrl { get; set; }
        public HashSet<int> ShopkeeperIds { get; } = [];
    }
}
