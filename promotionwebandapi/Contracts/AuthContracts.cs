namespace OrderProcessAPI.Contracts;

public sealed class RegisterUserRequest
{
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string ConfirmPassword { get; init; } = string.Empty;
    public string? Role { get; init; }
    public string? FirebaseDeviceToken { get; init; }
    public string? Imei { get; init; }
}

public sealed class RegisterUserResponse
{
    public string UserId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public bool OtpRequired { get; init; }
    public DateTime OtpExpiresAt { get; init; }
    public string DebugOtpCode { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class LoginUserRequest
{
    public string PhoneNumber { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string? FirebaseDeviceToken { get; init; }
    public string? Imei { get; init; }
}

public sealed class LoginUserResponse
{
    public string UserId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
    public string? Role { get; init; }
    public bool IsPhoneVerified { get; init; }
    public bool OtpRequired { get; init; }
    public DateTime? OtpExpiresAt { get; init; }
    public string DebugOtpCode { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class VerifyOtpRequest
{
    public string UserId { get; init; } = string.Empty;
    public string OtpCode { get; init; } = string.Empty;
}

public sealed class VerifyOtpResponse
{
    public string UserId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public bool IsPhoneVerified { get; init; }
    public string Message { get; init; } = string.Empty;
}

public sealed class ResendOtpRequest
{
    public string UserId { get; init; } = string.Empty;
}

public sealed class ResendOtpResponse
{
    public string UserId { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public DateTime OtpExpiresAt { get; init; }
    public string DebugOtpCode { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class ForgotPasswordRequest
{
    public string PhoneNumber { get; init; } = string.Empty;
}

public sealed class ForgotPasswordResponse
{
    public string UserId { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public DateTime OtpExpiresAt { get; init; }
    public string DebugOtpCode { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class ResetPasswordRequest
{
    public string UserId { get; init; } = string.Empty;
    public string OtpCode { get; init; } = string.Empty;
    public string NewPassword { get; init; } = string.Empty;
    public string ConfirmPassword { get; init; } = string.Empty;
}

public sealed class ResetPasswordResponse
{
    public string UserId { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class UpdateDeviceInfoRequest
{
    public string UserId { get; init; } = string.Empty;
    public string? FirebaseDeviceToken { get; init; }
    public string? Imei { get; init; }
}

public sealed class UpdateDeviceInfoResponse
{
    public string UserId { get; init; } = string.Empty;
    public string? FirebaseDeviceToken { get; init; }
    public string? Imei { get; init; }
    public string Message { get; init; } = string.Empty;
}

public sealed class SendOtpRequest
{
    public string MobileNumber { get; init; } = string.Empty;
    public string OtpCode { get; init; } = string.Empty;
}

public sealed class SendOtpResponse
{
    public bool IsSuccess { get; init; }
    public bool IsError { get; init; }
    public string ProviderResponse { get; init; } = string.Empty;
    public string ErrorMessage { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}
