using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class DeliveryAppLoginRequest
{
    [Required]
    public string Phone { get; set; } = "";

    [Required]
    public string Password { get; set; } = "";
}

public sealed class DeliveryAppStatusRequest
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

public sealed class DeliveryAppLocationRequest
{
    public int? AssignmentId { get; set; }

    [Required]
    [Range(-90, 90)]
    public decimal? Latitude { get; set; }

    [Required]
    [Range(-180, 180)]
    public decimal? Longitude { get; set; }
}
