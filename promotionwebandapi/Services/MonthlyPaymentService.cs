using System.Data;
using System.Text.Json;
using System.Text.Json.Serialization;
using Dapper;
using Microsoft.Data.SqlClient;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class MonthlyPaymentService : IMonthlyPaymentService
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private const string StoreId = "amarthikanaalive";
    private const string StorePassword = "6A27E77A0A4AC55109";
    private const string InitiateUrl = "https://securepay.sslcommerz.com/gwprocess/v4/api.php";
    private const string ValidateUrl = "https://securepay.sslcommerz.com/validator/api/validationserverAPI.php";
    private const decimal MonthlyServiceCharge = 50.00m;

    public MonthlyPaymentService(
        SqlConnectionFactory connectionFactory,
        HttpClient httpClient,
        IConfiguration configuration)
    {
        _connectionFactory = connectionFactory;
        _httpClient = httpClient;
        _configuration = configuration;
    }

    public async Task<PaymentStatusResponse> GetPaymentStatusAsync(string userId, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<PaymentStatusResponse>(
                new CommandDefinition(
                    "dbo.sp_MonthlyPayment_GetStatus",
                    new { UserId = parsedUserId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken));
        }
        catch (SqlException exception) when (exception.Number == 51040)
        {
            throw new InvalidOperationException("User not found.", exception);
        }
    }

    public async Task<MonthlyPaymentHistoryResponse> GetPaymentHistoryAsync(
        string userId,
        int year,
        CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        if (year is < 2000 or > 2100)
        {
            throw new ArgumentException(
                "Year must be between 2000 and 2100.",
                nameof(year));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        try
        {
            var rows = (await connection.QueryAsync<MonthlyPaymentHistoryRow>(
                new CommandDefinition(
                    "dbo.sp_MonthlyPayment_GetHistory",
                    new { UserId = parsedUserId, Year = year },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken))).AsList();

            var firstRow = rows.First();
            return new MonthlyPaymentHistoryResponse
            {
                UserId = firstRow.UserId,
                Role = firstRow.Role,
                Year = firstRow.Year,
                Months = rows.Select(row => new MonthlyPaymentHistoryItem
                {
                    MonthNumber = row.MonthNumber,
                    PaymentMonth = row.PaymentMonth,
                    PaymentStatus = row.PaymentStatus,
                    Amount = row.Amount,
                    PaidAt = row.PaidAt,
                    AccessAllowed = row.AccessAllowed,
                }).ToArray(),
            };
        }
        catch (SqlException exception) when (exception.Number == 51040)
        {
            throw new InvalidOperationException("User not found.", exception);
        }
    }

    public async Task<InitiatePaymentResponse> InitiatePaymentAsync(string userId, string baseUrl, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Valid user id is required.", nameof(userId));
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        // Fetch User Info
        var user = await connection.QuerySingleOrDefaultAsync<UserLookup>(
            new CommandDefinition(
                """
                SELECT FullName, PhoneNumber
                FROM dbo.Users
                WHERE Id = @UserId;
                """,
                new { UserId = parsedUserId },
                cancellationToken: cancellationToken));

        if (user is null)
        {
            throw new InvalidOperationException("User not found.");
        }

        var transactionId = $"TXN-{Guid.NewGuid().ToString("N").Substring(0, 16).ToUpper()}";
        var monthYear = DateTime.UtcNow.AddHours(6).ToString("yyyy-MM");
        const decimal amount = MonthlyServiceCharge;

        // Save pending payment record to database
        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.MonthlyPayments (UserId, TransactionId, Amount, Status, MonthYear)
                VALUES (@UserId, @TransactionId, @Amount, 'pending', @MonthYear);
                """,
                new
                {
                    UserId = userId,
                    TransactionId = transactionId,
                    Amount = amount,
                    MonthYear = monthYear
                },
                cancellationToken: cancellationToken));

        // Prepare SSLCommerz Payload
        var values = new Dictionary<string, string>
        {
            { "store_id", GetStoreId() },
            { "store_passwd", GetStorePassword() },
            { "total_amount", amount.ToString("F2") },
            { "currency", "BDT" },
            { "tran_id", transactionId },
            { "success_url", $"{baseUrl}/api/payments/success?tran_id={transactionId}" },
            { "fail_url", $"{baseUrl}/api/payments/fail?tran_id={transactionId}" },
            { "cancel_url", $"{baseUrl}/api/payments/cancel?tran_id={transactionId}" },
            { "ipn_url", $"{baseUrl}/api/payments/ipn?tran_id={transactionId}" },
            { "cus_name", string.IsNullOrWhiteSpace(user.FullName) ? "Amar Thikana User" : user.FullName },
            { "cus_email", "payment@amarthikana.com" },
            { "cus_phone", string.IsNullOrWhiteSpace(user.PhoneNumber) ? "01700000000" : user.PhoneNumber },
            { "cus_add1", "Dhaka" },
            { "cus_city", "Dhaka" },
            { "cus_country", "Bangladesh" },
            { "shipping_method", "NO" },
            { "product_name", "Monthly Service Charge" },
            { "product_category", "Service" },
            { "product_profile", "general" }
        };

        var content = new FormUrlEncodedContent(values);
        var response = await _httpClient.PostAsync(InitiateUrl, content, cancellationToken);
        response.EnsureSuccessStatusCode();

        var responseString = await response.Content.ReadAsStringAsync(cancellationToken);
        using var document = JsonDocument.Parse(responseString);
        var root = document.RootElement;

        var status = root.GetProperty("status").GetString();
        if (!string.Equals(status, "SUCCESS", StringComparison.OrdinalIgnoreCase))
        {
            var failedReason = root.TryGetProperty("failedreason", out var reasonProp) ? reasonProp.GetString() : "Unknown SSLCommerz error";
            throw new InvalidOperationException($"SSLCommerz initiation failed: {failedReason}");
        }

        var gatewayUrl = root.GetProperty("GatewayPageURL").GetString();
        if (string.IsNullOrWhiteSpace(gatewayUrl))
        {
            throw new InvalidOperationException("GatewayPageURL is missing in SSLCommerz response.");
        }

        return new InitiatePaymentResponse
        {
            GatewayPageUrl = gatewayUrl,
            TransactionId = transactionId
        };
    }

    public async Task<MonthlyPaymentCallbackResult> ProcessCallbackAsync(
        MonthlyPaymentCallbackData callbackData,
        CancellationToken cancellationToken)
    {
        var transactionId = callbackData.TransactionId?.Trim();
        if (string.IsNullOrWhiteSpace(transactionId))
        {
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = "Payment callback is missing transaction id."
            };
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var payment = await connection.QuerySingleOrDefaultAsync<MonthlyPaymentAttempt>(
            new CommandDefinition(
                """
                SELECT TOP (1)
                    TransactionId,
                    Amount,
                    Status,
                    MonthYear
                FROM dbo.MonthlyPayments
                WHERE TransactionId = @TransactionId;
                """,
                new { TransactionId = transactionId },
                cancellationToken: cancellationToken));

        if (payment is null)
        {
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = "Payment transaction was not found."
            };
        }

        if (string.Equals(payment.Status, "success", StringComparison.OrdinalIgnoreCase))
        {
            return new MonthlyPaymentCallbackResult
            {
                Success = true,
                AlreadyProcessed = true,
                Status = "success",
                Message = "Payment was already verified."
            };
        }

        var callbackStatus = callbackData.Status?.Trim();
        if (string.Equals(callbackStatus, "CANCEL", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(callbackStatus, "CANCELLED", StringComparison.OrdinalIgnoreCase))
        {
            await MarkPaymentAsync(connection, transactionId, "cancelled", null, cancellationToken);
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "cancelled",
                Message = "Payment was cancelled."
            };
        }

        if (string.Equals(callbackStatus, "FAILED", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(callbackStatus, "FAIL", StringComparison.OrdinalIgnoreCase))
        {
            await MarkPaymentAsync(connection, transactionId, "failed", null, cancellationToken);
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = "Payment failed."
            };
        }

        var validationId = callbackData.ValidationId?.Trim();
        if (string.IsNullOrWhiteSpace(validationId))
        {
            await MarkPaymentAsync(connection, transactionId, "failed", null, cancellationToken);
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = "Payment callback is missing validation id."
            };
        }

        var validation = await ValidatePaymentAsync(validationId, cancellationToken);
        var validTransaction = string.Equals(
            validation.TransactionId,
            payment.TransactionId,
            StringComparison.Ordinal);
        var validAmount = validation.Amount == payment.Amount;
        var validCurrency = string.Equals(validation.Currency, "BDT", StringComparison.OrdinalIgnoreCase);

        if (!validation.IsValid || !validTransaction || !validAmount || !validCurrency || validation.RiskLevel != 0)
        {
            await MarkPaymentAsync(connection, transactionId, "failed", null, cancellationToken);
            return new MonthlyPaymentCallbackResult
            {
                Success = false,
                Status = "failed",
                Message = validation.RiskLevel == 1
                    ? "Payment is marked as risky and requires manual review."
                    : validation.Error ?? "Payment could not be verified."
            };
        }

        await MarkPaymentAsync(
            connection,
            transactionId,
            "success",
            DateTime.UtcNow.AddHours(6),
            cancellationToken);

        return new MonthlyPaymentCallbackResult
        {
            Success = true,
            Status = "success",
            Message = "Payment verified."
        };
    }

    private async Task MarkPaymentAsync(
        SqlConnection connection,
        string transactionId,
        string status,
        DateTime? paymentDate,
        CancellationToken cancellationToken)
    {
        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.MonthlyPayments
                SET Status = @Status,
                    PaymentDate = @PaymentDate,
                    UpdatedOn = SYSUTCDATETIME()
                WHERE TransactionId = @TransactionId;
                """,
                new
                {
                    Status = status,
                    PaymentDate = paymentDate,
                    TransactionId = transactionId
                },
                cancellationToken: cancellationToken));
    }

    private async Task<SslCommerzValidationResult> ValidatePaymentAsync(
        string validationId,
        CancellationToken cancellationToken)
    {
        var url = Microsoft.AspNetCore.WebUtilities.QueryHelpers.AddQueryString(
            ValidateUrl,
            new Dictionary<string, string?>
            {
                ["val_id"] = validationId,
                ["store_id"] = GetStoreId(),
                ["store_passwd"] = GetStorePassword(),
                ["v"] = "1",
                ["format"] = "json"
            });

        try
        {
            using var response = await _httpClient.GetAsync(url, cancellationToken);
            var raw = await response.Content.ReadAsStringAsync(cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return new SslCommerzValidationResult
                {
                    Error = $"SSLCommerz validation failed with HTTP {(int)response.StatusCode}.",
                    RawResponse = raw
                };
            }

            using var document = JsonDocument.Parse(raw);
            var root = document.RootElement;
            var status = GetString(root, "status");

            return new SslCommerzValidationResult
            {
                IsValid = status is "VALID" or "VALIDATED",
                Status = status,
                TransactionId = GetString(root, "tran_id"),
                ValidationId = GetString(root, "val_id"),
                Amount = GetDecimal(root, "amount"),
                Currency = GetString(root, "currency"),
                RiskLevel = GetInt(root, "risk_level"),
                RawResponse = raw
            };
        }
        catch (Exception exception) when (exception is HttpRequestException or JsonException or TaskCanceledException)
        {
            return new SslCommerzValidationResult
            {
                Error = "Payment validation failed.",
                RawResponse = exception.Message
            };
        }
    }

    private string GetStoreId() =>
        _configuration["SslCommerz:StoreId"]?.Trim() is { Length: > 0 } configured
            ? configured
            : StoreId;

    private string GetStorePassword() =>
        _configuration["SslCommerz:StorePassword"]?.Trim() is { Length: > 0 } configured
            ? configured
            : StorePassword;

    private static string? GetString(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value) ? value.ToString() : null;

    private static decimal GetDecimal(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value)
        && decimal.TryParse(value.ToString(), System.Globalization.NumberStyles.Number, System.Globalization.CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : 0m;

    private static int GetInt(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value) && int.TryParse(value.ToString(), out var parsed)
            ? parsed
            : 0;

    private sealed class UserLookup
    {
        public string FullName { get; init; } = string.Empty;
        public string PhoneNumber { get; init; } = string.Empty;
    }

    private sealed class MonthlyPaymentAttempt
    {
        public string TransactionId { get; init; } = string.Empty;
        public decimal Amount { get; init; }
        public string Status { get; init; } = string.Empty;
        public string MonthYear { get; init; } = string.Empty;
    }

    private sealed class SslCommerzValidationResult
    {
        public bool IsValid { get; init; }
        public string? Status { get; init; }
        public string? TransactionId { get; init; }
        public string? ValidationId { get; init; }
        public decimal Amount { get; init; }
        public string? Currency { get; init; }
        public int RiskLevel { get; init; }
        public string? Error { get; init; }
        public string? RawResponse { get; init; }
    }

    private sealed class MonthlyPaymentHistoryRow
    {
        public string UserId { get; init; } = string.Empty;
        public string Role { get; init; } = string.Empty;
        public int Year { get; init; }
        public int MonthNumber { get; init; }
        public string PaymentMonth { get; init; } = string.Empty;
        public string PaymentStatus { get; init; } = string.Empty;
        public decimal Amount { get; init; }
        public DateTime? PaidAt { get; init; }
        public bool AccessAllowed { get; init; }
    }
}
