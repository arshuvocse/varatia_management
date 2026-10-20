namespace PromotionWeb.Models;

public sealed class AdminVaratiaManagementViewModel
{
    public IReadOnlyList<AdminGeneralPostItemViewModel> GeneralPosts { get; init; } = [];
    public int TotalGeneralPosts { get; init; }
    public int ActiveGeneralPostsCount { get; init; }
    public int VerifiedGeneralPostsCount { get; init; }
    public string? CategoryFilter { get; init; }
    public IReadOnlyList<AdminTenantItemViewModel> Tenants { get; init; } = [];
    public IReadOnlyList<AdminPropertyItemViewModel> Properties { get; init; } = [];
    public IReadOnlyList<AdminRentPaymentItemViewModel> Payments { get; init; } = [];
    public IReadOnlyList<AdminPaymentHistoryItemViewModel> SslCommerzPayments { get; init; } = [];
    public IReadOnlyList<AdminAppUserItemViewModel> Users { get; init; } = [];
    public int TotalTenants { get; init; }
    public int TotalProperties { get; init; }
    public int RentedPropertiesCount { get; init; }
    public int AvailablePropertiesCount { get; init; }
    public int TotalRentDue { get; init; }
    public int TotalBuildings { get; init; }
    public IReadOnlyList<OrderProcessAPI.Contracts.SubscriptionPlanDto> SubscriptionPlans { get; init; } = [];
    public IReadOnlyList<OrderProcessAPI.Contracts.UserSubscriptionDto> Subscriptions { get; init; } = [];
    public decimal TotalSubscriptionFeesCollected { get; init; }
    public decimal RegistrationFee { get; init; } = 50.00m;
    public bool IsRegistrationFeeActive { get; init; } = true;
    public decimal TotalRegistrationFeesCollected { get; init; }
    public decimal TotalMonthlyFeesCollected { get; init; }
    public string? SearchQuery { get; init; }
    public string? StatusFilter { get; init; }
    public string ActiveTab { get; init; } = "tenants";
}

public sealed class AdminGeneralPostItemViewModel
{
    public int Id { get; init; }
    public string UserId { get; init; } = "";
    public string UserName { get; init; } = "";
    public string UserPhone { get; init; } = "";
    public string UserRole { get; init; } = "";
    public string Category { get; init; } = "";
    public string? TenantType { get; init; }
    public string Title { get; init; } = "";
    public decimal Price { get; init; }
    public decimal? Advance { get; init; }
    public bool UtilityIncluded { get; init; }
    public string DivisionId { get; init; } = "";
    public string AreaId { get; init; } = "";
    public string? FullAddress { get; init; }
    public string? Description { get; init; }
    public string? MediaInfo { get; init; }
    public int MediaCount { get; init; }
    public int FreePostsUsed { get; init; }
    public int PaidCreditsBalance { get; init; }
    public string Status { get; init; } = "active";
    public bool IsVerified { get; init; }
    public DateTime CreatedOn { get; init; }
    public DateTime UpdatedOn { get; init; }
}

public sealed class AdminPaymentHistoryItemViewModel
{
    public int Id { get; init; }
    public string UserId { get; init; } = "";
    public string UserName { get; init; } = "";
    public string UserPhone { get; init; } = "";
    public string UserRole { get; init; } = "";
    public string TransactionId { get; init; } = "";
    public string PaymentType { get; init; } = "";
    public decimal Amount { get; init; }
    public string Status { get; init; } = "";
    public string Gateway { get; init; } = "SSLCOMMERZ";
    public DateTime? PaymentDate { get; init; }
    public DateTime CreatedOn { get; init; }
}

public sealed class AdminTenantItemViewModel
{
    public string Id { get; init; } = "";
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public string Nid { get; init; } = "";
    public string? PropertyId { get; init; }
    public string PropertyName { get; init; } = "";
    public string BuildingName { get; init; } = "";
    public string Location { get; init; } = "";
    public int MonthlyRent { get; init; }
    public int DueAmount { get; init; }
    public string Status { get; init; } = "";
}

public sealed class AdminPropertyItemViewModel
{
    public string Id { get; init; } = "";
    public string Name { get; init; } = "";
    public string BuildingName { get; init; } = "";
    public string Location { get; init; } = "";
    public int MonthlyRent { get; init; }
    public string Status { get; init; } = "available";
    public string? TenantName { get; init; }
    public int DueAmount { get; init; }
}

public sealed class AdminRentPaymentItemViewModel
{
    public int Id { get; init; }
    public string PropertyId { get; init; } = "";
    public string PropertyName { get; init; } = "";
    public string? TenantName { get; init; }
    public string MonthLabel { get; init; } = "";
    public int Amount { get; init; }
    public string Status { get; init; } = "";
    public DateTime? PaidOn { get; init; }
}

public sealed class AdminAppUserItemViewModel
{
    public Guid Id { get; init; }
    public string FullName { get; init; } = "";
    public string PhoneNumber { get; init; } = "";
    public string? Role { get; init; }
    public bool IsPhoneVerified { get; init; }
    public bool IsRegistrationFeePaid { get; init; }
    public string? RegistrationFeeTransactionId { get; init; }
    public DateTime? RegistrationFeePaidAt { get; init; }
    public DateTime CreatedAt { get; init; }
}
