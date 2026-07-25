using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IFlatOwnerProfileService
{
    Task<FlatOwnerProfileResponse> GetProfileAsync(
        string userId,
        CancellationToken cancellationToken = default);
}
