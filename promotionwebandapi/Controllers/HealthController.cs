using Dapper;
using Microsoft.AspNetCore.Mvc;
using OrderProcessAPI.Configuration;

namespace OrderProcessAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class HealthController : ControllerBase
{
    private readonly SqlConnectionFactory _connectionFactory;

    public HealthController(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken cancellationToken)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var command = new CommandDefinition(
            "SELECT 1;",
            cancellationToken: cancellationToken);

        var result = await connection.ExecuteScalarAsync<int>(command);

        return Ok(new
        {
            status = result == 1 ? "ok" : "unhealthy",
            database = connection.Database,
        });
    }
}
