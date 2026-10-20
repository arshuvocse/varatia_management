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

public sealed class SmartBazarAddBalanceRequest
{
    public string ShopkeeperId { get; init; } = string.Empty;
    public decimal Amount { get; init; }
}

public sealed class SmartBazarSaleRequest
{
    public string ShopkeeperId { get; init; } = string.Empty;
    public string CustomerPhone { get; init; } = string.Empty;
    public decimal Amount { get; init; }
    public decimal CommissionAmount { get; init; }
    public string? Remarks { get; init; }
}
