namespace PromotionWeb.Contracts;

public sealed class SmartBazarRegisterRequest
{
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string ConfirmPassword { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public string? Email { get; init; }
}

public sealed class SmartBazarLoginRequest
{
    public string PhoneNumber { get; init; } = string.Empty;
    public string Password { get; init; } = string.Empty;
    public string? Role { get; init; }
}

public sealed class SmartBazarAuthResponse
{
    public string UserId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public string? ShopCode { get; init; }
    public DateTime CreatedAt { get; init; }
    public string Message { get; init; } = string.Empty;
}
