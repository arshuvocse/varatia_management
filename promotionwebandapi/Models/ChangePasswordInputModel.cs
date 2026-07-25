using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class ChangePasswordInputModel
{
    [Required(ErrorMessage = "বর্তমান পাসওয়ার্ড প্রয়োজন।")]
    public string OldPassword { get; set; } = "";

    [Required(ErrorMessage = "নতুন পাসওয়ার্ড প্রয়োজন।")]
    [MinLength(4, ErrorMessage = "পাসওয়ার্ড কমপক্ষে ৪ অক্ষরের হতে হবে।")]
    public string NewPassword { get; set; } = "";

    [Required(ErrorMessage = "পাসওয়ার্ড নিশ্চিতকরণ প্রয়োজন।")]
    [Compare("NewPassword", ErrorMessage = "নতুন পাসওয়ার্ড এবং নিশ্চিতকরণ পাসওয়ার্ড মেলেনি।")]
    public string ConfirmPassword { get; set; } = "";
}
