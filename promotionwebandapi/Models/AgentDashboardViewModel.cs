namespace PromotionWeb.Models;

public sealed class AgentDashboardViewModel
{
    public string AgentName { get; init; } = "";
    public string AgentPhone { get; init; } = "";
    public string? ProfilePictureUrl { get; init; }
    public AgentDistrictInfo? District { get; init; }
    public LocationCatalog Locations { get; init; } = new();
    public FieldOfficerRegistrationInput FieldOfficerRegistration { get; init; } = new();
    public DeliveryManRegistrationInput DeliveryRegistration { get; init; } = new();
    public ChangePasswordInputModel Password { get; init; } = new();
    public IReadOnlyList<AppUser> FieldOfficers { get; init; } = [];
    public IReadOnlyList<Shopkeeper> Shops { get; init; } = [];
    public IReadOnlyList<DeliveryMan> DeliveryMen { get; init; } = [];
    public IReadOnlyList<DeliveryAssignment> Assignments { get; init; } = [];
    public IReadOnlyList<ServiceRequest> ServiceRequests { get; init; } = [];

    public int ActiveDeliveryMen => DeliveryMen.Count(x => x.IsActive);
    public int AvailableDeliveryMen => DeliveryMen.Count(x => x.IsActive && x.Availability == DeliveryAvailability.Available);
    public int BusyDeliveryMen => DeliveryMen.Count(x => x.IsActive && x.Availability == DeliveryAvailability.Busy);
    public int ActiveAssignments => Assignments.Count(x => x.Status is not DeliveryStatus.Delivered
        and not DeliveryStatus.Rejected and not DeliveryStatus.Cancelled
        and not DeliveryStatus.Failed and not DeliveryStatus.Returned);
    public int DeliveredAssignments => Assignments.Count(x => x.Status == DeliveryStatus.Delivered);
    public int FailedAssignments => Assignments.Count(x => x.Status is DeliveryStatus.Failed or DeliveryStatus.Returned);
    public decimal DeliveredCollection => Assignments
        .Where(x => x.Status == DeliveryStatus.Delivered)
        .Sum(x => x.CashCollectedAmount ?? x.CollectionAmount);
}
