namespace OrderProcessAPI.Services;

public interface ISmsOtpService
{
    Task<SmsOtpSendResult> SendOtpAsync(
        string mobileNumber,
        string otpCode,
        CancellationToken cancellationToken = default);

    Task<SmsOtpSendResult> SendMessageAsync(
        string mobileNumber,
        string message,
        CancellationToken cancellationToken = default);
}

public sealed class SmsOtpSendResult
{
    public bool IsSuccess { get; init; }
    public bool IsError { get; init; }
    public string ProviderResponse { get; init; } = string.Empty;
    public string ErrorMessage { get; init; } = string.Empty;
}
