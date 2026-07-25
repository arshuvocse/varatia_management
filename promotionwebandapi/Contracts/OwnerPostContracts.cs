namespace OrderProcessAPI.Contracts;

public sealed class CreateOwnerPostRequest
{
    public string OwnerId { get; init; } = string.Empty;
    public string PostType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public OwnerPostPropertyRequest Property { get; init; } = new();
    public IReadOnlyList<OwnerPostPhotoRequest> Photos { get; init; } =
        Array.Empty<OwnerPostPhotoRequest>();
    public IReadOnlyList<string> TenantPreferences { get; init; } =
        Array.Empty<string>();
    public OwnerPostRoomsRequest Rooms { get; init; } = new();
    public IReadOnlyList<string> Amenities { get; init; } = Array.Empty<string>();
    public OwnerPostPricingRequest Pricing { get; init; } = new();
    public int AreaSqft { get; init; }
    public string ContactNumber { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public string FulfillmentStatus { get; init; } = string.Empty;
    public string Remarks { get; init; } = string.Empty;
}

public sealed class OwnerPostPropertyRequest
{
    public string Location { get; init; } = string.Empty;
    public decimal? Lat { get; init; }
    public decimal? Long { get; init; }
    public string LatLongAddress { get; init; } = string.Empty;
    public string BuildingId { get; init; } = string.Empty;
    public string FloorId { get; init; } = string.Empty;
    public string PropertyId { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
}

public sealed class OwnerPostPhotoRequest
{
    public string FileName { get; init; } = string.Empty;
    public string Url { get; init; } = string.Empty;
}

public sealed class OwnerPostRoomsRequest
{
    public int TotalFloors { get; init; }
    public int Bedrooms { get; init; }
    public int Balconies { get; init; }
    public int Dining { get; init; }
    public int Drawing { get; init; }
    public int Bathrooms { get; init; }
    public int Kitchens { get; init; }
}

public sealed class OwnerPostPricingRequest
{
    public int MonthlyRent { get; init; }
    public int Advance { get; init; }
    public int ServiceCharge { get; init; }
}

public sealed class CreateOwnerPostResponse
{
    public OwnerPostDto Post { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class OwnerPostListResponse
{
    public IReadOnlyList<OwnerPostDto> Posts { get; init; } =
        Array.Empty<OwnerPostDto>();
}

public sealed class OwnerPostDto
{
    public string Id { get; init; } = string.Empty;
    public string OwnerId { get; init; } = string.Empty;
    public string PostType { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public OwnerPostPropertyDto Property { get; init; } = new();
    public IReadOnlyList<OwnerPostPhotoDto> Photos { get; init; } =
        Array.Empty<OwnerPostPhotoDto>();
    public IReadOnlyList<string> TenantPreferences { get; init; } =
        Array.Empty<string>();
    public OwnerPostRoomsDto Rooms { get; init; } = new();
    public IReadOnlyList<string> Amenities { get; init; } = Array.Empty<string>();
    public OwnerPostPricingDto Pricing { get; init; } = new();
    public int AreaSqft { get; init; }
    public string ContactNumber { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public string FulfillmentStatus { get; init; } = string.Empty;
    public string Remarks { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
}

public sealed class OwnerPostPropertyDto
{
    public string Location { get; init; } = string.Empty;
    public decimal? Lat { get; init; }
    public decimal? Long { get; init; }
    public string LatLongAddress { get; init; } = string.Empty;
    public string BuildingId { get; init; } = string.Empty;
    public string FloorId { get; init; } = string.Empty;
    public string PropertyId { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
}

public sealed class OwnerPostPhotoDto
{
    public string FileName { get; init; } = string.Empty;
    public string Url { get; init; } = string.Empty;
}

public sealed class OwnerPostRoomsDto
{
    public int TotalFloors { get; init; }
    public int Bedrooms { get; init; }
    public int Balconies { get; init; }
    public int Dining { get; init; }
    public int Drawing { get; init; }
    public int Bathrooms { get; init; }
    public int Kitchens { get; init; }
}

public sealed class OwnerPostPricingDto
{
    public int MonthlyRent { get; init; }
    public int Advance { get; init; }
    public int ServiceCharge { get; init; }
}
