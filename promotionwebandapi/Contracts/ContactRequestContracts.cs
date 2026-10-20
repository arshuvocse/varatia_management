namespace OrderProcessAPI.Contracts;

public sealed class CreateContactAccessRequest
{
    public string RequesterUserId { get; init; } = string.Empty;
    public string PostType { get; init; } = "GeneralPost"; // "GeneralPost" or "TutorPost"
    public int PostId { get; init; }
    public string? Purpose { get; init; }
}

public sealed class ContactAccessRequestDto
{
    public int Id { get; init; }
    public string RequesterUserId { get; init; } = string.Empty;
    public string RequesterName { get; init; } = string.Empty;
    public string RequesterPhone { get; init; } = string.Empty;
    public string PostType { get; init; } = string.Empty;
    public int PostId { get; init; }
    public string PostTitle { get; init; } = string.Empty;
    public string PostCategory { get; init; } = string.Empty;
    public string PostOwnerUserId { get; init; } = string.Empty;
    public string PostOwnerName { get; init; } = string.Empty;
    public string? Purpose { get; init; }
    public string Status { get; init; } = "pending"; // "pending", "approved", "rejected"
    public string? RejectionReason { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? ReviewedAt { get; init; }
}

public sealed class ContactAccessStatusResponse
{
    public int RequestId { get; init; }
    public string Status { get; init; } = "none"; // "none", "pending", "approved", "rejected"
    public bool IsApproved { get; init; }
    public string? RevealedPhoneNumber { get; init; }
    public string? Message { get; init; }
}

public sealed class ReviewContactRequestInput
{
    public int RequestId { get; init; }
    public bool Approve { get; init; }
    public string? Reason { get; init; }
}
