using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/dhaka-police-zones")]
public sealed class DhakaPoliceZonesController : ControllerBase
{
    private readonly IDhakaPoliceZoneService _dhakaPoliceZoneService;

    public DhakaPoliceZonesController(IDhakaPoliceZoneService dhakaPoliceZoneService)
    {
        _dhakaPoliceZoneService = dhakaPoliceZoneService;
    }

    [HttpGet("ward-coverages")]
    public async Task<ActionResult<IReadOnlyList<DhakaPoliceZoneDto>>> GetWardCoverages(
        [FromQuery] string? zoneId,
        [FromQuery] string? stationId,
        CancellationToken cancellationToken)
    {
        var coverages = await _dhakaPoliceZoneService.GetZoneWardCoveragesAsync(
            zoneId,
            stationId,
            cancellationToken);

        return Ok(coverages);
    }

    [HttpGet("cascading-options")]
    public async Task<ActionResult<DhakaPoliceCascadingOptionsResponse>> GetCascadingOptions(
        [FromQuery] string? zoneId,
        [FromQuery] string? stationId,
        CancellationToken cancellationToken)
    {
        var options = await _dhakaPoliceZoneService.GetCascadingOptionsAsync(
            zoneId,
            stationId,
            cancellationToken);

        return Ok(options);
    }
}
