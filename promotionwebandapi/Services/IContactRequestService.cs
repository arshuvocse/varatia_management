using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IContactRequestService
{
    Task<ContactAccessStatusResponse> CreateRequestAsync(
        CreateContactAccessRequest request,
        CancellationToken cancellationToken = default);

    Task<ContactAccessStatusResponse> GetStatusAsync(
        string requesterUserId,
        string postType,
        int postId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ContactAccessRequestDto>> GetAllRequestsAsync(
        string? statusFilter = null,
        CancellationToken cancellationToken = default);

    Task<bool> ReviewRequestAsync(
        int requestId,
        bool approve,
        string adminId,
        string? reason = null,
        CancellationToken cancellationToken = default);
}
