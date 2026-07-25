namespace OrderProcessAPI.Contracts;

public sealed class DhakaPoliceZoneDto
{
    public string Id { get; init; } = string.Empty;
    public string NameBn { get; init; } = string.Empty;
    public string NameEn { get; init; } = string.Empty;
    public int DisplayOrder { get; init; }
    public IReadOnlyList<DhakaPoliceStationDto> Stations { get; init; } =
        Array.Empty<DhakaPoliceStationDto>();
}

public sealed class DhakaPoliceStationDto
{
    public string Id { get; init; } = string.Empty;
    public string ZoneId { get; init; } = string.Empty;
    public string NameBn { get; init; } = string.Empty;
    public string NameEn { get; init; } = string.Empty;
    public int DisplayOrder { get; init; }
    public IReadOnlyList<DhakaPoliceStationWardCoverageDto> Wards { get; init; } =
        Array.Empty<DhakaPoliceStationWardCoverageDto>();
}

public sealed class DhakaPoliceStationWardCoverageDto
{
    public int Id { get; init; }
    public string StationId { get; init; } = string.Empty;
    public int WardNo { get; init; }
    public string? CoverageNoteBn { get; init; }
    public string? CoverageNoteEn { get; init; }
    public int DisplayOrder { get; init; }
}

public sealed class DhakaPoliceCascadingOptionsResponse
{
    public IReadOnlyList<DhakaPoliceZoneOptionDto> Zones { get; init; } =
        Array.Empty<DhakaPoliceZoneOptionDto>();
    public IReadOnlyList<DhakaPoliceStationOptionDto> Stations { get; init; } =
        Array.Empty<DhakaPoliceStationOptionDto>();
    public IReadOnlyList<DhakaPoliceWardOptionDto> Wards { get; init; } =
        Array.Empty<DhakaPoliceWardOptionDto>();
}

public sealed class DhakaPoliceZoneOptionDto
{
    public string Id { get; init; } = string.Empty;
    public string NameBn { get; init; } = string.Empty;
    public string NameEn { get; init; } = string.Empty;
}

public sealed class DhakaPoliceStationOptionDto
{
    public string Id { get; init; } = string.Empty;
    public string ZoneId { get; init; } = string.Empty;
    public string NameBn { get; init; } = string.Empty;
    public string NameEn { get; init; } = string.Empty;
}

public sealed class DhakaPoliceWardOptionDto
{
    public int Id { get; init; }
    public string StationId { get; init; } = string.Empty;
    public int WardNo { get; init; }
    public string NameBn { get; init; } = string.Empty;
    public string NameEn { get; init; } = string.Empty;
    public string? CoverageNoteBn { get; init; }
    public string? CoverageNoteEn { get; init; }
}
