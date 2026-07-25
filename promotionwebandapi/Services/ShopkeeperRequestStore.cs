using Microsoft.Data.SqlClient;
using PromotionWeb.Models;

namespace PromotionWeb.Services;

public sealed class ShopkeeperRequestStore(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");
    private static readonly object SchemaLock = new();
    private static bool _schemaReady;

    public ShopkeeperWalletSummary GetWalletSummary(int shopkeeperId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT
                COALESCE(w.Balance, 0) AS Balance,
                COALESCE(w.WithdrawableBalance, 0) AS WithdrawableBalance,
                COALESCE((SELECT SUM(r.Amount) FROM dbo.tbl_ShopkeeperWithdrawalRequests r
                          WHERE r.ShopkeeperId = @ShopkeeperId AND r.Status IN (N'Pending',N'Approved')), 0) AS PendingWithdrawal
            FROM (VALUES (1)) seed(Id)
            LEFT JOIN dbo.tbl_ShopkeeperWallets w ON w.ShopkeeperId = @ShopkeeperId;
            """, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        connection.Open();
        using var reader = command.ExecuteReader();
        if (!reader.Read()) return new ShopkeeperWalletSummary();
        return new ShopkeeperWalletSummary
        {
            Balance = reader.GetDecimal(0),
            Withdrawable = reader.GetDecimal(1),
            PendingWithdrawal = reader.GetDecimal(2)
        };
    }

    public IReadOnlyList<ShopkeeperWithdrawalViewModel> GetWithdrawals(int shopkeeperId)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT TOP (20) Id, Amount, PaymentMethod, AccountNumber, Status, CreatedAt
            FROM dbo.tbl_ShopkeeperWithdrawalRequests
            WHERE ShopkeeperId = @ShopkeeperId
            ORDER BY Id DESC;
            """, connection);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        connection.Open();
        using var reader = command.ExecuteReader();
        var result = new List<ShopkeeperWithdrawalViewModel>();
        while (reader.Read())
        {
            result.Add(new ShopkeeperWithdrawalViewModel
            {
                Id = reader.GetInt32(0), Amount = reader.GetDecimal(1), PaymentMethod = reader.GetString(2),
                AccountNumber = reader.GetString(3), Status = reader.GetString(4), CreatedAt = reader.GetDateTime(5)
            });
        }
        return result;
    }

    public IReadOnlyList<ShopkeeperWithdrawalViewModel> GetAllWithdrawals()
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT r.Id,r.Amount,r.PaymentMethod,r.AccountNumber,r.Status,r.CreatedAt,
                   s.ShopName,s.ShopCode,s.Phone
            FROM dbo.tbl_ShopkeeperWithdrawalRequests r
            JOIN dbo.tbl_Shopkeepers s ON s.Id=r.ShopkeeperId
            ORDER BY CASE r.Status WHEN N'Pending' THEN 0 WHEN N'Approved' THEN 1 ELSE 2 END,r.Id DESC;
            """, connection);
        connection.Open();
        using var reader = command.ExecuteReader();
        var result = new List<ShopkeeperWithdrawalViewModel>();
        while (reader.Read()) result.Add(new ShopkeeperWithdrawalViewModel
        {
            Id=reader.GetInt32(0),Amount=reader.GetDecimal(1),PaymentMethod=reader.GetString(2),
            AccountNumber=reader.GetString(3),Status=reader.GetString(4),CreatedAt=reader.GetDateTime(5),
            ShopName=reader.GetString(6),ShopCode=reader.GetString(7),ShopPhone=reader.GetString(8)
        });
        return result;
    }

    public void ProcessWithdrawal(int requestId, string status, int companyUserId, string? note)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        using var command = new SqlCommand("""
            DECLARE @ShopkeeperId INT,@Amount DECIMAL(18,2),@CurrentStatus NVARCHAR(20);
            SELECT @ShopkeeperId=ShopkeeperId,@Amount=Amount,@CurrentStatus=Status
            FROM dbo.tbl_ShopkeeperWithdrawalRequests WITH(UPDLOCK,HOLDLOCK) WHERE Id=@Id;
            IF @ShopkeeperId IS NULL THROW 51202,N'Withdrawal request not found.',1;
            IF @Status=N'Approved' AND @CurrentStatus<>N'Pending' THROW 51203,N'Only pending requests can be approved.',1;
            IF @Status=N'Rejected' AND @CurrentStatus NOT IN(N'Pending',N'Approved') THROW 51204,N'This request cannot be rejected.',1;
            IF @Status=N'Paid' AND @CurrentStatus<>N'Approved' THROW 51205,N'Approve the request before marking it paid.',1;

            IF @Status=N'Rejected'
                UPDATE dbo.tbl_ShopkeeperWallets SET WithdrawableBalance=WithdrawableBalance+@Amount,UpdatedAt=SYSUTCDATETIME()
                WHERE ShopkeeperId=@ShopkeeperId;
            IF @Status=N'Paid'
            BEGIN
                UPDATE dbo.tbl_ShopkeeperWallets SET Balance=Balance-@Amount,UpdatedAt=SYSUTCDATETIME()
                WHERE ShopkeeperId=@ShopkeeperId AND Balance>=@Amount;
                IF @@ROWCOUNT=0 THROW 51206,N'Wallet balance is insufficient.',1;
            END

            UPDATE dbo.tbl_ShopkeeperWithdrawalRequests
            SET Status=@Status,ProcessedAt=SYSUTCDATETIME(),ProcessedByUserId=@UserId,ProcessingNote=@Note
            WHERE Id=@Id;
            """, connection, transaction);
        command.Parameters.AddWithValue("@Id",requestId); command.Parameters.AddWithValue("@Status",status);
        command.Parameters.AddWithValue("@UserId",companyUserId); command.Parameters.AddWithValue("@Note",(object?)note?.Trim()??DBNull.Value);
        try { command.ExecuteNonQuery(); transaction.Commit(); }
        catch (SqlException ex) when (ex.Number is >= 51202 and <= 51206) { transaction.Rollback(); throw new InvalidOperationException(ex.Message,ex); }
    }

    public void RequestWithdrawal(int shopkeeperId, ShopkeeperWithdrawalInputModel input)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        using var transaction = connection.BeginTransaction();
        using var command = new SqlCommand("""
            DECLARE @Available DECIMAL(18,2);
            SELECT @Available = WithdrawableBalance
            FROM dbo.tbl_ShopkeeperWallets WITH (UPDLOCK, HOLDLOCK)
            WHERE ShopkeeperId = @ShopkeeperId;

            IF COALESCE(@Available, 0) < @Amount
                THROW 51201, N'উত্তোলনযোগ্য ব্যালেন্স পর্যাপ্ত নয়।', 1;

            UPDATE dbo.tbl_ShopkeeperWallets
            SET WithdrawableBalance = WithdrawableBalance - @Amount,
                UpdatedAt = SYSUTCDATETIME()
            WHERE ShopkeeperId = @ShopkeeperId;

            INSERT INTO dbo.tbl_ShopkeeperWithdrawalRequests
                (ShopkeeperId, Amount, PaymentMethod, AccountNumber)
            VALUES (@ShopkeeperId, @Amount, @PaymentMethod, @AccountNumber);
            """, connection, transaction);
        command.Parameters.AddWithValue("@ShopkeeperId", shopkeeperId);
        command.Parameters.AddWithValue("@Amount", input.Amount);
        command.Parameters.AddWithValue("@PaymentMethod", input.PaymentMethod.Trim());
        command.Parameters.AddWithValue("@AccountNumber", input.AccountNumber.Trim());
        try
        {
            command.ExecuteNonQuery();
            transaction.Commit();
        }
        catch (SqlException ex) when (ex.Number == 51201)
        {
            transaction.Rollback();
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    private void EnsureSchema()
    {
        if (_schemaReady) return;
        lock (SchemaLock)
        {
            if (_schemaReady) return;
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("""
                IF OBJECT_ID(N'dbo.tbl_ShopkeeperWithdrawalRequests', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.tbl_ShopkeeperWithdrawalRequests
                    (
                        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ShopkeeperWithdrawalRequests PRIMARY KEY,
                        ShopkeeperId INT NOT NULL,
                        Amount DECIMAL(18,2) NOT NULL,
                        PaymentMethod NVARCHAR(30) NOT NULL,
                        AccountNumber NVARCHAR(30) NOT NULL,
                        Status NVARCHAR(20) NOT NULL CONSTRAINT DF_ShopkeeperWithdrawal_Status DEFAULT N'Pending',
                        CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_ShopkeeperWithdrawal_Created DEFAULT SYSUTCDATETIME(),
                        ProcessedAt DATETIME2(0) NULL,
                        CONSTRAINT FK_ShopkeeperWithdrawal_Shop FOREIGN KEY (ShopkeeperId) REFERENCES dbo.tbl_Shopkeepers(Id),
                        CONSTRAINT CK_ShopkeeperWithdrawal_Amount CHECK (Amount > 0),
                        CONSTRAINT CK_ShopkeeperWithdrawal_Status CHECK (Status IN (N'Pending', N'Approved', N'Rejected', N'Paid'))
                    );
                    CREATE INDEX IX_ShopkeeperWithdrawal_Shop_Status
                        ON dbo.tbl_ShopkeeperWithdrawalRequests (ShopkeeperId, Status, CreatedAt DESC);
                END;
                IF COL_LENGTH(N'dbo.tbl_ShopkeeperWithdrawalRequests',N'ProcessedByUserId') IS NULL
                    ALTER TABLE dbo.tbl_ShopkeeperWithdrawalRequests ADD ProcessedByUserId INT NULL;
                IF COL_LENGTH(N'dbo.tbl_ShopkeeperWithdrawalRequests',N'ProcessingNote') IS NULL
                    ALTER TABLE dbo.tbl_ShopkeeperWithdrawalRequests ADD ProcessingNote NVARCHAR(250) NULL;
                """, connection);
            connection.Open();
            command.ExecuteNonQuery();
            _schemaReady = true;
        }
    }
}
