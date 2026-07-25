namespace PromotionWeb.Models;

public sealed class LocationCatalog
{
    public IReadOnlyList<LocationOption> Divisions { get; init; } = [];
    public IReadOnlyList<LocationOption> Districts { get; init; } = [];
    public IReadOnlyList<LocationOption> Thanas { get; init; } = [];
}

public sealed class LocationOption
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public int? ParentId { get; init; }
}
