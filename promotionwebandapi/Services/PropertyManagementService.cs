using Dapper;
using Microsoft.Data.SqlClient;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class PropertyManagementService : IPropertyManagementService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public PropertyManagementService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<GetBuildingsResponse> GetBuildingsAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var buildings = await connection.QueryAsync<BuildingBlockDto>(
            new CommandDefinition(
                "sp_GetBuildingsByOwner",
                new { UserId = userId },
                commandType: System.Data.CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        return new GetBuildingsResponse
        {
            Buildings = buildings.ToList()
        };
    }

    public async Task<GetFloorsResponse> GetFloorsAsync(
        string buildingId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var floors = await connection.QueryAsync<BuildingFloorDto>(
            new CommandDefinition(
                "sp_GetFloorsByBuildingId",
                new { BuildingId = buildingId },
                commandType: System.Data.CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        return new GetFloorsResponse
        {
            Floors = floors.ToList()
        };
    }

    public async Task<GetPropertiesResponse> GetPropertiesAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var properties = await connection.QueryAsync<PropertyUnitDto>(
            new CommandDefinition(
                "sp_GetPropertiesByOwner",
                new { UserId = userId },
                commandType: System.Data.CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        return new GetPropertiesResponse
        {
            Properties = properties.ToList()
        };
    }

    public async Task<CreateBuildingResponse> CreateBuildingAsync(
        CreateBuildingRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = request.UserId.Trim();
        var name = request.Name.Trim();
        var location = NormalizeBuildingLocation(request);
        var address = NormalizeOptionalText(request.Address);
        var zoneId = NormalizeOptionalText(request.ZoneId);
        var stationId = NormalizeOptionalText(request.StationId);
        ValidateBuilding(
            name,
            location,
            request.TotalFloors,
            request.Latitude,
            request.Longitude,
            zoneId,
            stationId,
            request.WardId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await EnsureBuildingLocationSelectionAsync(
            connection,
            zoneId,
            stationId,
            request.WardId,
            cancellationToken);
        await EnsureUniqueBuildingNameAsync(
            connection,
            name,
            buildingIdToIgnore: null,
            cancellationToken);

        var nextNumericId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT ISNULL(MAX(TRY_CONVERT(int, SUBSTRING(Id, 3, LEN(Id) - 2))), 0) + 1
                FROM dbo.Buildings
                WHERE Id LIKE 'B-%';
                """,
                cancellationToken: cancellationToken));

        var buildingId = $"B-{nextNumericId:D2}";

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.Buildings
                (
                    Id,
                    UserId,
                    Name,
                    TotalFloors,
                    Location,
                    Address,
                    Latitude,
                    Longitude,
                    ZoneId,
                    StationId,
                    WardId
                )
                VALUES
                (
                    @Id,
                    @UserId,
                    @Name,
                    @TotalFloors,
                    @Location,
                    @Address,
                    @Latitude,
                    @Longitude,
                    @ZoneId,
                    @StationId,
                    @WardId
                );
                """,
                new
                {
                    Id = buildingId,
                    UserId = EmptyToNull(userId),
                    Name = name,
                    TotalFloors = request.TotalFloors,
                    Location = location,
                    Address = EmptyToNull(address),
                    request.Latitude,
                    request.Longitude,
                    ZoneId = EmptyToNull(zoneId),
                    StationId = EmptyToNull(stationId),
                    request.WardId,
                },
                cancellationToken: cancellationToken));

        await InsertActivityAsync(
            connection,
            "Building created",
            $"{name} was added to the property directory.",
            cancellationToken);

        return new CreateBuildingResponse
        {
            Building = new BuildingBlockDto
            {
                Id = buildingId,
                UserId = userId,
                Name = name,
                TotalFloors = request.TotalFloors,
                Location = location,
                Address = address,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                ZoneId = zoneId,
                StationId = stationId,
                WardId = request.WardId,
            },
            Message = "Building created successfully.",
        };
    }

    public async Task<UpdateBuildingResponse> UpdateBuildingAsync(
        string buildingId,
        UpdateBuildingRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedBuildingId = buildingId.Trim();
        var userId = request.UserId.Trim();
        var name = request.Name.Trim();
        var location = NormalizeBuildingLocation(request);
        var address = NormalizeOptionalText(request.Address);
        var zoneId = NormalizeOptionalText(request.ZoneId);
        var stationId = NormalizeOptionalText(request.StationId);
        ValidateBuilding(
            name,
            location,
            request.TotalFloors,
            request.Latitude,
            request.Longitude,
            zoneId,
            stationId,
            request.WardId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await EnsureBuildingExistsAsync(
            connection,
            normalizedBuildingId,
            cancellationToken);
        await EnsureBuildingLocationSelectionAsync(
            connection,
            zoneId,
            stationId,
            request.WardId,
            cancellationToken);
        await EnsureUniqueBuildingNameAsync(
            connection,
            name,
            normalizedBuildingId,
            cancellationToken);

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Buildings
                SET
                    UserId = @UserId,
                    Name = @Name,
                    TotalFloors = @TotalFloors,
                    Location = @Location,
                    Address = @Address,
                    Latitude = @Latitude,
                    Longitude = @Longitude,
                    ZoneId = @ZoneId,
                    StationId = @StationId,
                    WardId = @WardId
                WHERE Id = @BuildingId;

                UPDATE dbo.Properties
                SET Location = @Location
                WHERE BuildingId = @BuildingId;
                """,
                new
                {
                    BuildingId = normalizedBuildingId,
                    UserId = EmptyToNull(userId),
                    Name = name,
                    TotalFloors = request.TotalFloors,
                    Location = location,
                    Address = EmptyToNull(address),
                    request.Latitude,
                    request.Longitude,
                    ZoneId = EmptyToNull(zoneId),
                    StationId = EmptyToNull(stationId),
                    request.WardId,
                },
                cancellationToken: cancellationToken));

        await InsertActivityAsync(
            connection,
            "Building updated",
            $"{name} details were updated.",
            cancellationToken);

        return new UpdateBuildingResponse
        {
            Building = new BuildingBlockDto
            {
                Id = normalizedBuildingId,
                UserId = userId,
                Name = name,
                TotalFloors = request.TotalFloors,
                Location = location,
                Address = address,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                ZoneId = zoneId,
                StationId = stationId,
                WardId = request.WardId,
            },
            Message = "Building updated successfully.",
        };
    }

    public async Task<DeleteBuildingResponse> DeleteBuildingAsync(
        string buildingId,
        CancellationToken cancellationToken = default)
    {
        var normalizedBuildingId = buildingId.Trim();
        if (string.IsNullOrWhiteSpace(normalizedBuildingId))
        {
            throw new PropertyManagementValidationException(
                "Building id is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var building = await connection.QuerySingleOrDefaultAsync<BuildingLookup>(
            new CommandDefinition(
                """
                SELECT
                    Id,
                    COALESCE(UserId, '') AS UserId,
                    Name,
                    Location,
                    COALESCE(Address, '') AS Address,
                    Latitude,
                    Longitude,
                    COALESCE(ZoneId, '') AS ZoneId,
                    COALESCE(StationId, '') AS StationId,
                    WardId,
                    TotalFloors
                FROM dbo.Buildings
                WHERE Id = @BuildingId;
                """,
                new { BuildingId = normalizedBuildingId },
                cancellationToken: cancellationToken));

        if (building is null)
        {
            throw new PropertyManagementNotFoundException("Building was not found.");
        }

        var dependencies = await connection.QuerySingleAsync<DependencyLookup>(
            new CommandDefinition(
                """
                SELECT
                    (SELECT COUNT(*) FROM dbo.Floors WHERE BuildingId = @BuildingId) AS FloorCount,
                    (SELECT COUNT(*) FROM dbo.Properties WHERE BuildingId = @BuildingId) AS PropertyCount;
                """,
                new { BuildingId = normalizedBuildingId },
                cancellationToken: cancellationToken));

        if (dependencies.FloorCount > 0 || dependencies.PropertyCount > 0)
        {
            throw new PropertyManagementConflictException(
                "Remove linked floors and units before deleting this building.");
        }

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                DELETE FROM dbo.Buildings
                WHERE Id = @BuildingId;
                """,
                new { BuildingId = normalizedBuildingId },
                cancellationToken: cancellationToken));

        await InsertActivityAsync(
            connection,
            "Building deleted",
            $"{building.Name} was removed from the property directory.",
            cancellationToken);

        return new DeleteBuildingResponse
        {
            BuildingId = normalizedBuildingId,
            Message = "Building deleted successfully.",
        };
    }

    public async Task<CreateFloorResponse> CreateFloorAsync(
        CreateFloorRequest request,
        CancellationToken cancellationToken = default)
    {
        var buildingId = request.BuildingId.Trim();
        var label = NormalizeFloorLabel(request.Label);
        ValidateFloor(buildingId, label, request.TotalUnits);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await EnsureBuildingExistsAsync(connection, buildingId, cancellationToken);
        await EnsureUniqueFloorLabelAsync(
            connection,
            buildingId,
            label,
            floorIdToIgnore: null,
            cancellationToken);

        var nextNumericId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT ISNULL(MAX(TRY_CONVERT(int, SUBSTRING(Id, 3, LEN(Id) - 2))), 0) + 1
                FROM dbo.Floors
                WHERE Id LIKE 'F-%';
                """,
                cancellationToken: cancellationToken));

        var floorId = $"F-{nextNumericId:D2}";

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.Floors (Id, BuildingId, Label, TotalUnits)
                VALUES (@Id, @BuildingId, @Label, @TotalUnits);
                """,
                new
                {
                    Id = floorId,
                    BuildingId = buildingId,
                    Label = label,
                    TotalUnits = request.TotalUnits,
                },
                cancellationToken: cancellationToken));

        await InsertActivityAsync(
            connection,
            "Floor created",
            $"{label} was added under {buildingId}.",
            cancellationToken);

        return new CreateFloorResponse
        {
            Floor = new BuildingFloorDto
            {
                Id = floorId,
                BuildingId = buildingId,
                Label = label,
                TotalUnits = request.TotalUnits,
            },
            Message = "Floor created successfully.",
        };
    }

    public async Task<UpdateFloorResponse> UpdateFloorAsync(
        string floorId,
        UpdateFloorRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedFloorId = floorId.Trim();
        var buildingId = request.BuildingId.Trim();
        var label = NormalizeFloorLabel(request.Label);
        ValidateFloor(buildingId, label, request.TotalUnits);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        await EnsureFloorExistsAsync(connection, normalizedFloorId, cancellationToken);
        await EnsureBuildingExistsAsync(connection, buildingId, cancellationToken);
        await EnsureUniqueFloorLabelAsync(
            connection,
            buildingId,
            label,
            normalizedFloorId,
            cancellationToken);

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Floors
                SET
                    BuildingId = @BuildingId,
                    Label = @Label,
                    TotalUnits = @TotalUnits
                WHERE Id = @FloorId;

                UPDATE dbo.Properties
                SET BuildingId = @BuildingId,
                    Location = (SELECT Location FROM dbo.Buildings WHERE Id = @BuildingId)
                WHERE FloorId = @FloorId;
                """,
                new
                {
                    FloorId = normalizedFloorId,
                    BuildingId = buildingId,
                    Label = label,
                    TotalUnits = request.TotalUnits,
                },
                cancellationToken: cancellationToken));

        await InsertActivityAsync(
            connection,
            "Floor updated",
            $"{label} was updated.",
            cancellationToken);

        return new UpdateFloorResponse
        {
            Floor = new BuildingFloorDto
            {
                Id = normalizedFloorId,
                BuildingId = buildingId,
                Label = label,
                TotalUnits = request.TotalUnits,
            },
            Message = "Floor updated successfully.",
        };
    }

    public async Task<DeleteFloorResponse> DeleteFloorAsync(
        string floorId,
        CancellationToken cancellationToken = default)
    {
        var normalizedFloorId = floorId.Trim();
        if (string.IsNullOrWhiteSpace(normalizedFloorId))
        {
            throw new PropertyManagementValidationException("Floor id is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var floor = await connection.QuerySingleOrDefaultAsync<FloorLookup>(
            new CommandDefinition(
                """
                SELECT Id, BuildingId, Label, TotalUnits
                FROM dbo.Floors
                WHERE Id = @FloorId;
                """,
                new { FloorId = normalizedFloorId },
                cancellationToken: cancellationToken));

        if (floor is null)
        {
            throw new PropertyManagementNotFoundException("Floor was not found.");
        }

        var propertyCount = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(*)
                FROM dbo.Properties
                WHERE FloorId = @FloorId;
                """,
                new { FloorId = normalizedFloorId },
                cancellationToken: cancellationToken));

        if (propertyCount > 0)
        {
            throw new PropertyManagementConflictException(
                "Remove linked units before deleting this floor.");
        }

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                DELETE FROM dbo.Floors
                WHERE Id = @FloorId;
                """,
                new { FloorId = normalizedFloorId },
                cancellationToken: cancellationToken));

        await InsertActivityAsync(
            connection,
            "Floor deleted",
            $"{floor.Label} was removed from {floor.BuildingId}.",
            cancellationToken);

        return new DeleteFloorResponse
        {
            FloorId = normalizedFloorId,
            BuildingId = floor.BuildingId,
            Message = "Floor deleted successfully.",
        };
    }

    public async Task<CreatePropertyResponse> CreatePropertyAsync(
        CreatePropertyRequest request,
        CancellationToken cancellationToken = default)
    {
        var name = request.Name.Trim();
        var buildingId = request.BuildingId.Trim();
        var floorId = request.FloorId.Trim();
        ValidateProperty(name, request.MonthlyRent, buildingId, floorId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var building = await EnsureBuildingLookupAsync(
            connection,
            buildingId,
            cancellationToken);
        var floor = await EnsureFloorLookupAsync(
            connection,
            floorId,
            cancellationToken);
        EnsureFloorBelongsToBuilding(floor, buildingId);
        await EnsureUniquePropertyNameAsync(
            connection,
            name,
            propertyIdToIgnore: null,
            cancellationToken);

        var nextNumericId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT ISNULL(MAX(TRY_CONVERT(int, SUBSTRING(Id, 3, LEN(Id) - 2))), 0) + 1
                FROM dbo.Properties
                WHERE Id LIKE 'P-%';
                """,
                cancellationToken: cancellationToken));

        var propertyId = $"P-{nextNumericId:D2}";

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.Properties
                (
                    Id,
                    Name,
                    Location,
                    MonthlyRent,
                    Status,
                    TenantName,
                    DueAmount,
                    BuildingId,
                    FloorId
                )
                VALUES
                (
                    @Id,
                    @Name,
                    @Location,
                    @MonthlyRent,
                    'available',
                    NULL,
                    @DueAmount,
                    @BuildingId,
                    @FloorId
                );
                """,
                new
                {
                    Id = propertyId,
                    Name = name,
                    Location = building.Location,
                    MonthlyRent = request.MonthlyRent,
                    DueAmount = request.MonthlyRent,
                    BuildingId = buildingId,
                    FloorId = floorId,
                },
                cancellationToken: cancellationToken));

        await InsertActivityAsync(
            connection,
            "Unit created",
            $"{name} was added to {building.Name} {floor.Label}.",
            cancellationToken);

        return new CreatePropertyResponse
        {
            Property = new PropertyUnitDto
            {
                Id = propertyId,
                Name = name,
                Location = building.Location,
                MonthlyRent = request.MonthlyRent,
                Status = "available",
                TenantName = null,
                DueAmount = request.MonthlyRent,
                BuildingId = buildingId,
                BuildingName = building.Name,
                FloorId = floorId,
                FloorLabel = floor.Label,
            },
            Message = "Unit created successfully.",
        };
    }

    public async Task<UpdatePropertyResponse> UpdatePropertyAsync(
        string propertyId,
        UpdatePropertyRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedPropertyId = propertyId.Trim();
        var name = request.Name.Trim();
        var buildingId = request.BuildingId.Trim();
        var floorId = request.FloorId.Trim();
        ValidateProperty(name, request.MonthlyRent, buildingId, floorId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var existingProperty = await EnsurePropertyLookupAsync(
            connection,
            normalizedPropertyId,
            cancellationToken);
        var building = await EnsureBuildingLookupAsync(
            connection,
            buildingId,
            cancellationToken);
        var floor = await EnsureFloorLookupAsync(
            connection,
            floorId,
            cancellationToken);
        EnsureFloorBelongsToBuilding(floor, buildingId);
        await EnsureUniquePropertyNameAsync(
            connection,
            name,
            normalizedPropertyId,
            cancellationToken);

        var dueAmount = string.Equals(
                existingProperty.Status,
                "available",
                StringComparison.OrdinalIgnoreCase)
            ? request.MonthlyRent
            : existingProperty.DueAmount;

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Properties
                SET
                    Name = @Name,
                    Location = @Location,
                    MonthlyRent = @MonthlyRent,
                    DueAmount = @DueAmount,
                    BuildingId = @BuildingId,
                    FloorId = @FloorId
                WHERE Id = @PropertyId;

                UPDATE dbo.Tenants
                SET PropertyId = @PropertyId
                WHERE PropertyId = @PropertyId;
                """,
                new
                {
                    PropertyId = normalizedPropertyId,
                    Name = name,
                    Location = building.Location,
                    MonthlyRent = request.MonthlyRent,
                    DueAmount = dueAmount,
                    BuildingId = buildingId,
                    FloorId = floorId,
                },
                cancellationToken: cancellationToken));

        await InsertActivityAsync(
            connection,
            "Unit updated",
            $"{name} details were updated.",
            cancellationToken);

        return new UpdatePropertyResponse
        {
            Property = new PropertyUnitDto
            {
                Id = normalizedPropertyId,
                Name = name,
                Location = building.Location,
                MonthlyRent = request.MonthlyRent,
                Status = existingProperty.Status,
                TenantName = existingProperty.TenantName,
                DueAmount = dueAmount,
                BuildingId = buildingId,
                BuildingName = building.Name,
                FloorId = floorId,
                FloorLabel = floor.Label,
            },
            Message = "Unit updated successfully.",
        };
    }

    public async Task<DeletePropertyResponse> DeletePropertyAsync(
        string propertyId,
        CancellationToken cancellationToken = default)
    {
        var normalizedPropertyId = propertyId.Trim();
        if (string.IsNullOrWhiteSpace(normalizedPropertyId))
        {
            throw new PropertyManagementValidationException("Unit id is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var property = await EnsurePropertyLookupAsync(
            connection,
            normalizedPropertyId,
            cancellationToken);

        if (!string.IsNullOrWhiteSpace(property.TenantName) ||
            string.Equals(property.Status, "rented", StringComparison.OrdinalIgnoreCase))
        {
            throw new PropertyManagementConflictException(
                "Remove the active tenant before deleting this unit.");
        }

        var tenantCount = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(*)
                FROM dbo.Tenants
                WHERE PropertyId = @PropertyId;
                """,
                new { PropertyId = normalizedPropertyId },
                cancellationToken: cancellationToken));

        if (tenantCount > 0)
        {
            throw new PropertyManagementConflictException(
                "Tenant records are still linked to this unit.");
        }

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                DELETE FROM dbo.RentPayments
                WHERE PropertyId = @PropertyId;

                DELETE FROM dbo.Properties
                WHERE Id = @PropertyId;
                """,
                new { PropertyId = normalizedPropertyId },
                cancellationToken: cancellationToken));

        await InsertActivityAsync(
            connection,
            "Unit deleted",
            $"{property.Name} was removed from the property directory.",
            cancellationToken);

        return new DeletePropertyResponse
        {
            PropertyId = normalizedPropertyId,
            Message = "Unit deleted successfully.",
        };
    }

    private static void ValidateBuilding(
        string name,
        string location,
        int totalFloors,
        decimal? latitude,
        decimal? longitude,
        string zoneId,
        string stationId,
        int? wardId)
    {
        if (string.IsNullOrWhiteSpace(name) || name.Length < 2)
        {
            throw new PropertyManagementValidationException(
                "Building name must contain at least 2 characters.");
        }

        if (string.IsNullOrWhiteSpace(location) || location.Length < 3)
        {
            throw new PropertyManagementValidationException(
                "Building location must contain at least 3 characters.");
        }

        if (totalFloors <= 0)
        {
            throw new PropertyManagementValidationException(
                "Total floors must be greater than zero.");
        }

        if (latitude is < -90 or > 90)
        {
            throw new PropertyManagementValidationException(
                "Latitude must be between -90 and 90.");
        }

        if (longitude is < -180 or > 180)
        {
            throw new PropertyManagementValidationException(
                "Longitude must be between -180 and 180.");
        }

        if (string.IsNullOrWhiteSpace(zoneId) != string.IsNullOrWhiteSpace(stationId))
        {
            throw new PropertyManagementValidationException(
                "Zone and station must be provided together.");
        }

        if (wardId.HasValue && string.IsNullOrWhiteSpace(stationId))
        {
            throw new PropertyManagementValidationException(
                "Station is required when ward is provided.");
        }
    }

    private static string NormalizeBuildingLocation(CreateBuildingRequest request)
    {
        var location = request.Location.Trim();
        return location.Length > 0 ? location : request.Address.Trim();
    }

    private static string NormalizeBuildingLocation(UpdateBuildingRequest request)
    {
        var location = request.Location.Trim();
        return location.Length > 0 ? location : request.Address.Trim();
    }

    private static string NormalizeOptionalText(string value)
    {
        return value.Trim();
    }

    private static string? EmptyToNull(string value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value;
    }

    private static void ValidateFloor(string buildingId, string label, int totalUnits)
    {
        if (string.IsNullOrWhiteSpace(buildingId))
        {
            throw new PropertyManagementValidationException("Building is required.");
        }

        if (string.IsNullOrWhiteSpace(label))
        {
            throw new PropertyManagementValidationException("Floor label is required.");
        }

        if (totalUnits <= 0)
        {
            throw new PropertyManagementValidationException(
                "Total units must be greater than zero.");
        }
    }

    private static void ValidateProperty(
        string name,
        int monthlyRent,
        string buildingId,
        string floorId)
    {
        if (string.IsNullOrWhiteSpace(name) || name.Length < 1)
        {
            throw new PropertyManagementValidationException("Unit name is required.");
        }

        if (monthlyRent <= 0)
        {
            throw new PropertyManagementValidationException(
                "Monthly rent must be greater than zero.");
        }

        if (string.IsNullOrWhiteSpace(buildingId))
        {
            throw new PropertyManagementValidationException("Building is required.");
        }

        if (string.IsNullOrWhiteSpace(floorId))
        {
            throw new PropertyManagementValidationException("Floor is required.");
        }
    }

    private static string NormalizeFloorLabel(string value)
    {
        var normalizedValue = value.Trim();
        if (normalizedValue.Length == 0)
        {
            return string.Empty;
        }

        return normalizedValue.StartsWith("Floor ", StringComparison.OrdinalIgnoreCase)
            ? normalizedValue
            : $"Floor {normalizedValue}";
    }

    private static void EnsureFloorBelongsToBuilding(FloorLookup floor, string buildingId)
    {
        if (!string.Equals(floor.BuildingId, buildingId, StringComparison.OrdinalIgnoreCase))
        {
            throw new PropertyManagementValidationException(
                "Selected floor does not belong to the selected building.");
        }
    }

    private static async Task InsertActivityAsync(
        SqlConnection connection,
        string title,
        string subtitle,
        CancellationToken cancellationToken)
    {
        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                VALUES (@Title, @Subtitle, 'Today');
                """,
                new
                {
                    Title = title,
                    Subtitle = subtitle,
                },
                cancellationToken: cancellationToken));
    }

    private static async Task EnsureUniqueBuildingNameAsync(
        SqlConnection connection,
        string name,
        string? buildingIdToIgnore,
        CancellationToken cancellationToken)
    {
        var duplicateCount = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(*)
                FROM dbo.Buildings
                WHERE Name = @Name
                  AND (@BuildingIdToIgnore IS NULL OR Id <> @BuildingIdToIgnore);
                """,
                new
                {
                    Name = name,
                    BuildingIdToIgnore = buildingIdToIgnore,
                },
                cancellationToken: cancellationToken));

        if (duplicateCount > 0)
        {
            throw new PropertyManagementConflictException(
                "A building with this name already exists.");
        }
    }

    private static async Task EnsureUniqueFloorLabelAsync(
        SqlConnection connection,
        string buildingId,
        string label,
        string? floorIdToIgnore,
        CancellationToken cancellationToken)
    {
        var duplicateCount = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(*)
                FROM dbo.Floors
                WHERE BuildingId = @BuildingId
                  AND Label = @Label
                  AND (@FloorIdToIgnore IS NULL OR Id <> @FloorIdToIgnore);
                """,
                new
                {
                    BuildingId = buildingId,
                    Label = label,
                    FloorIdToIgnore = floorIdToIgnore,
                },
                cancellationToken: cancellationToken));

        if (duplicateCount > 0)
        {
            throw new PropertyManagementConflictException(
                "This floor already exists for the selected building.");
        }
    }

    private static async Task EnsureUniquePropertyNameAsync(
        SqlConnection connection,
        string name,
        string? propertyIdToIgnore,
        CancellationToken cancellationToken)
    {
        var duplicateCount = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(*)
                FROM dbo.Properties
                WHERE Name = @Name
                  AND (@PropertyIdToIgnore IS NULL OR Id <> @PropertyIdToIgnore);
                """,
                new
                {
                    Name = name,
                    PropertyIdToIgnore = propertyIdToIgnore,
                },
                cancellationToken: cancellationToken));

        if (duplicateCount > 0)
        {
            throw new PropertyManagementConflictException(
                "A unit with this name already exists.");
        }
    }

    private static async Task EnsureBuildingLocationSelectionAsync(
        SqlConnection connection,
        string zoneId,
        string stationId,
        int? wardId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(zoneId) && string.IsNullOrWhiteSpace(stationId))
        {
            return;
        }

        var stationCount = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(*)
                FROM dbo.DhakaPoliceStations
                WHERE Id = @StationId
                  AND ZoneId = @ZoneId;
                """,
                new
                {
                    ZoneId = zoneId,
                    StationId = stationId,
                },
                cancellationToken: cancellationToken));

        if (stationCount == 0)
        {
            throw new PropertyManagementValidationException(
                "Selected station does not belong to the selected zone.");
        }

        _ = wardId;
    }

    private static async Task EnsureBuildingExistsAsync(
        SqlConnection connection,
        string buildingId,
        CancellationToken cancellationToken)
    {
        var count = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(*)
                FROM dbo.Buildings
                WHERE Id = @BuildingId;
                """,
                new { BuildingId = buildingId },
                cancellationToken: cancellationToken));

        if (count == 0)
        {
            throw new PropertyManagementNotFoundException("Building was not found.");
        }
    }

    private static async Task EnsureFloorExistsAsync(
        SqlConnection connection,
        string floorId,
        CancellationToken cancellationToken)
    {
        var count = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(*)
                FROM dbo.Floors
                WHERE Id = @FloorId;
                """,
                new { FloorId = floorId },
                cancellationToken: cancellationToken));

        if (count == 0)
        {
            throw new PropertyManagementNotFoundException("Floor was not found.");
        }
    }

    private static async Task<BuildingLookup> EnsureBuildingLookupAsync(
        SqlConnection connection,
        string buildingId,
        CancellationToken cancellationToken)
    {
        var building = await connection.QuerySingleOrDefaultAsync<BuildingLookup>(
            new CommandDefinition(
                """
                SELECT
                    Id,
                    COALESCE(UserId, '') AS UserId,
                    Name,
                    Location,
                    COALESCE(Address, '') AS Address,
                    Latitude,
                    Longitude,
                    COALESCE(ZoneId, '') AS ZoneId,
                    COALESCE(StationId, '') AS StationId,
                    WardId,
                    TotalFloors
                FROM dbo.Buildings
                WHERE Id = @BuildingId;
                """,
                new { BuildingId = buildingId },
                cancellationToken: cancellationToken));

        if (building is null)
        {
            throw new PropertyManagementNotFoundException("Building was not found.");
        }

        return building;
    }

    private static async Task<FloorLookup> EnsureFloorLookupAsync(
        SqlConnection connection,
        string floorId,
        CancellationToken cancellationToken)
    {
        var floor = await connection.QuerySingleOrDefaultAsync<FloorLookup>(
            new CommandDefinition(
                """
                SELECT Id, BuildingId, Label, TotalUnits
                FROM dbo.Floors
                WHERE Id = @FloorId;
                """,
                new { FloorId = floorId },
                cancellationToken: cancellationToken));

        if (floor is null)
        {
            throw new PropertyManagementNotFoundException("Floor was not found.");
        }

        return floor;
    }

    private static async Task<PropertyLookup> EnsurePropertyLookupAsync(
        SqlConnection connection,
        string propertyId,
        CancellationToken cancellationToken)
    {
        var property = await connection.QuerySingleOrDefaultAsync<PropertyLookup>(
            new CommandDefinition(
                """
                SELECT
                    p.Id,
                    p.Name,
                    p.Location,
                    p.MonthlyRent,
                    p.Status,
                    p.TenantName,
                    p.DueAmount,
                    p.BuildingId,
                    p.FloorId,
                    b.Name AS BuildingName,
                    f.Label AS FloorLabel
                FROM dbo.Properties p
                LEFT JOIN dbo.Buildings b ON b.Id = p.BuildingId
                LEFT JOIN dbo.Floors f ON f.Id = p.FloorId
                WHERE p.Id = @PropertyId;
                """,
                new { PropertyId = propertyId },
                cancellationToken: cancellationToken));

        if (property is null)
        {
            throw new PropertyManagementNotFoundException("Unit was not found.");
        }

        return property;
    }

    private sealed class BuildingLookup
    {
        public string Id { get; init; } = string.Empty;
        public string UserId { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public int TotalFloors { get; init; }
        public string Location { get; init; } = string.Empty;
        public string Address { get; init; } = string.Empty;
        public decimal? Latitude { get; init; }
        public decimal? Longitude { get; init; }
        public string ZoneId { get; init; } = string.Empty;
        public string StationId { get; init; } = string.Empty;
        public int? WardId { get; init; }
    }

    private sealed class FloorLookup
    {
        public string Id { get; init; } = string.Empty;
        public string BuildingId { get; init; } = string.Empty;
        public string Label { get; init; } = string.Empty;
        public int TotalUnits { get; init; }
    }

    private sealed class PropertyLookup
    {
        public string Id { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public string Location { get; init; } = string.Empty;
        public int MonthlyRent { get; init; }
        public string Status { get; init; } = string.Empty;
        public string? TenantName { get; init; }
        public int DueAmount { get; init; }
        public string? BuildingId { get; init; }
        public string? FloorId { get; init; }
        public string? BuildingName { get; init; }
        public string? FloorLabel { get; init; }
    }

    private sealed class DependencyLookup
    {
        public int FloorCount { get; init; }
        public int PropertyCount { get; init; }
    }
}

public sealed class PropertyManagementValidationException : Exception
{
    public PropertyManagementValidationException(string message)
        : base(message)
    {
    }
}

public sealed class PropertyManagementConflictException : Exception
{
    public PropertyManagementConflictException(string message)
        : base(message)
    {
    }
}

public sealed class PropertyManagementNotFoundException : Exception
{
    public PropertyManagementNotFoundException(string message)
        : base(message)
    {
    }
}
