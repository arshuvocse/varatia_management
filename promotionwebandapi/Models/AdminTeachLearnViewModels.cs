namespace PromotionWeb.Models;

public sealed class AdminTeachLearnViewModel
{
    public IReadOnlyList<AdminTutorPostItemViewModel> Posts { get; init; } = [];
    public int TotalPosts { get; init; }
    public int TutorPostsCount { get; init; }
    public int RequestPostsCount { get; init; }
    public int VerifiedPostsCount { get; init; }
    public string? FilterType { get; init; }
    public string? FilterVerification { get; init; }
    public string? SearchQuery { get; init; }
}

public sealed class AdminTutorPostItemViewModel
{
    public string Id { get; init; } = "";
    public string TenantId { get; init; } = "";
    public string PostType { get; init; } = "";
    public string Name { get; init; } = "";
    public string RoleBn { get; init; } = "";
    public string RoleEn { get; init; } = "";
    public string SubjectBn { get; init; } = "";
    public string SubjectEn { get; init; } = "";
    public string AreaBn { get; init; } = "";
    public string AreaEn { get; init; } = "";
    public string PriceBn { get; init; } = "";
    public string PriceEn { get; init; } = "";
    public string AvailabilityBn { get; init; } = "";
    public string AvailabilityEn { get; init; } = "";
    public string BadgeBn { get; init; } = "";
    public string BadgeEn { get; init; } = "";
    public string Rating { get; init; } = "5.0";
    public string Phone { get; init; } = "";
    public string DescriptionBn { get; init; } = "";
    public string DescriptionEn { get; init; } = "";
    public string ExperienceBn { get; init; } = "";
    public string ExperienceEn { get; init; } = "";
    public string FulfillmentStatus { get; init; } = "not_got";
    public string? Remarks { get; init; }
    public bool IsVerified { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
}
