namespace OrderProcessAPI.Contracts;

public sealed class FlatOwnerProfileResponse
{
    public string UserId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string Role { get; init; } = string.Empty;
    public bool IsPhoneVerified { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
    public int TotalPosts { get; init; }
    public int ActivePosts { get; init; }
    public string PaymentMonth { get; init; } = string.Empty;
    public string PaymentStatus { get; init; } = string.Empty;
    public bool AccessAllowed { get; init; }
}
