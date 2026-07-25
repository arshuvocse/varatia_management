using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IAuthService
{
    Task<RegisterUserResponse> RegisterAsync(
        RegisterUserRequest request,
        CancellationToken cancellationToken = default);

    Task<LoginUserResponse> LoginAsync(
        LoginUserRequest request,
        CancellationToken cancellationToken = default);

    Task<VerifyOtpResponse> VerifyOtpAsync(
        VerifyOtpRequest request,
        CancellationToken cancellationToken = default);

    Task<ResendOtpResponse> ResendOtpAsync(
        ResendOtpRequest request,
        CancellationToken cancellationToken = default);

    Task<ForgotPasswordResponse> RequestPasswordResetAsync(
        ForgotPasswordRequest request,
        CancellationToken cancellationToken = default);

    Task<ResetPasswordResponse> ResetPasswordAsync(
        ResetPasswordRequest request,
        CancellationToken cancellationToken = default);

    Task<UpdateDeviceInfoResponse> UpdateDeviceInfoAsync(
        UpdateDeviceInfoRequest request,
        CancellationToken cancellationToken = default);

    Task<SendOtpResponse> SendOtpAsync(
        SendOtpRequest request,
        CancellationToken cancellationToken = default);
}
