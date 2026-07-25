using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public static class DeliveryAvailability
{
    public const string Available = "Available";
    public const string Busy = "Busy";
    public const string Offline = "Offline";
}

public static class DeliveryStatus
{
    public const string Assigned = "Assigned";
    public const string Accepted = "Accepted";
    public const string PickedUp = "Picked Up";
    public const string OutForDelivery = "Out for Delivery";
    public const string Delivered = "Delivered";
    public const string Rejected = "Rejected";
    public const string Failed = "Failed Delivery";
    public const string Cancelled = "Cancelled";
    public const string Returned = "Returned";

    public static readonly IReadOnlySet<string> DeliveryManUpdates = new HashSet<string>
    {
        Accepted, PickedUp, OutForDelivery, Delivered, Rejected, Failed, Returned
    };
}

public sealed class DeliveryManRegistrationInput
{
    [Required, StringLength(150)]
    public string Name { get; set; } = "";
    [Required, RegularExpression(@"^\d{11}$", ErrorMessage = "মোবাইল নম্বর ১১ সংখ্যার হতে হবে।")]
    public string Phone { get; set; } = "";
    [Required, MinLength(4), StringLength(100)]
    public string Password { get; set; } = "";
    [Required]
    public int? DivisionId { get; set; }
    [Required]
    public int? DistrictId { get; set; }
    [Required]
    public int? ThanaId { get; set; }
    [Required, StringLength(250)]
    public string Address { get; set; } = "";
    [Required]
    public decimal? Latitude { get; set; }
    [Required]
    public decimal? Longitude { get; set; }
    [StringLength(30)]
    public string? NidNumber { get; set; }
    public DateTime? DateOfBirth { get; set; }
    [StringLength(20)]
    public string? EmergencyContact { get; set; }
    [StringLength(50)]
    public string? VehicleType { get; set; }
    [StringLength(50)]
    public string? VehicleNumber { get; set; }
    [StringLength(50)]
    public string? DrivingLicenseNumber { get; set; }
    public IFormFile? ProfilePhoto { get; set; }
    public IFormFile? NidFrontPhoto { get; set; }
    public IFormFile? NidBackPhoto { get; set; }
    public IFormFile? DrivingLicensePhoto { get; set; }
}

public sealed class DeliveryProfileUpdateInput
{
    [Required, StringLength(150)]
    public string Name { get; set; } = "";
    [Required, StringLength(250)]
    public string Address { get; set; } = "";
    [StringLength(20)]
    public string? EmergencyContact { get; set; }
    [StringLength(50)]
    public string? VehicleType { get; set; }
    [StringLength(50)]
    public string? VehicleNumber { get; set; }
    [StringLength(30)]
    public string? NidNumber { get; set; }
    [StringLength(50)]
    public string? DrivingLicenseNumber { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public IFormFile? ProfilePhoto { get; set; }
    public IFormFile? NidFrontPhoto { get; set; }
    public IFormFile? NidBackPhoto { get; set; }
    public IFormFile? DrivingLicensePhoto { get; set; }
}

public sealed class DeliveryMan
{
    public int Id { get; init; }
    public int UserId { get; init; }
    public int? ShopkeeperId { get; init; }
    public int? AgentUserId { get; init; }
    public string ShopName { get; init; } = "";
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public int DivisionId { get; init; }
    public string DivisionName { get; init; } = "";
    public int DistrictId { get; init; }
    public string DistrictName { get; init; } = "";
    public int ThanaId { get; init; }
    public string ThanaName { get; init; } = "";
    public string Address { get; init; } = "";
    public decimal Latitude { get; init; }
    public decimal Longitude { get; init; }
    public decimal? LastLatitude { get; init; }
    public decimal? LastLongitude { get; init; }
    public DateTime? LastLocationAt { get; init; }
    public string? NidNumber { get; init; }
    public string? NidPhotoUrl { get; init; }
    public string? NidFrontPhotoUrl { get; init; }
    public string? NidBackPhotoUrl { get; init; }
    public DateTime? DateOfBirth { get; init; }
    public string? EmergencyContact { get; init; }
    public string? VehicleType { get; init; }
    public string? VehicleNumber { get; init; }
    public string? DrivingLicenseNumber { get; init; }
    public string? DrivingLicensePhotoUrl { get; init; }
    public string? ProfilePhotoUrl { get; init; }
    public string Availability { get; init; } = DeliveryAvailability.Offline;
    public bool IsActive { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class NearbyDeliveryMan
{
    public DeliveryMan DeliveryMan { get; init; } = new();
    public decimal DistanceKm { get; init; }
}

public sealed class DeliveryAssignment
{
    public int AssignmentId { get; init; }
    public int OrderId { get; init; }
    public int DeliveryManId { get; init; }
    public string DeliveryManName { get; init; } = "";
    public string DeliveryManPhone { get; init; } = "";
    public string CustomerName { get; init; } = "";
    public string CustomerPhone { get; init; } = "";
    public decimal? CustomerLatitude { get; init; }
    public decimal? CustomerLongitude { get; init; }
    public string ShopName { get; init; } = "";
    public string ShopPhone { get; init; } = "";
    public decimal CollectionAmount { get; init; }
    public string Status { get; init; } = DeliveryStatus.Assigned;
    public string? DeliveryOtp { get; init; }
    public string? DeliveryNote { get; init; }
    public decimal? CashCollectedAmount { get; init; }
    public string? ProofPhotoUrl { get; init; }
    public string? CustomerSignatureUrl { get; init; }
    public decimal? CurrentLatitude { get; init; }
    public decimal? CurrentLongitude { get; init; }
    public DateTime AssignedAt { get; init; }
    public DateTime? DeliveredAt { get; init; }
    public IReadOnlyList<CustomerOrderDetail> Details { get; init; } = [];
}

public sealed class DeliveryStatusUpdateInput
{
    [Required]
    public string Status { get; set; } = "";
    public string? Otp { get; set; }
    public decimal? CashCollectedAmount { get; set; }
    public string? DeliveryNote { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public IFormFile? ProofPhoto { get; set; }
    public IFormFile? CustomerSignature { get; set; }
}

public sealed class DeliveryDashboardViewModel
{
    public DeliveryMan DeliveryMan { get; init; } = new();
    public IReadOnlyList<DeliveryAssignment> Assignments { get; init; } = [];
    public int ActiveCount => Assignments.Count(x => x.Status is not DeliveryStatus.Delivered
        and not DeliveryStatus.Rejected and not DeliveryStatus.Cancelled
        and not DeliveryStatus.Failed and not DeliveryStatus.Returned);
    public int DeliveredCount => Assignments.Count(x => x.Status == DeliveryStatus.Delivered);
    public int NewAssignmentCount => Assignments.Count(x => x.Status == DeliveryStatus.Assigned);
}
