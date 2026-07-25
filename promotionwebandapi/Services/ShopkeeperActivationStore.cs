using Microsoft.Data.SqlClient;
using PromotionWeb.Models;

namespace PromotionWeb.Services;

public sealed class ShopkeeperActivationStore(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");
    private static readonly object SchemaLock = new();
    private static bool _schemaReady;

    public bool IsActivatedByUserId(int userId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT CONVERT(BIT, CASE WHEN EXISTS (
                SELECT 1
                FROM dbo.tbl_ShopkeeperActivationPayments payment
                INNER JOIN dbo.tbl_Shopkeepers shop ON shop.Id = payment.ShopkeeperId
                WHERE shop.UserId = @UserId AND payment.Status = N'Paid'
            ) THEN 1 ELSE 0 END);
            """, connection);
        command.Parameters.AddWithValue("@UserId", userId);
        connection.Open();
        return (bool)(command.ExecuteScalar() ?? false);
    }

    public bool IsActivated(int shopkeeperId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT CONVERT(BIT, CASE WHEN EXISTS (
                SELECT 1 FROM dbo.tbl_ShopkeeperActivationPayments
                WHERE ShopkeeperId = @ShopkeeperId AND Status = N'Paid'
            ) THEN 1 ELSE 0 END);
            """, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        connection.Open();
        return (bool)(command.ExecuteScalar() ?? false);
    }

    public ShopkeeperActivationPayment CreateAttempt(int shopkeeperId, string transactionId, decimal amount)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            INSERT INTO dbo.tbl_ShopkeeperActivationPayments
                (ShopkeeperId, TransactionId, Amount, Currency, Status)
            OUTPUT INSERTED.*
            VALUES (@ShopkeeperId, @TransactionId, @Amount, N'BDT', N'Pending');
            """, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@TransactionId", transactionId);
        command.Parameters.AddWithValue("@Amount", amount);
        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? Map(reader) : throw new InvalidOperationException("Payment attempt could not be created.");
    }

    public ShopkeeperActivationPayment? GetByTransactionId(string transactionId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT TOP (1) * FROM dbo.tbl_ShopkeeperActivationPayments
            WHERE TransactionId = @TransactionId;
            """, connection);
        command.Parameters.AddWithValue("@TransactionId", transactionId);
        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? Map(reader) : null;
    }

    public ShopkeeperActivationPayment? GetLatest(int shopkeeperId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT TOP (1) * FROM dbo.tbl_ShopkeeperActivationPayments
            WHERE ShopkeeperId = @ShopkeeperId
            ORDER BY CreatedAt DESC, Id DESC;
            """, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? Map(reader) : null;
    }

    public IReadOnlyList<CompanyShopkeeperPaymentViewModel> GetCompanyPayments(int limit = 1000)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT TOP (@Limit)
                payment.Id, payment.ShopkeeperId, shop.ShopName, shop.ShopCode,
                shop.OwnerName, shop.Phone, district.Name AS DistrictName,
                payment.TransactionId, payment.BankTransactionId, payment.CardType,
                payment.Amount, payment.Currency, payment.Status,
                payment.CreatedAt, payment.PaidAt
            FROM dbo.tbl_ShopkeeperActivationPayments payment
            INNER JOIN dbo.tbl_Shopkeepers shop ON shop.Id = payment.ShopkeeperId
            INNER JOIN dbo.tbl_Districts district ON district.Id = shop.DistrictId
            ORDER BY COALESCE(payment.PaidAt, payment.CreatedAt) DESC, payment.Id DESC;
            """, connection);
        command.Parameters.AddWithValue("@Limit", Math.Clamp(limit, 1, 5000));
        var payments = new List<CompanyShopkeeperPaymentViewModel>();
        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            payments.Add(new CompanyShopkeeperPaymentViewModel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                ShopkeeperId = reader.GetInt32(reader.GetOrdinal("ShopkeeperId")),
                ShopName = reader.GetString(reader.GetOrdinal("ShopName")),
                ShopCode = reader.GetString(reader.GetOrdinal("ShopCode")),
                OwnerName = reader.GetString(reader.GetOrdinal("OwnerName")),
                Phone = reader.GetString(reader.GetOrdinal("Phone")),
                DistrictName = reader.GetString(reader.GetOrdinal("DistrictName")),
                TransactionId = reader.GetString(reader.GetOrdinal("TransactionId")),
                BankTransactionId = NullableString(reader, "BankTransactionId"),
                CardType = NullableString(reader, "CardType"),
                Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                Currency = reader.GetString(reader.GetOrdinal("Currency")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt")),
                PaidAt = reader.IsDBNull(reader.GetOrdinal("PaidAt"))
                    ? null
                    : reader.GetDateTime(reader.GetOrdinal("PaidAt"))
            });
        }
        return payments;
    }

    public void SetSession(string transactionId, string? sessionKey, string rawResponse)
    {
        EnsureSchema();
        Execute("""
            UPDATE dbo.tbl_ShopkeeperActivationPayments
            SET SessionKey = @SessionKey, GatewayResponse = @Response
            WHERE TransactionId = @TransactionId AND Status = N'Pending';
            """, command =>
        {
            command.Parameters.AddWithValue("@SessionKey", (object?)sessionKey ?? DBNull.Value);
            command.Parameters.AddWithValue("@Response", rawResponse);
            command.Parameters.AddWithValue("@TransactionId", transactionId);
        });
    }

    public bool MarkPaid(ShopkeeperActivationPayment payment, SslCommerzValidationResult validation)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_ShopkeeperActivationPayments
            SET Status = N'Paid',
                ValidationId = @ValidationId,
                BankTransactionId = @BankTransactionId,
                CardType = @CardType,
                GatewayResponse = @Response,
                PaidAt = COALESCE(PaidAt, SYSUTCDATETIME())
            WHERE Id = @Id AND Status IN (N'Pending', N'Failed', N'Cancelled');
            SELECT CONVERT(BIT, CASE WHEN EXISTS (
                SELECT 1 FROM dbo.tbl_ShopkeeperActivationPayments
                WHERE Id = @Id AND Status = N'Paid'
            ) THEN 1 ELSE 0 END);
            """, connection);
        command.Parameters.AddWithValue("@ValidationId", (object?)validation.ValidationId ?? DBNull.Value);
        command.Parameters.AddWithValue("@BankTransactionId", (object?)validation.BankTransactionId ?? DBNull.Value);
        command.Parameters.AddWithValue("@CardType", (object?)validation.CardType ?? DBNull.Value);
        command.Parameters.AddWithValue("@Response", validation.RawResponse);
        command.Parameters.AddWithValue("@Id", payment.Id);
        connection.Open();
        return (bool)(command.ExecuteScalar() ?? false);
    }

    public void MarkStatus(string transactionId, string status, string? response = null)
    {
        if (status is not ("Failed" or "Cancelled")) return;
        EnsureSchema();
        Execute("""
            UPDATE dbo.tbl_ShopkeeperActivationPayments
            SET Status = @Status, GatewayResponse = COALESCE(@Response, GatewayResponse)
            WHERE TransactionId = @TransactionId AND Status <> N'Paid';
            """, command =>
        {
            command.Parameters.AddWithValue("@Status", status);
            command.Parameters.AddWithValue("@Response", (object?)response ?? DBNull.Value);
            command.Parameters.AddWithValue("@TransactionId", transactionId);
        });
    }

    private void EnsureSchema()
    {
        if (_schemaReady) return;
        lock (SchemaLock)
        {
            if (_schemaReady) return;
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("""
                IF OBJECT_ID(N'dbo.tbl_ShopkeeperActivationPayments', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.tbl_ShopkeeperActivationPayments
                    (
                        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ShopkeeperActivationPayments PRIMARY KEY,
                        ShopkeeperId INT NOT NULL,
                        TransactionId NVARCHAR(30) NOT NULL,
                        SessionKey NVARCHAR(100) NULL,
                        Amount DECIMAL(10,2) NOT NULL,
                        Currency NVARCHAR(3) NOT NULL,
                        Status NVARCHAR(20) NOT NULL,
                        ValidationId NVARCHAR(100) NULL,
                        BankTransactionId NVARCHAR(100) NULL,
                        CardType NVARCHAR(100) NULL,
                        GatewayResponse NVARCHAR(MAX) NULL,
                        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_ShopActivation_CreatedAt DEFAULT SYSUTCDATETIME(),
                        PaidAt DATETIME2(0) NULL,
                        CONSTRAINT FK_ShopActivation_Shopkeeper FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
                        CONSTRAINT UQ_ShopActivation_TransactionId UNIQUE (TransactionId)
                    );
                    CREATE INDEX IX_ShopActivation_Shopkeeper_Status
                        ON dbo.tbl_ShopkeeperActivationPayments (ShopkeeperId, Status);
                END;
                """, connection);
            connection.Open();
            command.ExecuteNonQuery();
            _schemaReady = true;
        }
    }

    private void Execute(string sql, Action<SqlCommand> configure)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(sql, connection);
        configure(command);
        connection.Open();
        command.ExecuteNonQuery();
    }

    private static ShopkeeperActivationPayment Map(SqlDataReader reader) => new()
    {
        Id = reader.GetInt32(reader.GetOrdinal("Id")),
        ShopkeeperId = reader.GetInt32(reader.GetOrdinal("ShopkeeperId")),
        TransactionId = reader.GetString(reader.GetOrdinal("TransactionId")),
        SessionKey = NullableString(reader, "SessionKey"),
        Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
        Currency = reader.GetString(reader.GetOrdinal("Currency")),
        Status = reader.GetString(reader.GetOrdinal("Status")),
        ValidationId = NullableString(reader, "ValidationId"),
        BankTransactionId = NullableString(reader, "BankTransactionId"),
        CardType = NullableString(reader, "CardType"),
        GatewayResponse = NullableString(reader, "GatewayResponse"),
        CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt")),
        PaidAt = reader.IsDBNull(reader.GetOrdinal("PaidAt")) ? null : reader.GetDateTime(reader.GetOrdinal("PaidAt"))
    };

    private static string? NullableString(SqlDataReader reader, string name) =>
        reader.IsDBNull(reader.GetOrdinal(name)) ? null : reader.GetString(reader.GetOrdinal(name));
}
