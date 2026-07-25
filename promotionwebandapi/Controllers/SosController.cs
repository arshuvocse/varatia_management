using Microsoft.AspNetCore.Mvc;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

[ApiController]
[Route("api/sos")]
public class SosController(SosStore sosStore) : ControllerBase
{
    [HttpPost("trigger")]
    public IActionResult TriggerAlert([FromBody] SosAlertTriggerModel model)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, message = "Invalid data." });
        }

        var id = sosStore.TriggerAlert(model);
        return Ok(new { success = true, alertId = id, message = "SOS alert sent successfully." });
    }

    [HttpGet("contacts/{userId}")]
    public IActionResult GetContacts(string userId)
    {
        var contacts = sosStore.GetContacts(userId);
        return Ok(new { success = true, data = contacts });
    }

    [HttpPost("contacts")]
    public IActionResult AddContact([FromBody] SosEmergencyContactInputModel model)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, message = "Invalid data." });
        }

        var newContact = sosStore.AddContact(model);
        return Ok(new { success = true, data = newContact, message = "Contact added successfully." });
    }

    [HttpDelete("contacts/{userId}/{id}")]
    public IActionResult RemoveContact(string userId, int id)
    {
        sosStore.RemoveContact(id, userId);
        return Ok(new { success = true, message = "Contact removed successfully." });
    }

    [HttpPost("location")]
    public IActionResult UpdateLocation([FromBody] SosLocationUpdateModel model)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, message = "Invalid data." });
        }

        sosStore.UpdateLocation(model);
        return Ok(new { success = true, message = "Location updated successfully." });
    }

    [HttpGet("services")]
    public IActionResult GetEmergencyServices()
    {
        var services = sosStore.GetEmergencyServices();
        return Ok(new { success = true, data = services });
    }

    [HttpGet("safety-tips")]
    public IActionResult GetSafetyTips()
    {
        var tips = sosStore.GetSafetyTips();
        return Ok(new { success = true, data = tips });
    }

    [HttpPost("evidence")]
    public IActionResult SaveEvidence([FromBody] SosEvidenceInputModel model)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false, message = "Invalid data." });
        }

        sosStore.SaveEvidence(model);
        return Ok(new { success = true, message = "Evidence saved successfully." });
    }
}
