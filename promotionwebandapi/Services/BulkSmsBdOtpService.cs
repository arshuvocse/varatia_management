using Microsoft.Extensions.Options;
using OrderProcessAPI.Configuration;

namespace OrderProcessAPI.Services;

public sealed class BulkSmsBdOtpService : ISmsOtpService
{
    private readonly HttpClient _httpClient;
    private readonly IWebHostEnvironment _environment;
    private readonly BulkSmsBdOptions _options;

    public BulkSmsBdOtpService(
        HttpClient httpClient,
        IWebHostEnvironment environment,
        IOptions<BulkSmsBdOptions> options)
    {
        _httpClient = httpClient;
        _environment = environment;
        _options = options.Value;
    }

    public async Task<SmsOtpSendResult> SendOtpAsync(
        string mobileNumber,
        string otpCode,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var normalizedMobileNumber = NormalizeDigits(mobileNumber);
            var normalizedOtpCode = NormalizeDigits(otpCode);

            if (normalizedMobileNumber.Length < 10 ||
                normalizedMobileNumber.Length > 15)
            {
                return new SmsOtpSendResult
                {
                    IsError = true,
                    ErrorMessage = "Mobile number must contain 10 to 15 digits.",
                };
            }

            if (normalizedOtpCode.Length != 6)
            {
                return new SmsOtpSendResult
                {
                    IsError = true,
                    ErrorMessage = "OTP code must contain 6 digits.",
                };
            }

            var message =
                $"Welcome to Amar Abas APP! Your OTP code is : {normalizedOtpCode}. Please enter it to verify your account.";
            return await SendNormalizedMessageAsync(
                normalizedMobileNumber,
                message,
                cancellationToken);
        }
        catch (HttpRequestException exception)
        {
            return new SmsOtpSendResult
            {
                IsError = true,
                ErrorMessage = $"Error sending OTP: {exception.Message}",
            };
        }
        catch (Exception exception)
        {
            return new SmsOtpSendResult
            {
                IsError = true,
                ErrorMessage = $"Unexpected error: {exception.Message}",
            };
        }
    }

    public async Task<SmsOtpSendResult> SendMessageAsync(
        string mobileNumber,
        string message,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var normalizedMobileNumber = NormalizeDigits(mobileNumber);
            if (normalizedMobileNumber.Length < 10 ||
                normalizedMobileNumber.Length > 15)
            {
                return new SmsOtpSendResult
                {
                    IsError = true,
                    ErrorMessage = "Mobile number must contain 10 to 15 digits.",
                };
            }

            if (string.IsNullOrWhiteSpace(message))
            {
                return new SmsOtpSendResult
                {
                    IsError = true,
                    ErrorMessage = "Message is required.",
                };
            }

            return await SendNormalizedMessageAsync(
                normalizedMobileNumber,
                message.Trim(),
                cancellationToken);
        }
        catch (HttpRequestException exception)
        {
            return new SmsOtpSendResult
            {
                IsError = true,
                ErrorMessage = $"Error sending SMS: {exception.Message}",
            };
        }
        catch (Exception exception)
        {
            return new SmsOtpSendResult
            {
                IsError = true,
                ErrorMessage = $"Unexpected error: {exception.Message}",
            };
        }
    }

    private async Task<SmsOtpSendResult> SendNormalizedMessageAsync(
        string normalizedMobileNumber,
        string message,
        CancellationToken cancellationToken)
    {
        if (_environment.IsDevelopment() &&
            (string.IsNullOrWhiteSpace(_options.ApiKey) ||
             string.IsNullOrWhiteSpace(_options.SenderId)))
        {
            return new SmsOtpSendResult
            {
                IsSuccess = true,
                ProviderResponse = "Development mode: SMS send skipped.",
            };
        }

        if (string.IsNullOrWhiteSpace(_options.ApiKey) ||
            string.IsNullOrWhiteSpace(_options.SenderId))
        {
            return new SmsOtpSendResult
            {
                IsError = true,
                ErrorMessage = "BulkSMSBD credentials are not configured.",
            };
        }

        var encodedMessage = Uri.EscapeDataString(message);
        var baseUrl = string.IsNullOrWhiteSpace(_options.BaseUrl)
            ? BulkSmsBdOptions.DefaultBaseUrl
            : _options.BaseUrl.Trim();
        var url =
            $"{baseUrl}?api_key={Uri.EscapeDataString(_options.ApiKey)}&type=text&number={normalizedMobileNumber}&senderid={Uri.EscapeDataString(_options.SenderId)}&message={encodedMessage}";

        var response = await _httpClient.GetAsync(url, cancellationToken);
        var responseContent = await response.Content.ReadAsStringAsync(
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            return new SmsOtpSendResult
            {
                IsError = true,
                ProviderResponse = responseContent,
                ErrorMessage =
                    $"BulkSMSBD returned HTTP {(int)response.StatusCode}.",
            };
        }

        return new SmsOtpSendResult
        {
            IsSuccess = true,
            ProviderResponse = responseContent,
        };
    }

    private static string NormalizeDigits(string value)
    {
        return new string(value.Where(char.IsDigit).ToArray());
    }
}
