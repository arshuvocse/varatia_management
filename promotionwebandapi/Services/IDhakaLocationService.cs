using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IDhakaLocationService
{
    Task<IReadOnlyList<DhakaDivisionDto>> GetDivisionsAsync(
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DhakaAreaDto>> GetAreasAsync(
        string? divisionId = null,
        CancellationToken cancellationToken = default);
}
