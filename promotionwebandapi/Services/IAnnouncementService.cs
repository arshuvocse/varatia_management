using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IAnnouncementService
{
    Task<IReadOnlyList<AnnouncementDto>> GetActiveAnnouncementsAsync(CancellationToken cancellationToken);
}
