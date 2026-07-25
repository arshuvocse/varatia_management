using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/account")]
public sealed class VaratiaAccountController : ControllerBase
{
    private readonly IAccountService _accountService;

    public VaratiaAccountController(IAccountService accountService)
    {
        _accountService = accountService;
    }

    [HttpGet("profile/{userId}")]
    public async Task<ActionResult<UserProfileDto>> GetProfile(
        string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _accountService.GetProfileAsync(
                userId,
                cancellationToken);

            return Ok(response);
        }
        catch (AccountValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (AccountNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpPut("profile/{userId}")]
    public async Task<ActionResult<UpdateUserProfileResponse>> UpdateProfile(
        string userId,
        [FromBody] UpdateUserProfileRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _accountService.UpdateProfileAsync(
                userId,
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (AccountValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (AccountNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (AccountConflictException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpPost("change-password")]
    public async Task<ActionResult<ChangePasswordResponse>> ChangePassword(
        [FromBody] ChangePasswordRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _accountService.ChangePasswordAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (AccountValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (AccountNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
        catch (AccountSecurityException exception)
        {
            return Unauthorized(new { message = exception.Message });
        }
    }
}
