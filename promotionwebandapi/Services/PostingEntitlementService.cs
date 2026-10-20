using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class PostingEntitlementService : IPostingEntitlementService
{
    private const int DefaultFreeQuota = 4;
    private const decimal MinimumRequiredPayment = 100.00m;
    private const decimal AmountPerCredit = 100.00m;

    private readonly SqlConnectionFactory _connectionFactory;
    private static bool _schemaEnsured;

    public PostingEntitlementService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    private static async Task EnsureSchemaAsync(Microsoft.Data.SqlClient.SqlConnection connection, CancellationToken cancellationToken)
    {
        if (_schemaEnsured) return;

        const string sql = """
            IF OBJECT_ID(N'dbo.UserPostingEntitlements', N'U') IS NULL
            BEGIN
                CREATE TABLE dbo.UserPostingEntitlements (
                    UserId NVARCHAR(450) NOT NULL CONSTRAINT PK_UserPostingEntitlements PRIMARY KEY,
                    FreePostsAllowed INT NOT NULL CONSTRAINT DF_UserPostingEntitlements_FreeAllowed DEFAULT (4),
                    FreePostsUsed INT NOT NULL CONSTRAINT DF_UserPostingEntitlements_FreeUsed DEFAULT (0),
                    PaidCreditsBalance INT NOT NULL CONSTRAINT DF_UserPostingEntitlements_PaidCredits DEFAULT (0),
                    TotalPaidAmount DECIMAL(18,2) NOT NULL CONSTRAINT DF_UserPostingEntitlements_TotalPaid DEFAULT (0.00),
                    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_UserPostingEntitlements_CreatedAt DEFAULT SYSUTCDATETIME(),
                    UpdatedAt DATETIME2 NOT NULL CONSTRAINT DF_UserPostingEntitlements_UpdatedAt DEFAULT SYSUTCDATETIME()
                );
            END
            """;

        await connection.ExecuteAsync(new CommandDefinition(sql, cancellationToken: cancellationToken));
        _schemaEnsured = true;
    }

    public async Task<PostingEntitlementDto> GetEntitlementAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new ArgumentException("User ID is required.", nameof(userId));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await EnsureSchemaAsync(connection, cancellationToken);

        var record = await connection.QuerySingleOrDefaultAsync<EntitlementRow>(
            new CommandDefinition(
                """
                SELECT UserId, FreePostsAllowed, FreePostsUsed, PaidCreditsBalance, TotalPaidAmount
                FROM dbo.UserPostingEntitlements
                WHERE UserId = @userId
                """,
                new { userId },
                cancellationToken: cancellationToken));

        if (record is null)
        {
            // Count any existing posts by this user to seed FreePostsUsed accurately
            var existingGeneralCount = await connection.ExecuteScalarAsync<int>(
                new CommandDefinition(
                    "SELECT COUNT(1) FROM dbo.GeneralPosts WHERE UserId = @userId",
                    new { userId },
                    cancellationToken: cancellationToken));

            var existingTutorCount = await connection.ExecuteScalarAsync<int>(
                new CommandDefinition(
                    "SELECT COUNT(1) FROM dbo.TenantTutorPosts WHERE TenantId = @userId",
                    new { userId },
                    cancellationToken: cancellationToken));

            var totalExisting = existingGeneralCount + existingTutorCount;
            var initialFreeUsed = Math.Min(DefaultFreeQuota, totalExisting);

            const string insertSql = """
                INSERT INTO dbo.UserPostingEntitlements
                (
                    UserId,
                    FreePostsAllowed,
                    FreePostsUsed,
                    PaidCreditsBalance,
                    TotalPaidAmount,
                    CreatedAt,
                    UpdatedAt
                )
                VALUES
                (
                    @userId,
                    @DefaultFreeQuota,
                    @initialFreeUsed,
                    0,
                    0.00,
                    SYSUTCDATETIME(),
                    SYSUTCDATETIME()
                );
                """;

            await connection.ExecuteAsync(
                new CommandDefinition(
                    insertSql,
                    new { userId, DefaultFreeQuota, initialFreeUsed },
                    cancellationToken: cancellationToken));

            record = new EntitlementRow
            {
                UserId = userId,
                FreePostsAllowed = DefaultFreeQuota,
                FreePostsUsed = initialFreeUsed,
                PaidCreditsBalance = 0,
                TotalPaidAmount = 0.00m
            };
        }

        var remainingFree = Math.Max(0, record.FreePostsAllowed - record.FreePostsUsed);
        var canPost = remainingFree > 0 || record.PaidCreditsBalance > 0;

        return new PostingEntitlementDto
        {
            UserId = record.UserId,
            FreePostsAllowed = record.FreePostsAllowed,
            FreePostsUsed = record.FreePostsUsed,
            RemainingFreePosts = remainingFree,
            PaidCreditsBalance = record.PaidCreditsBalance,
            TotalPaidAmount = record.TotalPaidAmount,
            CanPost = canPost,
            RequiresPayment = !canPost,
            MinimumPaymentAmount = MinimumRequiredPayment
        };
    }

    public async Task ConsumePostingSlotAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        var entitlement = await GetEntitlementAsync(userId, cancellationToken);
        if (!entitlement.CanPost)
        {
            throw new InvalidOperationException(
                $"User {userId} has reached the free posting limit of {entitlement.FreePostsAllowed} posts. A minimum payment of BDT {MinimumRequiredPayment:0.00} is required before publishing another post.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        if (entitlement.RemainingFreePosts > 0)
        {
            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.UserPostingEntitlements
                    SET FreePostsUsed = FreePostsUsed + 1,
                        UpdatedAt = SYSUTCDATETIME()
                    WHERE UserId = @userId
                    """,
                    new { userId },
                    cancellationToken: cancellationToken));
        }
        else
        {
            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.UserPostingEntitlements
                    SET PaidCreditsBalance = PaidCreditsBalance - 1,
                        UpdatedAt = SYSUTCDATETIME()
                    WHERE UserId = @userId AND PaidCreditsBalance > 0
                    """,
                    new { userId },
                    cancellationToken: cancellationToken));
        }
    }

    public async Task<PostingEntitlementDto> GrantPostingCreditsAsync(
        string userId,
        decimal amount,
        string transactionId,
        CancellationToken cancellationToken = default)
    {
        if (amount < MinimumRequiredPayment)
        {
            throw new ArgumentException(
                $"Posting payment must be at least BDT {MinimumRequiredPayment:0.00}. Provided: BDT {amount:0.00}",
                nameof(amount));
        }

        var creditsToGrant = (int)Math.Floor(amount / AmountPerCredit);
        if (creditsToGrant <= 0)
        {
            creditsToGrant = 1;
        }

        // Ensure record exists
        await GetEntitlementAsync(userId, cancellationToken);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.UserPostingEntitlements
                SET PaidCreditsBalance = PaidCreditsBalance + @creditsToGrant,
                    TotalPaidAmount = TotalPaidAmount + @amount,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE UserId = @userId
                """,
                new { userId, creditsToGrant, amount },
                cancellationToken: cancellationToken));

        return await GetEntitlementAsync(userId, cancellationToken);
    }

    private sealed class EntitlementRow
    {
        public string UserId { get; set; } = string.Empty;
        public int FreePostsAllowed { get; set; }
        public int FreePostsUsed { get; set; }
        public int PaidCreditsBalance { get; set; }
        public decimal TotalPaidAmount { get; set; }
    }
}
