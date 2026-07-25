namespace OrderProcessAPI.Contracts;

public sealed class DhakaDivisionDto
{
    public string Id { get; init; } = string.Empty;
    public string NameBn { get; init; } = string.Empty;
    public int DisplayOrder { get; init; }
    public IReadOnlyList<DhakaAreaDto> Areas { get; init; } =
        Array.Empty<DhakaAreaDto>();
}

public sealed class DhakaAreaDto
{
    public string Id { get; init; } = string.Empty;
    public string DivisionId { get; init; } = string.Empty;
    public string NameBn { get; init; } = string.Empty;
    public int DisplayOrder { get; init; }
}
