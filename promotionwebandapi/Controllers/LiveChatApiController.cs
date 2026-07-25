using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Dapper;

namespace PromotionWeb.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LiveChatApiController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        
        public LiveChatApiController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public class ChatStartRequest
        {
            public string FullName { get; set; } = string.Empty;
            public string MobileNumber { get; set; } = string.Empty;
        }

        [HttpPost("start")]
        public async Task<IActionResult> StartChat([FromBody] ChatStartRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FullName) || string.IsNullOrWhiteSpace(request.MobileNumber))
            {
                return BadRequest("Name and Mobile Number are required.");
            }

            string connectionString = _configuration.GetConnectionString("DefaultConnection") ?? "";
            if (string.IsNullOrEmpty(connectionString))
            {
                return StatusCode(500, "Database connection not configured.");
            }

            try
            {
                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();
                
                // Create table if not exists
                string createTableSql = @"
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='LiveChatUsers' and xtype='U')
                    CREATE TABLE LiveChatUsers (
                        Id INT PRIMARY KEY IDENTITY,
                        FullName NVARCHAR(150),
                        MobileNumber NVARCHAR(20),
                        CreatedAt DATETIME DEFAULT GETDATE()
                    )
                ";
                await connection.ExecuteAsync(createTableSql);

                // Insert the user
                string insertSql = @"
                    INSERT INTO LiveChatUsers (FullName, MobileNumber, CreatedAt)
                    VALUES (@FullName, @MobileNumber, @CreatedAt);
                    SELECT CAST(SCOPE_IDENTITY() as int);
                ";
                
                var id = await connection.QuerySingleAsync<int>(insertSql, new {
                    request.FullName,
                    request.MobileNumber,
                    CreatedAt = DateTime.Now
                });

                return Ok(new { Success = true, UserId = id });
            }
            catch (Exception ex)
            {
                // In production, log the exception.
                return StatusCode(500, "An error occurred while starting the chat: " + ex.Message);
            }
        }
    }
}
