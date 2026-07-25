using System.ComponentModel.DataAnnotations;

namespace PromotionWeb.Models;

public sealed class FieldOfficerRegistrationInput
{
    [Required, StringLength(150)]
    public string Name { get; set; } = "";

    [Required, RegularExpression(@"^\d{11}$", ErrorMessage = "মোবাইল নম্বর ১১ সংখ্যার হতে হবে।")]
    public string Phone { get; set; } = "";

    [Required, MinLength(4), StringLength(100)]
    public string Password { get; set; } = "";

    [Required]
    public int? DistrictId { get; set; }
}

public sealed class AgentDistrictInfo
{
    public int DivisionId { get; init; }
    public string DivisionName { get; init; } = "";
    public int DistrictId { get; init; }
    public string DistrictName { get; init; } = "";
}
