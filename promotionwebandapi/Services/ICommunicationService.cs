using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface ICommunicationService
{
    Task<IReadOnlyList<CommunicationMessageDto>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task<CreateCommunicationMessageResponse> CreateAsync(
        CreateCommunicationMessageRequest request,
        CancellationToken cancellationToken = default);
}
