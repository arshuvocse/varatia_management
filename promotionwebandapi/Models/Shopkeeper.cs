namespace PromotionWeb.Models;

public sealed class Shopkeeper
{
    public int Id { get; init; }
    public string ShopName { get; init; } = "";
    public string OwnerName { get; init; } = "";
    public string Phone { get; init; } = "";
    public string? NidNumber { get; init; }
    public string? ProfilePhotoPath { get; init; }
    public string? BillboardPhotoPath { get; init; }
    public int DivisionId { get; init; }
    public string DivisionName { get; init; } = "";
    public int DistrictId { get; init; }
    public string DistrictName { get; init; } = "";
    public int ThanaId { get; init; }
    public string ThanaName { get; init; } = "";
    public string Address { get; init; } = "";
    public decimal Latitude { get; init; }
    public decimal Longitude { get; init; }
    public string Area { get; init; } = "";
    public string ShopType { get; init; } = "";
    public string Password { get; init; } = "";
    public string ShopCode { get; init; } = "";
    public int FieldOfficerUserId { get; init; }
    public string FieldOfficerName { get; init; } = "";
    public string FieldOfficerPhone { get; init; } = "";
    public DateTime RegisteredAt { get; init; } = DateTime.Now;
}
