using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Services;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/announcements")]
public sealed class AnnouncementsController : ControllerBase
{
    private readonly IAnnouncementService _announcementService;

    public AnnouncementsController(IAnnouncementService announcementService)
    {
        _announcementService = announcementService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<AnnouncementDto>>> GetActive(CancellationToken cancellationToken)
    {
        var announcements = await _announcementService.GetActiveAnnouncementsAsync(cancellationToken);
        return Ok(announcements);
    }
}
