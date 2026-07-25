using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IDhakaPoliceZoneService
{
    Task<IReadOnlyList<DhakaPoliceZoneDto>> GetZoneWardCoveragesAsync(
        string? zoneId = null,
        string? stationId = null,
        CancellationToken cancellationToken = default);

    Task<DhakaPoliceCascadingOptionsResponse> GetCascadingOptionsAsync(
        string? zoneId = null,
        string? stationId = null,
        CancellationToken cancellationToken = default);
}
