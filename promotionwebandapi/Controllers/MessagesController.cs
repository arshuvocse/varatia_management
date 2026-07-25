using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/messages")]
public sealed class MessagesController : ControllerBase
{
    private readonly ICommunicationService _communicationService;

    public MessagesController(ICommunicationService communicationService)
    {
        _communicationService = communicationService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CommunicationMessageDto>>> GetAll(
        CancellationToken cancellationToken)
    {
        var response = await _communicationService.GetAllAsync(cancellationToken);
        return Ok(response);
    }

    [HttpPost]
    public async Task<ActionResult<CreateCommunicationMessageResponse>> Create(
        [FromBody] CreateCommunicationMessageRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response = await _communicationService.CreateAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
        catch (CommunicationValidationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }
}
