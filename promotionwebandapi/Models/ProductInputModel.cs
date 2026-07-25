using Microsoft.AspNetCore.Http;

namespace PromotionWeb.Models;

public sealed class ProductInputModel
{
    public string Name { get; set; } = "";
    public string Sku { get; set; } = "";
    public string Category { get; set; } = "";
    public decimal UnitPrice { get; set; }
    public int StockQuantity { get; set; }
    public string? ImageUrl { get; set; }
    public IFormFile? ImageFile { get; set; }
}
