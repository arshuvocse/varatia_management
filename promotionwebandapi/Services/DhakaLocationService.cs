using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class DhakaLocationService : IDhakaLocationService
{
    private const string DivisionsWithAreasQuery = """
        SELECT Id, NameBn, DisplayOrder
        FROM dbo.DhakaDivisions
        ORDER BY DisplayOrder;

        SELECT Id, DivisionId, NameBn, DisplayOrder
        FROM dbo.DhakaAreas
        ORDER BY DivisionId, DisplayOrder;
        """;

    private readonly SqlConnectionFactory _connectionFactory;

    public DhakaLocationService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<DhakaDivisionDto>> GetDivisionsAsync(
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var command = new CommandDefinition(
            DivisionsWithAreasQuery,
            cancellationToken: cancellationToken);

        using var multi = await connection.QueryMultipleAsync(command);
        var divisions = (await multi.ReadAsync<DhakaDivisionDto>()).ToList();
        var areas = (await multi.ReadAsync<DhakaAreaDto>()).ToList();
        var areasByDivision = areas
            .GroupBy(area => area.DivisionId, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                group => group.Key,
                group => (IReadOnlyList<DhakaAreaDto>)group.ToList(),
                StringComparer.OrdinalIgnoreCase);

        return divisions
            .Select(division => new DhakaDivisionDto
            {
                Id = division.Id,
                NameBn = division.NameBn,
                DisplayOrder = division.DisplayOrder,
                Areas = areasByDivision.GetValueOrDefault(division.Id)
                    ?? Array.Empty<DhakaAreaDto>(),
            })
            .ToList();
    }

    public async Task<IReadOnlyList<DhakaAreaDto>> GetAreasAsync(
        string? divisionId = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var normalizedDivisionId = string.IsNullOrWhiteSpace(divisionId)
            ? null
            : divisionId.Trim();

        var command = new CommandDefinition(
            """
            SELECT Id, DivisionId, NameBn, DisplayOrder
            FROM dbo.DhakaAreas
            WHERE @DivisionId IS NULL OR DivisionId = @DivisionId
            ORDER BY DivisionId, DisplayOrder;
            """,
            new { DivisionId = normalizedDivisionId },
            cancellationToken: cancellationToken);

        return (await connection.QueryAsync<DhakaAreaDto>(command)).ToList();
    }
}
