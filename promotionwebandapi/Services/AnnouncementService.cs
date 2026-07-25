using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class AnnouncementService : IAnnouncementService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public AnnouncementService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<IReadOnlyList<AnnouncementDto>> GetActiveAnnouncementsAsync(CancellationToken cancellationToken)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var items = await connection.QueryAsync<AnnouncementDto>(
            new CommandDefinition(
                "dbo.GetActiveCompanyBulletins",
                commandType: System.Data.CommandType.StoredProcedure,
                cancellationToken: cancellationToken));

        return items.ToList();
    }
}
