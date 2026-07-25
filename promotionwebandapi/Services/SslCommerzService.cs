using System.Globalization;
using System.Text.Json;
using PromotionWeb.Models;

namespace PromotionWeb.Services;

public sealed class SslCommerzService(HttpClient httpClient, IConfiguration configuration)
{
    private readonly IConfigurationSection _settings = configuration.GetSection("SslCommerz");

    public decimal ActivationFee => _settings.GetValue("ActivationFee", 50m);
    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(_settings["StoreId"])
        && !string.IsNullOrWhiteSpace(_settings["StorePassword"]);

    public async Task<SslCommerzSessionResult> CreateSessionAsync(
        Shopkeeper shop,
        string transactionId,
        string successUrl,
        string failUrl,
        string cancelUrl,
        string ipnUrl)
    {
        return await CreateSessionAsync(shop, transactionId, ActivationFee, "Shopkeeper account activation", successUrl, failUrl, cancelUrl, ipnUrl);
    }

    public async Task<SslCommerzSessionResult> CreateSessionAsync(
        Shopkeeper shop,
        string transactionId,
        decimal amount,
        string productName,
        string successUrl,
        string failUrl,
        string cancelUrl,
        string ipnUrl,
        string? valueB = null)
    {
        if (!IsConfigured)
            return new SslCommerzSessionResult { Error = "SSLCOMMERZ credentials are not configured." };

        var fields = new Dictionary<string, string>
        {
            ["store_id"] = _settings["StoreId"]!,
            ["store_passwd"] = _settings["StorePassword"]!,
            ["total_amount"] = amount.ToString("0.00", CultureInfo.InvariantCulture),
            ["currency"] = "BDT",
            ["tran_id"] = transactionId,
            ["success_url"] = successUrl,
            ["fail_url"] = failUrl,
            ["cancel_url"] = cancelUrl,
            ["ipn_url"] = ipnUrl,
            ["cus_name"] = shop.OwnerName,
            ["cus_email"] = _settings["FallbackCustomerEmail"] ?? "shopkeeper@example.com",
            ["cus_add1"] = shop.Address,
            ["cus_city"] = shop.DistrictName,
            ["cus_state"] = shop.DivisionName,
            ["cus_postcode"] = "1000",
            ["cus_country"] = "Bangladesh",
            ["cus_phone"] = shop.Phone,
            ["shipping_method"] = "NO",
            ["num_of_item"] = "1",
            ["product_name"] = productName,
            ["product_category"] = "service",
            ["product_profile"] = "non-physical-goods",
            ["value_a"] = shop.Id.ToString(CultureInfo.InvariantCulture)
        };
        
        if (!string.IsNullOrEmpty(valueB))
        {
            fields["value_b"] = valueB;
        }

        try
        {
            using var response = await httpClient.PostAsync(
                $"{BaseUrl}/gwprocess/v4/api.php",
                new FormUrlEncodedContent(fields));
            var raw = await response.Content.ReadAsStringAsync();
            using var json = JsonDocument.Parse(raw);
            var root = json.RootElement;
            var status = GetString(root, "status");
            return new SslCommerzSessionResult
            {
                Success = response.IsSuccessStatusCode && string.Equals(status, "SUCCESS", StringComparison.OrdinalIgnoreCase),
                GatewayUrl = GetString(root, "GatewayPageURL"),
                SessionKey = GetString(root, "sessionkey"),
                Error = GetString(root, "failedreason"),
                RawResponse = raw
            };
        }
        catch (Exception ex) when (ex is HttpRequestException or JsonException or TaskCanceledException)
        {
            return new SslCommerzSessionResult { Error = "Could not connect to SSLCOMMERZ.", RawResponse = ex.Message };
        }
    }

    public async Task<SslCommerzValidationResult> ValidateAsync(string validationId)
    {
        if (!IsConfigured)
            return new SslCommerzValidationResult { Error = "SSLCOMMERZ credentials are not configured." };

        var query = new Dictionary<string, string?>
        {
            ["val_id"] = validationId,
            ["store_id"] = _settings["StoreId"],
            ["store_passwd"] = _settings["StorePassword"],
            ["v"] = "1",
            ["format"] = "json"
        };
        var url = Microsoft.AspNetCore.WebUtilities.QueryHelpers.AddQueryString(
            $"{BaseUrl}/validator/api/validationserverAPI.php", query);

        try
        {
            var raw = await httpClient.GetStringAsync(url);
            using var json = JsonDocument.Parse(raw);
            var root = json.RootElement;
            var status = GetString(root, "status");
            var transactionId = GetString(root, "tran_id");
            var returnedValidationId = GetString(root, "val_id");
            var bankTransactionId = GetString(root, "bank_tran_id");
            var cardType = GetString(root, "card_type");
            var amount = GetDecimal(root, "amount");
            var currency = GetString(root, "currency");
            var riskLevel = GetInt(root, "risk_level");
            var auditResponse = JsonSerializer.Serialize(new
            {
                status,
                transactionId,
                validationId = returnedValidationId,
                bankTransactionId,
                cardType,
                amount,
                currency,
                riskLevel
            });
            return new SslCommerzValidationResult
            {
                IsValid = status is "VALID" or "VALIDATED",
                Status = status,
                TransactionId = transactionId,
                ValidationId = returnedValidationId,
                BankTransactionId = bankTransactionId,
                CardType = cardType,
                Amount = amount,
                Currency = currency,
                RiskLevel = riskLevel,
                RawResponse = auditResponse
            };
        }
        catch (Exception ex) when (ex is HttpRequestException or JsonException or TaskCanceledException)
        {
            return new SslCommerzValidationResult { Error = "Payment validation failed.", RawResponse = ex.Message };
        }
    }

    private string BaseUrl => _settings.GetValue("Sandbox", true)
        ? "https://sandbox.sslcommerz.com"
        : "https://securepay.sslcommerz.com";

    private static string? GetString(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value) ? value.ToString() : null;

    private static decimal GetDecimal(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value)
        && decimal.TryParse(value.ToString(), NumberStyles.Number, CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : 0m;

    private static int GetInt(JsonElement root, string name) =>
        root.TryGetProperty(name, out var value) && int.TryParse(value.ToString(), out var parsed) ? parsed : 0;
}
