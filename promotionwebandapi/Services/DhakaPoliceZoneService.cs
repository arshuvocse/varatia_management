using System.Data;
using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class DhakaPoliceZoneService : IDhakaPoliceZoneService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public DhakaPoliceZoneService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<DhakaPoliceZoneDto>> GetZoneWardCoveragesAsync(
        string? zoneId = null,
        string? stationId = null,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var command = new CommandDefinition(
            "dbo.GetDhakaPoliceZoneWardCoverage",
            new
            {
                ZoneId = NormalizeFilter(zoneId),
                StationId = NormalizeFilter(stationId),
            },
            commandType: CommandType.StoredProcedure,
            cancellationToken: cancellationToken);

        using var multi = await connection.QueryMultipleAsync(command);
        var zones = (await multi.ReadAsync<DhakaPoliceZoneDto>()).ToList();
        var stations = (await multi.ReadAsync<DhakaPoliceStationDto>()).ToList();
        var wards = (await multi.ReadAsync<DhakaPoliceStationWardCoverageDto>()).ToList();

        var wardsByStation = wards
            .GroupBy(ward => ward.StationId, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                group => group.Key,
                group => (IReadOnlyList<DhakaPoliceStationWardCoverageDto>)group.ToList(),
                StringComparer.OrdinalIgnoreCase);

        var stationsByZone = stations
            .Select(station => new DhakaPoliceStationDto
            {
                Id = station.Id,
                ZoneId = station.ZoneId,
                NameBn = station.NameBn,
                NameEn = station.NameEn,
                DisplayOrder = station.DisplayOrder,
                Wards = wardsByStation.GetValueOrDefault(station.Id)
                    ?? Array.Empty<DhakaPoliceStationWardCoverageDto>(),
            })
            .GroupBy(station => station.ZoneId, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                group => group.Key,
                group => (IReadOnlyList<DhakaPoliceStationDto>)group.ToList(),
                StringComparer.OrdinalIgnoreCase);

        return zones
            .Select(zone => new DhakaPoliceZoneDto
            {
                Id = zone.Id,
                NameBn = zone.NameBn,
                NameEn = zone.NameEn,
                DisplayOrder = zone.DisplayOrder,
                Stations = stationsByZone.GetValueOrDefault(zone.Id)
                    ?? Array.Empty<DhakaPoliceStationDto>(),
            })
            .ToList();
    }

    public async Task<DhakaPoliceCascadingOptionsResponse> GetCascadingOptionsAsync(
        string? zoneId = null,
        string? stationId = null,
        CancellationToken cancellationToken = default)
    {
        var zones = await GetZoneWardCoveragesAsync(
            zoneId,
            stationId,
            cancellationToken);

        var stations = zones
            .SelectMany(zone => zone.Stations)
            .ToList();

        var wards = stations
            .SelectMany(station => station.Wards)
            .ToList();

        return new DhakaPoliceCascadingOptionsResponse
        {
            Zones = zones
                .Select(zone => new DhakaPoliceZoneOptionDto
                {
                    Id = zone.Id,
                    NameBn = zone.NameBn,
                    NameEn = zone.NameEn,
                })
                .ToList(),
            Stations = stations
                .Select(station => new DhakaPoliceStationOptionDto
                {
                    Id = station.Id,
                    ZoneId = station.ZoneId,
                    NameBn = station.NameBn,
                    NameEn = station.NameEn,
                })
                .ToList(),
            Wards = wards
                .Select(ward => new DhakaPoliceWardOptionDto
                {
                    Id = ward.Id,
                    StationId = ward.StationId,
                    WardNo = ward.WardNo,
                    NameBn = $"ওয়ার্ড {ward.WardNo}",
                    NameEn = $"Ward {ward.WardNo}",
                    CoverageNoteBn = ward.CoverageNoteBn,
                    CoverageNoteEn = ward.CoverageNoteEn,
                })
                .ToList(),
        };
    }

    private static string? NormalizeFilter(string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? null
            : value.Trim();
    }
}
