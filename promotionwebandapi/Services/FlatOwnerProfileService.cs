using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class FlatOwnerProfileService : IFlatOwnerProfileService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public FlatOwnerProfileService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<FlatOwnerProfileResponse> GetProfileAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId?.Trim(), out var parsedUserId))
        {
            throw new FlatOwnerProfileValidationException(
                "Valid user id is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<FlatOwnerProfileResponse>(
                new CommandDefinition(
                    "dbo.sp_FlatOwner_GetProfile",
                    new { UserId = parsedUserId },
                    commandType: CommandType.StoredProcedure,
                    cancellationToken: cancellationToken));
        }
        catch (SqlException exception) when (exception.Number == 51050)
        {
            throw new FlatOwnerProfileNotFoundException(
                "Flat owner was not found.",
                exception);
        }
        catch (SqlException exception) when (exception.Number == 51051)
        {
            throw new FlatOwnerProfileRoleException(
                "The requested user is not a flat owner.",
                exception);
        }
    }
}

public sealed class FlatOwnerProfileValidationException : Exception
{
    public FlatOwnerProfileValidationException(string message) : base(message)
    {
    }
}

public sealed class FlatOwnerProfileNotFoundException : Exception
{
    public FlatOwnerProfileNotFoundException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}

public sealed class FlatOwnerProfileRoleException : Exception
{
    public FlatOwnerProfileRoleException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}
