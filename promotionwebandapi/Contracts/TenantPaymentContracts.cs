namespace OrderProcessAPI.Contracts;

public sealed class ConfirmTenantPaymentRequest
{
    public string TenantId { get; init; } = string.Empty;
    public string MonthLabel { get; init; } = string.Empty;
    public int Amount { get; init; }
    public string PaymentMethod { get; init; } = string.Empty;
    public IReadOnlyList<string> PaymentTypes { get; init; } =
        Array.Empty<string>();
}

public sealed class ConfirmTenantPaymentResponse
{
    public TenantProfileDto Tenant { get; init; } = new();
    public RentPaymentDto Payment { get; init; } = new();
    public string PropertyId { get; init; } = string.Empty;
    public string PropertyName { get; init; } = string.Empty;
    public int DueAmount { get; init; }
    public string Message { get; init; } = string.Empty;
}

public sealed class GetRentPaymentsResponse
{
    public List<RentPaymentDto> Payments { get; init; } = new();
}
