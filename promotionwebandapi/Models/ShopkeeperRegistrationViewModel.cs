using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace PromotionWeb.Models;

public sealed class ShopkeeperRegistrationViewModel
{
    [Required]
    [Display(Name = "দোকানের নাম")]
    public string ShopName { get; set; } = "";

    [Required]
    [Display(Name = "মালিকের নাম")]
    public string OwnerName { get; set; } = "";

    [Required]
    [Phone]
    [Display(Name = "মোবাইল নম্বর")]
    public string Phone { get; set; } = "";

    [StringLength(30)]
    [Display(Name = "জাতীয় পরিচয়পত্র নম্বর (ঐচ্ছিক)")]
    public string? NidNumber { get; set; }

    [Display(Name = "প্রোফাইল ছবি (ঐচ্ছিক)")]
    public IFormFile? ProfilePhoto { get; set; }

    [Display(Name = "দোকানের সাইনবোর্ডের ছবি (ঐচ্ছিক)")]
    public IFormFile? BillboardPhoto { get; set; }

    [Required]
    [Display(Name = "বিভাগ")]
    public int? DivisionId { get; set; }

    [Required]
    [Display(Name = "জেলা")]
    public int? DistrictId { get; set; }

    [Required]
    [Display(Name = "থানা")]
    public int? ThanaId { get; set; }

    [Required]
    [Display(Name = "ঠিকানা")]
    public string Address { get; set; } = "";

    [Required]
    [Range(-90, 90)]
    [Display(Name = "অক্ষাংশ")]
    public decimal? Latitude { get; set; }

    [Required]
    [Range(-180, 180)]
    [Display(Name = "দ্রাঘিমাংশ")]
    public decimal? Longitude { get; set; }

    [Required]
    [Display(Name = "এলাকা")]
    public string Area { get; set; } = "";

    [Required]
    [Display(Name = "দোকানের ধরন")]
    public string ShopType { get; set; } = "";

    [MinLength(1, ErrorMessage = "Select at least one product.")]
    public List<int> SelectedProductIds { get; set; } = [];

    [Required]
    [MinLength(4)]
    [DataType(DataType.Password)]
    [Display(Name = "লগইন পাসওয়ার্ড")]
    public string Password { get; set; } = "";
}
