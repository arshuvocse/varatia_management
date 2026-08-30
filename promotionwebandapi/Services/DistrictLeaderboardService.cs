using Microsoft.Data.SqlClient;

namespace PromotionWeb.Services;

public sealed class DistrictLeaderboardEntry
{
    public int Rank { get; init; }
    public string Name { get; init; } = "";
    public string? SecondaryLabel { get; init; }
    public decimal TotalAmount { get; init; }
    public int OrderCount { get; init; }
}

/// <summary>
/// Top-50-per-district leaderboards for the landing page: buyers ranked by total spend and
/// shopkeepers ranked by total sales, both scoped to a district and computed from Delivered orders.
/// A customer's district is taken from the shop they bought from (tbl_Shopkeepers.DistrictId),
/// since app customers don't have their own address/district recorded.
/// </summary>
public sealed class DistrictLeaderboardService(IConfiguration configuration)
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
            try
            {
                using var connection = new SqlConnection(_connectionString);
                connection.Open();

                using (var command = new SqlCommand("""
                    -- Bangladesh has 64 districts; only 14 were seeded originally. Fill in the rest
                    -- (idempotent: only inserts a division+name pair that isn't already present).
                    INSERT INTO dbo.tbl_Districts (DivisionId, Name)
                    SELECT d.Id, v.Name
                    FROM dbo.tbl_Divisions AS d
                    INNER JOIN (VALUES
                        (N'Dhaka', N'Faridpur'), (N'Dhaka', N'Gopalganj'), (N'Dhaka', N'Kishoreganj'), (N'Dhaka', N'Madaripur'),
                        (N'Dhaka', N'Manikganj'), (N'Dhaka', N'Munshiganj'), (N'Dhaka', N'Narsingdi'), (N'Dhaka', N'Rajbari'),
                        (N'Dhaka', N'Shariatpur'), (N'Dhaka', N'Tangail'),
                        (N'Chattogram', N'Bandarban'), (N'Chattogram', N'Brahmanbaria'), (N'Chattogram', N'Chandpur'),
                        (N'Chattogram', N'Feni'), (N'Chattogram', N'Khagrachhari'), (N'Chattogram', N'Lakshmipur'),
                        (N'Chattogram', N'Noakhali'), (N'Chattogram', N'Rangamati'),
                        (N'Rajshahi', N'Joypurhat'), (N'Rajshahi', N'Naogaon'), (N'Rajshahi', N'Natore'),
                        (N'Rajshahi', N'Chapai Nawabganj'), (N'Rajshahi', N'Pabna'), (N'Rajshahi', N'Sirajganj'),
                        (N'Khulna', N'Bagerhat'), (N'Khulna', N'Chuadanga'), (N'Khulna', N'Jhenaidah'), (N'Khulna', N'Kushtia'),
                        (N'Khulna', N'Magura'), (N'Khulna', N'Meherpur'), (N'Khulna', N'Narail'), (N'Khulna', N'Satkhira'),
                        (N'Barishal', N'Barguna'), (N'Barishal', N'Bhola'), (N'Barishal', N'Jhalokati'),
                        (N'Barishal', N'Patuakhali'), (N'Barishal', N'Pirojpur'),
                        (N'Sylhet', N'Habiganj'), (N'Sylhet', N'Moulvibazar'), (N'Sylhet', N'Sunamganj'),
                        (N'Rangpur', N'Dinajpur'), (N'Rangpur', N'Gaibandha'), (N'Rangpur', N'Kurigram'),
                        (N'Rangpur', N'Lalmonirhat'), (N'Rangpur', N'Nilphamari'), (N'Rangpur', N'Panchagarh'), (N'Rangpur', N'Thakurgaon'),
                        (N'Mymensingh', N'Jamalpur'), (N'Mymensingh', N'Netrokona'), (N'Mymensingh', N'Sherpur')
                    ) AS v(DivisionName, Name) ON v.DivisionName = d.Name
                    WHERE NOT EXISTS (
                        SELECT 1 FROM dbo.tbl_Districts existing
                        WHERE existing.DivisionId = d.Id AND existing.Name = v.Name
                    );
                    """, connection))
                {
                    command.ExecuteNonQuery();
                }

                using (var command = new SqlCommand("""
                    CREATE OR ALTER PROCEDURE dbo.sp_District_TopBuyers
                        @DistrictId INT
                    AS
                    BEGIN
                        SET NOCOUNT ON;

                        SELECT TOP (50)
                            CAST(RANK() OVER (ORDER BY SUM(o.TotalAmount - o.DiscountAmount) DESC) AS INT) AS Rank,
                            u.Id AS CustomerUserId,
                            u.Name AS CustomerName,
                            SUM(o.TotalAmount - o.DiscountAmount) AS TotalSpent,
                            COUNT(*) AS OrderCount
                        FROM dbo.tbl_CustomerOrders o
                        INNER JOIN dbo.tbl_Shopkeepers s ON s.Id = o.ShopkeeperId
                        INNER JOIN dbo.tbl_Users u ON u.Id = o.CustomerUserId
                        WHERE s.DistrictId = @DistrictId AND o.Status = N'Delivered'
                        GROUP BY u.Id, u.Name
                        ORDER BY TotalSpent DESC;
                    END
                    """, connection))
                {
                    command.ExecuteNonQuery();
                }

                using (var command = new SqlCommand("""
                    CREATE OR ALTER PROCEDURE dbo.sp_District_TopShopkeepers
                        @DistrictId INT
                    AS
                    BEGIN
                        SET NOCOUNT ON;

                        SELECT TOP (50)
                            CAST(RANK() OVER (ORDER BY SUM(o.TotalAmount - o.DiscountAmount) DESC) AS INT) AS Rank,
                            s.Id AS ShopkeeperId,
                            s.ShopName,
                            s.OwnerName,
                            SUM(o.TotalAmount - o.DiscountAmount) AS TotalSales,
                            COUNT(*) AS OrderCount
                        FROM dbo.tbl_CustomerOrders o
                        INNER JOIN dbo.tbl_Shopkeepers s ON s.Id = o.ShopkeeperId
                        WHERE s.DistrictId = @DistrictId AND o.Status = N'Delivered'
                        GROUP BY s.Id, s.ShopName, s.OwnerName
                        ORDER BY TotalSales DESC;
                    END
                    """, connection))
                {
                    command.ExecuteNonQuery();
                }

                _schemaReady = true;
            }
            catch
            {
                // Schema update failed, continue gracefully
            }
        }
    }

    public IReadOnlyList<DistrictLeaderboardEntry> GetTopBuyers(int districtId)
    {
        try
        {
            EnsureSchema();
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("dbo.sp_District_TopBuyers", connection)
            {
                CommandType = System.Data.CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@DistrictId", districtId);

            connection.Open();
            using var reader = command.ExecuteReader();
            var results = new List<DistrictLeaderboardEntry>();
            while (reader.Read())
            {
                results.Add(new DistrictLeaderboardEntry
                {
                    Rank = reader.GetInt32(reader.GetOrdinal("Rank")),
                    Name = reader.GetString(reader.GetOrdinal("CustomerName")),
                    TotalAmount = reader.GetDecimal(reader.GetOrdinal("TotalSpent")),
                    OrderCount = reader.GetInt32(reader.GetOrdinal("OrderCount"))
                });
            }

            return results;
        }
        catch
        {
            return Array.Empty<DistrictLeaderboardEntry>();
        }
    }

    public IReadOnlyList<DistrictLeaderboardEntry> GetTopShopkeepers(int districtId)
    {
        try
        {
            EnsureSchema();
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("dbo.sp_District_TopShopkeepers", connection)
            {
                CommandType = System.Data.CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@DistrictId", districtId);

            connection.Open();
            using var reader = command.ExecuteReader();
            var results = new List<DistrictLeaderboardEntry>();
            while (reader.Read())
            {
                results.Add(new DistrictLeaderboardEntry
                {
                    Rank = reader.GetInt32(reader.GetOrdinal("Rank")),
                    Name = reader.GetString(reader.GetOrdinal("ShopName")),
                    SecondaryLabel = reader.GetString(reader.GetOrdinal("OwnerName")),
                    TotalAmount = reader.GetDecimal(reader.GetOrdinal("TotalSales")),
                    OrderCount = reader.GetInt32(reader.GetOrdinal("OrderCount"))
                });
            }

            return results;
        }
        catch
        {
            return Array.Empty<DistrictLeaderboardEntry>();
        }
    }
}
