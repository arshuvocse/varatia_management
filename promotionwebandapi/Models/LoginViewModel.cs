using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class LoginViewModel
{
    [Required]
    [Display(Name = "মোবাইল নম্বর")]
    public string Phone { get; set; } = "";

    [Required]
    [DataType(DataType.Password)]
    [Display(Name = "পাসওয়ার্ড")]
    public string Password { get; set; } = "";
}

public sealed class ForgotPasswordInput
{
    public string Phone { get; set; } = "";
}

public sealed class ResetPasswordInput
{
    public string Phone { get; set; } = "";
    public string Otp { get; set; } = "";
    public string NewPassword { get; set; } = "";
}
