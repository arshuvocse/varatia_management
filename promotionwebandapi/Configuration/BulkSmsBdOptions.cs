namespace OrderProcessAPI.Configuration;

public sealed class BulkSmsBdOptions
{
    public const string SectionName = "BulkSmsBd";
    public const string DefaultBaseUrl = "https://bulksmsbd.net/api/smsapi";

    public string ApiKey { get; init; } = string.Empty;
    public string SenderId { get; init; } = string.Empty;
    public string BaseUrl { get; init; } = DefaultBaseUrl;
}
