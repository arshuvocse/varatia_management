using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IManagementDataService
{
    Task<ManagementBootstrapResponse> GetBootstrapAsync(
        CancellationToken cancellationToken = default);
}
