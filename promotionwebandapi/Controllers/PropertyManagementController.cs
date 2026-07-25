using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/property-management")]
public sealed class PropertyManagementController : ControllerBase
{
    private readonly IPropertyManagementService _propertyManagementService;

    public PropertyManagementController(
        IPropertyManagementService propertyManagementService)
    {
        _propertyManagementService = propertyManagementService;
    }

    [HttpGet("buildings")]
    public async Task<ActionResult<GetBuildingsResponse>> GetBuildings(
        [FromQuery] string user_id,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(user_id))
        {
            return BadRequest(new { message = "user_id is required." });
        }

        var response = await _propertyManagementService.GetBuildingsAsync(
            user_id,
            cancellationToken);

        return Ok(response);
    }

    [HttpGet("floors")]
    public async Task<ActionResult<GetFloorsResponse>> GetFloors(
        [FromQuery] string buildingId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(buildingId))
        {
            return BadRequest(new { message = "buildingId is required." });
        }

        var response = await _propertyManagementService.GetFloorsAsync(
            buildingId,
            cancellationToken);

        return Ok(response);
    }

    [HttpGet("units")]
    public async Task<ActionResult<GetPropertiesResponse>> GetProperties(
        [FromQuery] string user_id,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(user_id))
        {
            return BadRequest(new { message = "user_id is required." });
        }

        var response = await _propertyManagementService.GetPropertiesAsync(
            user_id,
            cancellationToken);

        return Ok(response);
    }

    [HttpPost("buildings")]
    public async Task<ActionResult<CreateBuildingResponse>> CreateBuilding(
        [FromBody] CreateBuildingRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _propertyManagementService.CreateBuildingAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (PropertyManagementValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (PropertyManagementConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpPut("buildings/{buildingId}")]
    public async Task<ActionResult<UpdateBuildingResponse>> UpdateBuilding(
        string buildingId,
        [FromBody] UpdateBuildingRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _propertyManagementService.UpdateBuildingAsync(
                buildingId,
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (PropertyManagementValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (PropertyManagementNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (PropertyManagementConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpDelete("buildings/{buildingId}")]
    public async Task<ActionResult<DeleteBuildingResponse>> DeleteBuilding(
        string buildingId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _propertyManagementService.DeleteBuildingAsync(
                buildingId,
                cancellationToken);

            return Ok(response);
        }
        catch (PropertyManagementValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (PropertyManagementNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (PropertyManagementConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpPost("floors")]
    public async Task<ActionResult<CreateFloorResponse>> CreateFloor(
        [FromBody] CreateFloorRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _propertyManagementService.CreateFloorAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (PropertyManagementValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (PropertyManagementNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (PropertyManagementConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpPut("floors/{floorId}")]
    public async Task<ActionResult<UpdateFloorResponse>> UpdateFloor(
        string floorId,
        [FromBody] UpdateFloorRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _propertyManagementService.UpdateFloorAsync(
                floorId,
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (PropertyManagementValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (PropertyManagementNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (PropertyManagementConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpDelete("floors/{floorId}")]
    public async Task<ActionResult<DeleteFloorResponse>> DeleteFloor(
        string floorId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _propertyManagementService.DeleteFloorAsync(
                floorId,
                cancellationToken);

            return Ok(response);
        }
        catch (PropertyManagementValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (PropertyManagementNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (PropertyManagementConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpPost("units")]
    public async Task<ActionResult<CreatePropertyResponse>> CreateProperty(
        [FromBody] CreatePropertyRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _propertyManagementService.CreatePropertyAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (PropertyManagementValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (PropertyManagementNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (PropertyManagementConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpPut("units/{propertyId}")]
    public async Task<ActionResult<UpdatePropertyResponse>> UpdateProperty(
        string propertyId,
        [FromBody] UpdatePropertyRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _propertyManagementService.UpdatePropertyAsync(
                propertyId,
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (PropertyManagementValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (PropertyManagementNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (PropertyManagementConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpDelete("units/{propertyId}")]
    public async Task<ActionResult<DeletePropertyResponse>> DeleteProperty(
        string propertyId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _propertyManagementService.DeletePropertyAsync(
                propertyId,
                cancellationToken);

            return Ok(response);
        }
        catch (PropertyManagementValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (PropertyManagementNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (PropertyManagementConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }
}
