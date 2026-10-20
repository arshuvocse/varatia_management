using PromotionWeb.Models;

namespace PromotionWeb.Services;

public interface IVaratiaAdminService
{
    Task<AdminTeachLearnViewModel> GetTeachLearnDataAsync(
        string? postType = null,
        string? verification = null,
        string? search = null,
        CancellationToken cancellationToken = default);

    Task<bool> ToggleTutorPostVerificationAsync(
        string postId,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteTutorPostAsync(
        string postId,
        CancellationToken cancellationToken = default);

    Task<AdminVaratiaManagementViewModel> GetVaratiaManagementDataAsync(
        string? search = null,
        string? statusFilter = null,
        string? tab = null,
        string? category = null,
        CancellationToken cancellationToken = default);

    Task<bool> ToggleGeneralPostStatusAsync(
        int postId,
        CancellationToken cancellationToken = default);

    Task<bool> ToggleGeneralPostVerificationAsync(
        int postId,
        CancellationToken cancellationToken = default);

    Task<bool> DeleteGeneralPostAsync(
        int postId,
        CancellationToken cancellationToken = default);

    Task<bool> GrantPostingCreditsAsync(
        string userId,
        int credits,
        CancellationToken cancellationToken = default);

    Task<bool> UpdateRegistrationFeeAsync(
        decimal fee,
        bool isActive,
        CancellationToken cancellationToken = default);
}
