using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/dhaka-locations")]
public sealed class DhakaLocationsController : ControllerBase
{
    private readonly IDhakaLocationService _dhakaLocationService;

    public DhakaLocationsController(IDhakaLocationService dhakaLocationService)
    {
        _dhakaLocationService = dhakaLocationService;
    }

    [HttpGet("divisions")]
    public async Task<ActionResult<IReadOnlyList<DhakaDivisionDto>>> GetDivisions(
        CancellationToken cancellationToken)
    {
        var divisions = await _dhakaLocationService.GetDivisionsAsync(
            cancellationToken);

        return Ok(divisions);
    }

    [HttpGet("areas")]
    public async Task<ActionResult<IReadOnlyList<DhakaAreaDto>>> GetAreas(
        [FromQuery] string? divisionId,
        CancellationToken cancellationToken)
    {
        var areas = await _dhakaLocationService.GetAreasAsync(
            divisionId,
            cancellationToken);

        return Ok(areas);
    }
}
