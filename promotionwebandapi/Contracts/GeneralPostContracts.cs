namespace OrderProcessAPI.Contracts;

public sealed class CreateGeneralPostRequest
{
    public string UserId { get; init; } = string.Empty;
    public string Category { get; init; } = string.Empty; // 'rent' or 'sale'
    public string? TenantType { get; init; } // 'family', 'bachelor_male', 'bachelor_female'
    public string Title { get; init; } = string.Empty;
    public decimal Price { get; init; }
    public decimal? Advance { get; init; }
    public bool UtilityIncluded { get; init; }
    public string DivisionId { get; init; } = string.Empty;
    public string AreaId { get; init; } = string.Empty;
    public string? FullAddress { get; init; }
    public string? Street { get; init; }
    public decimal? Latitude { get; init; }
    public decimal? Longitude { get; init; }

    // Features
    public int Bedrooms { get; init; } = 1;
    public int Bathrooms { get; init; } = 1;
    public int Kitchens { get; init; } = 1;
    public int Balconies { get; init; } = 0;
    public bool HasGas { get; init; }
    public bool HasLift { get; init; }
    public bool HasGenerator { get; init; }
    public bool HasParking { get; init; }

    public string? Description { get; init; }
    public string? MediaInfo { get; set; }
    public List<Microsoft.AspNetCore.Http.IFormFile>? Files { get; set; }
}

public sealed class CreateGeneralPostResponse
{
    public int Id { get; init; }
    public string Message { get; init; } = string.Empty;
}

public sealed class GeneralPostDto
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? TenantType { get; set; }
    public string Title { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal? Advance { get; set; }
    public bool UtilityIncluded { get; set; }
    public string DivisionId { get; set; } = string.Empty;
    public string DivisionNameBn { get; set; } = string.Empty;
    public string AreaId { get; set; } = string.Empty;
    public string AreaNameBn { get; set; } = string.Empty;
    public string? FullAddress { get; set; }
    public string? Street { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public int Bedrooms { get; set; }
    public int Bathrooms { get; set; }
    public int Kitchens { get; set; }
    public int Balconies { get; set; }
    public bool HasGas { get; set; }
    public bool HasLift { get; set; }
    public bool HasGenerator { get; set; }
    public bool HasParking { get; set; }
    public string? Description { get; set; }
    public string? MediaInfo { get; set; }
    public string? ImageUrl { get; set; }
    public IReadOnlyList<string> MediaUrls { get; set; } = Array.Empty<string>();
    public int PhotoCount { get; set; }
    public int LikeCount { get; set; }
    public int CommentCount { get; set; }
    public bool IsLikedByViewer { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
    public DateTime UpdatedOn { get; set; }
}

public sealed class GeneralPostLikeRequest
{
    public string UserId { get; init; } = string.Empty;
}

public sealed class GeneralPostLikeResponse
{
    public int PostId { get; init; }
    public bool IsLiked { get; init; }
    public int LikeCount { get; init; }
}

public sealed class CreateGeneralPostCommentRequest
{
    public string UserId { get; init; } = string.Empty;
    public string CommentText { get; init; } = string.Empty;
}

public sealed class GeneralPostCommentDto
{
    public int Id { get; init; }
    public int PostId { get; init; }
    public string UserId { get; init; } = string.Empty;
    public string CommentText { get; init; } = string.Empty;
    public DateTime CreatedOn { get; init; }
    public DateTime UpdatedOn { get; init; }
}
