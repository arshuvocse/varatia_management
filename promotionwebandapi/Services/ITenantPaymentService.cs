using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface ITenantPaymentService
{
    Task<ConfirmTenantPaymentResponse> ConfirmPaymentAsync(
        ConfirmTenantPaymentRequest request,
        CancellationToken cancellationToken = default);

    Task<GetRentPaymentsResponse> GetRentPaymentsAsync(
        string userId,
        CancellationToken cancellationToken = default);
}
