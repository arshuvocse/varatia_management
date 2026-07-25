namespace OrderProcessAPI.Contracts;

public sealed class TenantAreaHomeResponse
{
    public int NotificationUnreadCount { get; init; }
    public TenantAreaWardDto ActiveWard { get; init; } = new();
    public IReadOnlyList<TenantAreaWardDto> Wards { get; init; } =
        Array.Empty<TenantAreaWardDto>();
    public IReadOnlyList<TenantAreaPostDto> FeedPreview { get; init; } =
        Array.Empty<TenantAreaPostDto>();
    public TenantAreaLocalizedListDto WardRules { get; init; } = new();
    public IReadOnlyList<string> LocationOptions { get; init; } =
        Array.Empty<string>();
    public TenantAreaEmergencyHelplineDto EmergencyHelpline { get; init; } =
        new()
        {
            Label = "Emergency",
            Phone = "999",
        };
}

public sealed class TenantAreaWardsResponse
{
    public IReadOnlyList<TenantAreaWardDto> Wards { get; init; } =
        Array.Empty<TenantAreaWardDto>();
}

public sealed class TenantAreaPostsResponse
{
    public IReadOnlyList<TenantAreaPostDto> Posts { get; init; } =
        Array.Empty<TenantAreaPostDto>();
    public int Page { get; init; }
    public int Limit { get; init; }
    public int TotalCount { get; init; }
    public int TotalPages { get; init; }
}

public sealed class CreateTenantAreaPostRequest
{
    public string TenantId { get; init; } = string.Empty;
    public string WardId { get; init; } = string.Empty;
    public string PostType { get; init; } = string.Empty;
    public string Details { get; init; } = string.Empty;
    public TenantAreaPostLocationDto Location { get; init; } = new();
    public string Privacy { get; init; } = string.Empty;
    public IReadOnlyList<TenantAreaPostAttachmentRequest> Attachments { get; init; } =
        Array.Empty<TenantAreaPostAttachmentRequest>();
}

public sealed class CreateTenantAreaPostResponse
{
    public TenantAreaPostDto Post { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class TenantAreaWardDto
{
    public string Id { get; init; } = string.Empty;
    public TenantAreaLocalizedTextDto Title { get; init; } = new();
    public string TitleEn { get; init; } = string.Empty;
    public string Area { get; init; } = string.Empty;
    public int MemberCount { get; init; }
    public TenantAreaLocalizedTextDto MemberLabel { get; init; } = new();
    public bool Selected { get; init; }
    public bool Verified { get; init; }
}

public sealed class TenantAreaPostDto
{
    public string Id { get; init; } = string.Empty;
    public string TenantId { get; init; } = string.Empty;
    public string WardId { get; init; } = string.Empty;
    public string PostType { get; init; } = string.Empty;
    public string Category { get; init; } = string.Empty;
    public string Details { get; init; } = string.Empty;
    public TenantAreaPostLocationDto Location { get; init; } = new();
    public string Privacy { get; init; } = string.Empty;
    public IReadOnlyList<TenantAreaPostAttachmentDto> Attachments { get; init; } =
        Array.Empty<TenantAreaPostAttachmentDto>();
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
}

public sealed class TenantAreaPostLocationDto
{
    public string Label { get; init; } = string.Empty;
    public decimal? Latitude { get; init; }
    public decimal? Longitude { get; init; }
}

public sealed class TenantAreaPostAttachmentRequest
{
    public string FileName { get; init; } = string.Empty;
    public string Url { get; init; } = string.Empty;
}

public sealed class TenantAreaPostAttachmentDto
{
    public string FileName { get; init; } = string.Empty;
    public string Url { get; init; } = string.Empty;
}

public sealed class TenantAreaLocalizedTextDto
{
    public string Bn { get; init; } = string.Empty;
    public string En { get; init; } = string.Empty;
}

public sealed class TenantAreaLocalizedListDto
{
    public IReadOnlyList<string> Bn { get; init; } = Array.Empty<string>();
    public IReadOnlyList<string> En { get; init; } = Array.Empty<string>();
}

public sealed class TenantAreaEmergencyHelplineDto
{
    public string Label { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
}
