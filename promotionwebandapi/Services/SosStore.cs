using System.Data;
using Microsoft.Data.SqlClient;
using PromotionWeb.Models;

namespace PromotionWeb.Services;

public sealed class SosStore(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");

    public int TriggerAlert(SosAlertTriggerModel input)
    {
        using var connection = OpenConnection();
        using var command = new SqlCommand("sp_Sos_TriggerAlert", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.AddWithValue("@UserId", input.UserId.Trim());
        command.Parameters.AddWithValue("@Latitude", DbValue(input.Latitude));
        command.Parameters.AddWithValue("@Longitude", DbValue(input.Longitude));

        var result = command.ExecuteScalar();
        return result != null ? Convert.ToInt32(result) : 0;
    }

    public SosEmergencyContactDto AddContact(SosEmergencyContactInputModel input)
    {
        using var connection = OpenConnection();
        using var command = new SqlCommand("sp_Sos_AddContact", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.AddWithValue("@UserId", input.UserId.Trim());
        command.Parameters.AddWithValue("@Name", input.Name.Trim());
        command.Parameters.AddWithValue("@Phone", input.Phone.Trim());
        command.Parameters.AddWithValue("@Relation", DbValue(input.Relation?.Trim()));
        command.Parameters.AddWithValue("@ImageUrl", DbValue(input.ImageUrl?.Trim()));

        var id = Convert.ToInt32(command.ExecuteScalar());

        return new SosEmergencyContactDto
        {
            Id = id,
            UserId = input.UserId.Trim(),
            Name = input.Name.Trim(),
            Phone = input.Phone.Trim(),
            Relation = input.Relation?.Trim(),
            ImageUrl = input.ImageUrl?.Trim(),
            CreatedAt = DateTime.UtcNow
        };
    }

    public IReadOnlyList<SosEmergencyContactDto> GetContacts(string userId)
    {
        using var connection = OpenConnection();
        using var command = new SqlCommand("sp_Sos_GetContacts", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@UserId", userId.Trim());

        using var reader = command.ExecuteReader();
        var list = new List<SosEmergencyContactDto>();
        while (reader.Read())
        {
            list.Add(new SosEmergencyContactDto
            {
                Id = reader.GetInt32(0),
                UserId = reader.GetString(1),
                Name = reader.GetString(2),
                Phone = reader.GetString(3),
                Relation = reader.IsDBNull(4) ? null : reader.GetString(4),
                ImageUrl = reader.IsDBNull(5) ? null : reader.GetString(5),
                CreatedAt = reader.GetDateTime(6)
            });
        }

        return list;
    }

    public void RemoveContact(int id, string userId)
    {
        using var connection = OpenConnection();
        using var command = new SqlCommand("sp_Sos_RemoveContact", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@Id", id);
        command.Parameters.AddWithValue("@UserId", userId.Trim());

        command.ExecuteNonQuery();
    }

    public void UpdateLocation(SosLocationUpdateModel input)
    {
        using var connection = OpenConnection();
        using var command = new SqlCommand("sp_Sos_UpdateLocation", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@UserId", input.UserId.Trim());
        command.Parameters.AddWithValue("@Latitude", input.Latitude);
        command.Parameters.AddWithValue("@Longitude", input.Longitude);

        command.ExecuteNonQuery();
    }

    public IReadOnlyList<SosEmergencyServiceDto> GetEmergencyServices()
    {
        using var connection = OpenConnection();
        using var command = new SqlCommand("sp_Sos_GetEmergencyServices", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        using var reader = command.ExecuteReader();
        var list = new List<SosEmergencyServiceDto>();
        while (reader.Read())
        {
            list.Add(new SosEmergencyServiceDto
            {
                Id = reader.GetInt32(0),
                Title = reader.GetString(1),
                Phone = reader.GetString(2),
                Type = reader.GetString(3)
            });
        }

        return list;
    }

    public IReadOnlyList<SosSafetyTipDto> GetSafetyTips()
    {
        using var connection = OpenConnection();
        using var command = new SqlCommand("sp_Sos_GetSafetyTips", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        using var reader = command.ExecuteReader();
        var list = new List<SosSafetyTipDto>();
        while (reader.Read())
        {
            list.Add(new SosSafetyTipDto
            {
                Id = reader.GetInt32(0),
                Title = reader.GetString(1),
                Description = reader.GetString(2),
                CreatedAt = reader.GetDateTime(3)
            });
        }

        return list;
    }

    public void SaveEvidence(SosEvidenceInputModel input)
    {
        using var connection = OpenConnection();
        using var command = new SqlCommand("sp_Sos_SaveEvidence", connection)
        {
            CommandType = CommandType.StoredProcedure
        };
        command.Parameters.AddWithValue("@UserId", input.UserId.Trim());
        command.Parameters.AddWithValue("@FileUrl", input.FileUrl.Trim());
        command.Parameters.AddWithValue("@FileType", input.FileType.Trim());

        command.ExecuteNonQuery();
    }

    private SqlConnection OpenConnection()
    {
        var connection = new SqlConnection(_connectionString);
        connection.Open();
        return connection;
    }

    private static object DbValue(object? value) => value ?? DBNull.Value;
}
