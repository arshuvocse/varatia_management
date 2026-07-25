using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<ActionResult<RegisterUserResponse>> Register(
        [FromBody] RegisterUserRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.RegisterAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (AuthValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (DuplicatePhoneNumberException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginUserResponse>> Login(
        [FromBody] LoginUserRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.LoginAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (AuthValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (InvalidCredentialsException exception)
        {
            return Unauthorized(new { message = exception.Message });
        }
    }

    [HttpPost("verify-otp")]
    public async Task<ActionResult<VerifyOtpResponse>> VerifyOtp(
        [FromBody] VerifyOtpRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.VerifyOtpAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (AuthValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (AuthNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpPost("resend-otp")]
    public async Task<ActionResult<ResendOtpResponse>> ResendOtp(
        [FromBody] ResendOtpRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.ResendOtpAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (AuthValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (AuthNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpPost("forgot-password")]
    public async Task<ActionResult<ForgotPasswordResponse>> ForgotPassword(
        [FromBody] ForgotPasswordRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.RequestPasswordResetAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (AuthValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (AuthNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpPost("reset-password")]
    public async Task<ActionResult<ResetPasswordResponse>> ResetPassword(
        [FromBody] ResetPasswordRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.ResetPasswordAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (AuthValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (AuthNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpPost("device-info")]
    public async Task<ActionResult<UpdateDeviceInfoResponse>> UpdateDeviceInfo(
        [FromBody] UpdateDeviceInfoRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.UpdateDeviceInfoAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (AuthValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
        catch (AuthNotFoundException exception)
        {
            return NotFound(new { message = exception.Message });
        }
    }

    [HttpPost("send-otp")]
    public async Task<ActionResult<SendOtpResponse>> SendOtp(
        [FromBody] SendOtpRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _authService.SendOtpAsync(
                request,
                cancellationToken);

            if (response.IsError)
            {
                return BadRequest(response);
            }

            return Ok(response);
        }
        catch (AuthValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }
}
