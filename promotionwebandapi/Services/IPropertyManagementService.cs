using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public interface IPropertyManagementService
{
    Task<CreateBuildingResponse> CreateBuildingAsync(
        CreateBuildingRequest request,
        CancellationToken cancellationToken = default);

    Task<UpdateBuildingResponse> UpdateBuildingAsync(
        string buildingId,
        UpdateBuildingRequest request,
        CancellationToken cancellationToken = default);

    Task<DeleteBuildingResponse> DeleteBuildingAsync(
        string buildingId,
        CancellationToken cancellationToken = default);

    Task<CreateFloorResponse> CreateFloorAsync(
        CreateFloorRequest request,
        CancellationToken cancellationToken = default);

    Task<UpdateFloorResponse> UpdateFloorAsync(
        string floorId,
        UpdateFloorRequest request,
        CancellationToken cancellationToken = default);

    Task<DeleteFloorResponse> DeleteFloorAsync(
        string floorId,
        CancellationToken cancellationToken = default);

    Task<CreatePropertyResponse> CreatePropertyAsync(
        CreatePropertyRequest request,
        CancellationToken cancellationToken = default);

    Task<UpdatePropertyResponse> UpdatePropertyAsync(
        string propertyId,
        UpdatePropertyRequest request,
        CancellationToken cancellationToken = default);

    Task<DeletePropertyResponse> DeletePropertyAsync(
        string propertyId,
        CancellationToken cancellationToken = default);

    Task<GetBuildingsResponse> GetBuildingsAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task<GetFloorsResponse> GetFloorsAsync(
        string buildingId,
        CancellationToken cancellationToken = default);

    Task<GetPropertiesResponse> GetPropertiesAsync(
        string userId,
        CancellationToken cancellationToken = default);
}
