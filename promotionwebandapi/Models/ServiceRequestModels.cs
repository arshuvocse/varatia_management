using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class ServiceRequestInputModel
{
    [Required, StringLength(150)]
    public string Name { get; set; } = "";

    [Required, RegularExpression(@"^01\d{9}$", ErrorMessage = "সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন।")]
    public string Phone { get; set; } = "";

    [Required, StringLength(100)]
    public string Service { get; set; } = "";

    [StringLength(200)]
    public string? Location { get; set; }

    [StringLength(2000)]
    public string? Message { get; set; }
}

public sealed class ServiceRequest
{
    public int Id { get; init; }
    public string Name { get; init; } = "";
    public string Phone { get; init; } = "";
    public string Service { get; init; } = "";
    public string? Location { get; init; }
    public string? Message { get; init; }
    public string Status { get; init; } = "New";
    public DateTime CreatedAt { get; init; }
}
