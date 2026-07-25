using Microsoft.AspNetCore.Mvc;
using System.Data;
using Microsoft.Data.SqlClient;
using Dapper;

namespace PromotionWeb.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LeaderboardController : ControllerBase
    {
        private readonly string _connectionString;

        public LeaderboardController(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") ?? "";
        }

        [HttpGet("top50")]
        public async Task<IActionResult> GetTop50(int districtId)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var multi = await connection.QueryMultipleAsync("dbo.sp_Leaderboard_GetTop50", new { DistrictId = districtId }, commandType: CommandType.StoredProcedure);
                
                var topCustomers = await multi.ReadAsync<CustomerLeaderboardItem>();
                var topShopkeepers = await multi.ReadAsync<ShopkeeperLeaderboardItem>();
                
                return Ok(new {
                    customers = topCustomers,
                    shopkeepers = topShopkeepers
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }

    public class CustomerLeaderboardItem
    {
        public int CustomerId { get; set; }
        public string CustomerName { get; set; } = "";
        public decimal TotalAmount { get; set; }
    }

    public class ShopkeeperLeaderboardItem
    {
        public int ShopkeeperId { get; set; }
        public string ShopName { get; set; } = "";
        public string OwnerName { get; set; } = "";
        public decimal TotalSales { get; set; }
    }
}
