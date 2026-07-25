using System.Text.Json.Serialization;

namespace OrderProcessAPI.Contracts;

public sealed class CreateBuildingRequest
{
    [JsonPropertyName("user_id")]
    public string UserId { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Location { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public int TotalFloors { get; init; }
    public decimal? Latitude { get; init; }
    public decimal? Longitude { get; init; }
    public string ZoneId { get; init; } = string.Empty;
    public string StationId { get; init; } = string.Empty;
    public int? WardId { get; init; }
}

public sealed class UpdateBuildingRequest
{
    [JsonPropertyName("user_id")]
    public string UserId { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string Location { get; init; } = string.Empty;
    public string Address { get; init; } = string.Empty;
    public int TotalFloors { get; init; }
    public decimal? Latitude { get; init; }
    public decimal? Longitude { get; init; }
    public string ZoneId { get; init; } = string.Empty;
    public string StationId { get; init; } = string.Empty;
    public int? WardId { get; init; }
}

public sealed class CreateBuildingResponse
{
    public BuildingBlockDto Building { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class UpdateBuildingResponse
{
    public BuildingBlockDto Building { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class DeleteBuildingResponse
{
    public string BuildingId { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class CreateFloorRequest
{
    public string BuildingId { get; init; } = string.Empty;
    public string Label { get; init; } = string.Empty;
    public int TotalUnits { get; init; }
}

public sealed class UpdateFloorRequest
{
    public string BuildingId { get; init; } = string.Empty;
    public string Label { get; init; } = string.Empty;
    public int TotalUnits { get; init; }
}

public sealed class CreateFloorResponse
{
    public BuildingFloorDto Floor { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class UpdateFloorResponse
{
    public BuildingFloorDto Floor { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class DeleteFloorResponse
{
    public string FloorId { get; init; } = string.Empty;
    public string BuildingId { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class CreatePropertyRequest
{
    public string Name { get; init; } = string.Empty;
    public int MonthlyRent { get; init; }
    public string BuildingId { get; init; } = string.Empty;
    public string FloorId { get; init; } = string.Empty;
}

public sealed class UpdatePropertyRequest
{
    public string Name { get; init; } = string.Empty;
    public int MonthlyRent { get; init; }
    public string BuildingId { get; init; } = string.Empty;
    public string FloorId { get; init; } = string.Empty;
}

public sealed class CreatePropertyResponse
{
    public PropertyUnitDto Property { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class UpdatePropertyResponse
{
    public PropertyUnitDto Property { get; init; } = new();
    public string Message { get; init; } = string.Empty;
}

public sealed class DeletePropertyResponse
{
    public string PropertyId { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

// GET Responses
public sealed class GetBuildingsResponse
{
    public List<BuildingBlockDto> Buildings { get; init; } = new();
}

public sealed class GetFloorsResponse
{
    public List<BuildingFloorDto> Floors { get; init; } = new();
}

public sealed class GetPropertiesResponse
{
    public List<PropertyUnitDto> Properties { get; init; } = new();
}
