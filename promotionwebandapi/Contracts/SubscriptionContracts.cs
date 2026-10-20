namespace OrderProcessAPI.Contracts;

public sealed class SubscriptionPlanDto
{
    public int Id { get; init; }
    public string ServiceCode { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
    public string TargetRole { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public decimal Fee { get; init; }
    public int DeliveryDays { get; init; }
    public bool IsActive { get; init; }
}

public sealed class UserSubscriptionDto
{
    public int Id { get; init; }
    public string UserId { get; init; } = string.Empty;
    public string UserName { get; init; } = string.Empty;
    public string UserPhone { get; init; } = string.Empty;
    public string UserRole { get; init; } = string.Empty;
    public string ServiceCode { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
    public decimal Amount { get; init; }
    public string TransactionId { get; init; } = string.Empty;
    public string PaymentStatus { get; init; } = "pending";
    public string SubscriptionStatus { get; init; } = "in_progress";
    public string? UserRequirements { get; init; }
    public int DeliveryDays { get; init; }
    public DateTime SubscribedAt { get; init; }
    public DateTime DeadlineAt { get; init; }
    public int RemainingDays { get; init; }
    public bool IsExpired { get; init; }
    public DateTime? FulfilledAt { get; init; }
    public string? AdminNotes { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class InitiateSubscriptionPaymentRequest
{
    public string UserId { get; set; } = string.Empty;
    public string ServiceCode { get; set; } = string.Empty;
    public string? UserRequirements { get; set; }
}

public sealed class UpdateSubscriptionPlanRequest
{
    public string ServiceCode { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Fee { get; set; }
    public int DeliveryDays { get; set; }
    public bool IsActive { get; set; } = true;
}

public sealed class UpdateSubscriptionStatusRequest
{
    public int SubscriptionId { get; set; }
    public string SubscriptionStatus { get; set; } = string.Empty;
    public string? AdminNotes { get; set; }
}
