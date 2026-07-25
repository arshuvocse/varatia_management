using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace PromotionWeb.Controllers;

[ApiController]
[Route("api/top-performers")]
public sealed class TopPerformersController(IConfiguration configuration) : ControllerBase
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");

    [HttpGet("districts")]
    public async Task<IActionResult> GetDistricts()
    {
        using var connection = new SqlConnection(_connectionString);
        var districts = await connection.QueryAsync<string>(
            "SELECT DISTINCT d.Name FROM dbo.tbl_Districts d ORDER BY d.Name");
        return Ok(districts);
    }

    [HttpGet("buyers/{districtName}")]
    public async Task<IActionResult> GetTopBuyers(string districtName)
    {
        using var connection = new SqlConnection(_connectionString);
        var buyers = await connection.QueryAsync(
            @"SELECT TOP 50 
                u.Name as Name, 
                SUM(o.TotalAmount) as TotalAmount
              FROM dbo.tbl_CustomerOrders o
              JOIN dbo.tbl_Shopkeepers s ON o.ShopkeeperId = s.Id
              JOIN dbo.tbl_Districts d ON s.DistrictId = d.Id
              JOIN dbo.tbl_Users u ON o.CustomerUserId = u.Id
              WHERE d.Name = @DistrictName AND o.Status = 'Delivered'
              GROUP BY u.Name
              ORDER BY TotalAmount DESC", new { DistrictName = districtName });
        return Ok(buyers);
    }

    [HttpGet("sellers/{districtName}")]
    public async Task<IActionResult> GetTopSellers(string districtName)
    {
        using var connection = new SqlConnection(_connectionString);
        var sellers = await connection.QueryAsync(
            @"SELECT TOP 50 
                s.ShopName as Name, 
                SUM(o.TotalAmount) as TotalAmount
              FROM dbo.tbl_CustomerOrders o
              JOIN dbo.tbl_Shopkeepers s ON o.ShopkeeperId = s.Id
              JOIN dbo.tbl_Districts d ON s.DistrictId = d.Id
              WHERE d.Name = @DistrictName AND o.Status = 'Delivered'
              GROUP BY s.ShopName
              ORDER BY TotalAmount DESC", new { DistrictName = districtName });
        return Ok(sellers);
    }
}
