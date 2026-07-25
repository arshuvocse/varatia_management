namespace OrderProcessAPI.Contracts;

public sealed class UserProfileDto
{
    public string UserId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string? Role { get; init; }
    public bool IsPhoneVerified { get; init; }
    public string? FirebaseDeviceToken { get; init; }
    public string? Imei { get; init; }
}

public sealed class UpdateUserProfileRequest
{
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
}

public sealed class UpdateUserProfileResponse
{
    public UserProfileDto Profile { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class ChangePasswordRequest
{
    public string UserId { get; init; } = string.Empty;
    public string CurrentPassword { get; init; } = string.Empty;
    public string NewPassword { get; init; } = string.Empty;
    public string ConfirmPassword { get; init; } = string.Empty;
}

public sealed class ChangePasswordResponse
{
    public string UserId { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}
