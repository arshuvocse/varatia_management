using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using PromotionWeb.Hubs;
using PromotionWeb.Models;
using PromotionWeb.Services;

namespace PromotionWeb.Controllers;

public sealed class ChatController(
    ChatStore chatStore,
    IWebHostEnvironment environment,
    IHubContext<ChatHub> hubContext) : Controller
{
    private static readonly Dictionary<string, string> AllowedTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        ["image/jpeg"] = ".jpg",
        ["image/png"] = ".png",
        ["image/webp"] = ".webp",
        ["image/gif"] = ".gif"
    };

    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(6 * 1024 * 1024)]
    public async Task<IActionResult> UploadImage(int conversationId, IFormFile? image)
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (userId is null)
        {
            return Unauthorized(new { message = "Session expired." });
        }

        if (image is null || image.Length == 0 || image.Length > 5 * 1024 * 1024
            || !AllowedTypes.TryGetValue(image.ContentType, out var extension)
            || !await HasValidImageSignature(image, extension))
        {
            return BadRequest(new { message = "Select a JPEG, PNG, WebP or GIF image up to 5 MB." });
        }

        ChatConversationViewModel conversation;
        try
        {
            conversation = chatStore.OpenForUser(conversationId, userId.Value);
        }
        catch (InvalidOperationException)
        {
            return Forbid();
        }

        var folder = Path.Combine(environment.ContentRootPath, "uploads", "chat");
        Directory.CreateDirectory(folder);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        await using (var stream = System.IO.File.Create(Path.Combine(folder, fileName)))
        {
            await image.CopyToAsync(stream);
        }

        var message = chatStore.SendImage(conversationId, userId.Value, $"/uploads/chat/{fileName}");
        var recipientUserId = userId.Value == conversation.CustomerUserId
            ? conversation.ShopkeeperUserId
            : conversation.CustomerUserId;

        await hubContext.Clients.Group($"conversation:{conversationId}").SendAsync("ReceiveMessage", message);
        await hubContext.Clients.Group($"user:{recipientUserId}").SendAsync("ReceiveNotification", new
        {
            conversationId,
            message.SenderName,
            MessageText = "Sent an image",
            message.SentAt,
            conversation.CustomerName,
            conversation.CustomerPhone,
            conversation.ShopName,
            conversation.ShopkeeperPhone
        });

        return Json(message);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(12 * 1024 * 1024)]
    public async Task<IActionResult> UploadAudio(int conversationId, IFormFile? audio)
    {
        var userId = HttpContext.Session.GetInt32("UserId");
        if (userId is null)
        {
            return Unauthorized(new { message = "Session expired." });
        }

        if (audio is null || audio.Length == 0 || audio.Length > 10 * 1024 * 1024)
        {
            return BadRequest(new { message = "Recording must be up to 10 MB." });
        }

        var extension = audio.ContentType?.ToLowerInvariant() switch
        {
            "audio/webm" => ".webm",
            "audio/ogg" => ".ogg",
            "audio/wav" or "audio/x-wav" => ".wav",
            "audio/mp3" or "audio/mpeg" => ".mp3",
            "audio/mp4" or "audio/m4a" or "audio/x-m4a" => ".m4a",
            "audio/aac" => ".aac",
            _ => ".webm"
        };

        ChatConversationViewModel conversation;
        try
        {
            conversation = chatStore.OpenForUser(conversationId, userId.Value);
        }
        catch (InvalidOperationException)
        {
            return Forbid();
        }

        var folder = Path.Combine(environment.ContentRootPath, "uploads", "chat");
        Directory.CreateDirectory(folder);
        var fileName = $"voice_{Guid.NewGuid():N}{extension}";
        await using (var stream = System.IO.File.Create(Path.Combine(folder, fileName)))
        {
            await audio.CopyToAsync(stream);
        }

        var message = chatStore.SendAudio(conversationId, userId.Value, $"/uploads/chat/{fileName}");
        var recipientUserId = userId.Value == conversation.CustomerUserId
            ? conversation.ShopkeeperUserId
            : conversation.CustomerUserId;

        await hubContext.Clients.Group($"conversation:{conversationId}").SendAsync("ReceiveMessage", message);
        await hubContext.Clients.Group($"user:{recipientUserId}").SendAsync("ReceiveNotification", new
        {
            conversationId,
            message.SenderName,
            MessageText = "🎤 Sent a voice message",
            message.SentAt,
            conversation.CustomerName,
            conversation.CustomerPhone,
            conversation.ShopName,
            conversation.ShopkeeperPhone
        });

        return Json(message);
    }

    private static async Task<bool> HasValidImageSignature(IFormFile image, string extension)
    {
        var header = new byte[12];
        await using var stream = image.OpenReadStream();
        var bytesRead = await stream.ReadAsync(header);

        return extension switch
        {
            ".jpg" => bytesRead >= 3 && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF,
            ".png" => bytesRead >= 8 && header[..8].SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 }),
            ".gif" => bytesRead >= 6
                && (header[..6].SequenceEqual("GIF87a"u8.ToArray()) || header[..6].SequenceEqual("GIF89a"u8.ToArray())),
            ".webp" => bytesRead >= 12
                && header[..4].SequenceEqual("RIFF"u8.ToArray())
                && header[8..12].SequenceEqual("WEBP"u8.ToArray()),
            _ => false
        };
    }
}
