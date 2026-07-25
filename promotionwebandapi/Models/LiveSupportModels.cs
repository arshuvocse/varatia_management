using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class LiveSupportSession
{
    public string SessionId { get; init; } = "";
    public string UserName { get; init; } = "";
    public string UserPhone { get; init; } = "";
    public string Status { get; init; } = "Active";
    public int? AssignedAgentId { get; init; }
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
}

public sealed class LiveSupportMessage
{
    public int MessageId { get; init; }
    public string SessionId { get; init; } = "";
    public string SenderType { get; init; } = ""; // "Guest" or "Agent"
    public int? SenderId { get; init; } // Null for Guest, Agent's Id for Agent
    public string MessageText { get; init; } = "";
    public DateTime SentAt { get; init; } = DateTime.UtcNow;
    
    // Virtual properties for display
    public string? AgentName { get; init; }
    public string? AgentProfilePictureUrl { get; init; }
}

public sealed class StartLiveSessionRequest
{
    [Required]
    public string SessionId { get; set; } = "";
    [Required]
    public string Name { get; set; } = "";
    [Required, RegularExpression(@"^01\d{9}$", ErrorMessage = "সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন।")]
    public string Phone { get; set; } = "";
}

public sealed class SendLiveMessageRequest
{
    [Required]
    public string SessionId { get; set; } = "";
    [Required]
    public string MessageText { get; set; } = "";
}
