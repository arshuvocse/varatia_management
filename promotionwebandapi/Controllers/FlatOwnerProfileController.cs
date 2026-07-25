using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/flat-owner")]
public sealed class FlatOwnerProfileController : ControllerBase
{
    private readonly IFlatOwnerProfileService _profileService;

    public FlatOwnerProfileController(IFlatOwnerProfileService profileService)
    {
        _profileService = profileService;
    }

    [HttpGet("profile/{userId}")]
    public async Task<ActionResult<FlatOwnerProfileResponse>> GetProfile(
        string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _profileService.GetProfileAsync(
                userId,
                cancellationToken);

            return Ok(response);
        }
        catch (FlatOwnerProfileValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (FlatOwnerProfileNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (FlatOwnerProfileRoleException exception)
        {
            return StatusCode(
                StatusCodes.Status403Forbidden,
                new { message = exception.Message });
        }
    }
}
