using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class CustomerRegistrationViewModel
{
    [Required, StringLength(150)]
    [Display(Name = "নাম")]
    public string Name { get; set; } = "";

    [Required, RegularExpression(@"^\d{11}$", ErrorMessage = "মোবাইল নম্বর ১১ সংখ্যার হতে হবে।")]
    [Display(Name = "মোবাইল নম্বর")]
    public string Phone { get; set; } = "";

    [Required, MinLength(4), StringLength(100)]
    [DataType(DataType.Password)]
    [Display(Name = "পাসওয়ার্ড")]
    public string Password { get; set; } = "";

    [StringLength(250)]
    [Display(Name = "ঠিকানা")]
    public string? Address { get; set; }

    [Range(-90, 90)]
    public decimal? Latitude { get; set; }

    [Range(-180, 180)]
    public decimal? Longitude { get; set; }
}
