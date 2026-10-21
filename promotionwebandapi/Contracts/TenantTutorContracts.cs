namespace OrderProcessAPI.Contracts;

public sealed class CreateTenantTutorPostRequest
{
    public string TenantId { get; init; } = string.Empty;
    public string Type { get; init; } = string.Empty;
    public string PostType { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public TenantTutorLocalizedTextDto Role { get; init; } = new();
    public TenantTutorLocalizedTextDto Subject { get; init; } = new();
    public string SubjectBn { get; init; } = string.Empty;
    public string SubjectEn { get; init; } = string.Empty;
    public TenantTutorLocalizedTextDto Area { get; init; } = new();
    public TenantTutorLocationDto Location { get; init; } = new();
    public TenantTutorLocalizedTextDto Price { get; init; } = new();
    public TenantTutorLocalizedTextDto Fee { get; init; } = new();
    public TenantTutorLocalizedTextDto Availability { get; init; } = new();
    public string Phone { get; init; } = string.Empty;
    public string ContactNumber { get; init; } = string.Empty;
    public TenantTutorLocalizedTextDto Description { get; init; } = new();
    public TenantTutorLocalizedTextDto Experience { get; init; } = new();
    public string FulfillmentStatus { get; init; } = string.Empty;
    public string Remarks { get; init; } = string.Empty;
    public string Rating { get; init; } = string.Empty;
    public bool? Verified { get; init; }
}

public sealed class TenantTutorPostListResponse
{
    public IReadOnlyList<TenantTutorPostDto> Posts { get; init; } =
        Array.Empty<TenantTutorPostDto>();
    public int Page { get; init; }
    public bool HasMore { get; init; }
}

public sealed class CreateTenantTutorPostResponse
{
    public string Message { get; init; } = string.Empty;
    public TenantTutorCreatedPostDto Post { get; init; } = new();
}

public sealed class TenantTutorPostDto
{
    public string Id { get; init; } = string.Empty;
    public string Type { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public TenantTutorLocalizedTextDto Role { get; init; } = new();
    public TenantTutorLocalizedTextDto Subject { get; init; } = new();
    public TenantTutorLocalizedTextDto Area { get; init; } = new();
    public TenantTutorLocalizedTextDto Price { get; init; } = new();
    public TenantTutorLocalizedTextDto Availability { get; init; } = new();
    public TenantTutorLocalizedTextDto Badge { get; init; } = new();
    public string Rating { get; init; } = string.Empty;
    public string Phone { get; init; } = string.Empty;
    public TenantTutorLocalizedTextDto Description { get; init; } = new();
    public TenantTutorLocalizedTextDto Experience { get; init; } = new();
    public string FulfillmentStatus { get; init; } = string.Empty;
    public string Remarks { get; init; } = string.Empty;
    public bool Verified { get; init; }
}

public sealed class TenantTutorCreatedPostDto
{
    public string Id { get; init; } = string.Empty;
    public string Type { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
}

public sealed class TenantTutorLocalizedTextDto
{
    public string Bn { get; init; } = string.Empty;
    public string En { get; init; } = string.Empty;
}

public sealed class TenantTutorLocationDto
{
    public string Label { get; init; } = string.Empty;
    public string Bn { get; init; } = string.Empty;
    public string En { get; init; } = string.Empty;
}

public sealed class SaveTutorBdjobsProfileRequest
{
    public string UserId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string Gender { get; init; } = "পুরুষ";
    public string City { get; init; } = "Dhaka";
    public string CurrentLocation { get; init; } = string.Empty;
    public string UniversityType { get; init; } = string.Empty;
    public string UniversityName { get; init; } = string.Empty;
    public string Department { get; init; } = string.Empty;
    public string SscMedium { get; init; } = string.Empty;
    public IReadOnlyList<string> PreferredLocations { get; init; } = Array.Empty<string>();
    public IReadOnlyList<string> PreferredSubjects { get; init; } = Array.Empty<string>();
    public IReadOnlyList<string> ClassesToTeach { get; init; } = Array.Empty<string>();
    public string ExpectedFee { get; init; } = string.Empty;
    public string DaysPerWeek { get; init; } = string.Empty;
    public int CompletionScore { get; init; }
}

public sealed class TutorBdjobsProfileDto
{
    public string Id { get; init; } = string.Empty;
    public string UserId { get; init; } = string.Empty;
    public string FullName { get; init; } = string.Empty;
    public string PhoneNumber { get; init; } = string.Empty;
    public string Gender { get; init; } = string.Empty;
    public string City { get; init; } = string.Empty;
    public string CurrentLocation { get; init; } = string.Empty;
    public string UniversityType { get; init; } = string.Empty;
    public string UniversityName { get; init; } = string.Empty;
    public string Department { get; init; } = string.Empty;
    public string SscMedium { get; init; } = string.Empty;
    public IReadOnlyList<string> PreferredLocations { get; init; } = Array.Empty<string>();
    public IReadOnlyList<string> PreferredSubjects { get; init; } = Array.Empty<string>();
    public IReadOnlyList<string> ClassesToTeach { get; init; } = Array.Empty<string>();
    public string ExpectedFee { get; init; } = string.Empty;
    public string DaysPerWeek { get; init; } = string.Empty;
    public int CompletionScore { get; init; }
    public DateTime? CreatedAt { get; init; }
    public DateTime? UpdatedAt { get; init; }
}

public sealed class TutorBdjobsProfileResponse
{
    public string Message { get; init; } = string.Empty;
    public TutorBdjobsProfileDto? Profile { get; init; }
}

