using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IAccountService
{
    Task<UserProfileDto> GetProfileAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task<UpdateUserProfileResponse> UpdateProfileAsync(
        string userId,
        UpdateUserProfileRequest request,
        CancellationToken cancellationToken = default);

    Task<ChangePasswordResponse> ChangePasswordAsync(
        ChangePasswordRequest request,
        CancellationToken cancellationToken = default);
}
