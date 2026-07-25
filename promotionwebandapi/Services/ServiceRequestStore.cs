using Microsoft.Data.SqlClient;
using PromotionWeb.Models;

namespace PromotionWeb.Services;

public sealed class ServiceRequestStore(IConfiguration configuration)
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection connection string is missing.");
    private static readonly object SchemaLock = new();
    private static bool _schemaReady;

    public ServiceRequest Create(ServiceRequestInputModel input)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            INSERT INTO dbo.tbl_ServiceRequests (Name, Phone, Service, Location, Message)
            OUTPUT INSERTED.Id, INSERTED.Name, INSERTED.Phone, INSERTED.Service,
                   INSERTED.Location, INSERTED.Message, INSERTED.Status, INSERTED.CreatedAt
            VALUES (@Name, @Phone, @Service, @Location, @Message);
            """, connection);
        command.Parameters.AddWithValue("@Name", input.Name.Trim());
        command.Parameters.AddWithValue("@Phone", input.Phone.Trim());
        command.Parameters.AddWithValue("@Service", input.Service.Trim());
        command.Parameters.AddWithValue("@Location", DbValue(input.Location));
        command.Parameters.AddWithValue("@Message", DbValue(input.Message));

        connection.Open();
        using var reader = command.ExecuteReader();
        return reader.Read() ? Map(reader) : throw new InvalidOperationException("Request could not be saved.");
    }

    public IReadOnlyList<ServiceRequest> GetRecent(int limit = 100)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT TOP (@Limit) Id, Name, Phone, Service, Location, Message, Status, CreatedAt
            FROM dbo.tbl_ServiceRequests
            ORDER BY CreatedAt DESC, Id DESC;
            """, connection);
        command.Parameters.AddWithValue("@Limit", Math.Clamp(limit, 1, 500));
        var requests = new List<ServiceRequest>();

        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read()) requests.Add(Map(reader));
        return requests;
    }

    public IReadOnlyList<ServiceRequest> GetForDistrict(string districtName, int limit = 250)
    {
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            SELECT TOP (@Limit) Id, Name, Phone, Service, Location, Message, Status, CreatedAt
            FROM dbo.tbl_ServiceRequests
            WHERE Location LIKE @District
            ORDER BY CreatedAt DESC, Id DESC;
            """, connection);
        command.Parameters.AddWithValue("@Limit", Math.Clamp(limit, 1, 500));
        command.Parameters.AddWithValue("@District", $"%{districtName}%");
        var requests = new List<ServiceRequest>();
        connection.Open();
        using var reader = command.ExecuteReader();
        while (reader.Read()) requests.Add(Map(reader));
        return requests;
    }

    public void UpdateStatusForDistrict(int requestId, string districtName, string status)
    {
        if (status is not ("New" or "Contacted" or "Completed" or "Rejected"))
            throw new InvalidOperationException("Invalid service request status.");
        EnsureSchema();
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand("""
            UPDATE dbo.tbl_ServiceRequests
            SET Status = @Status
            WHERE Id = @Id AND Location LIKE @District;
            """, connection);
        command.Parameters.AddWithValue("@Status", status);
        command.Parameters.AddWithValue("@Id", requestId);
        command.Parameters.AddWithValue("@District", $"%{districtName}%");
        connection.Open();
        if (command.ExecuteNonQuery() != 1)
            throw new InvalidOperationException("The service request was not found in your district.");
    }

    private void EnsureSchema()
    {
        if (_schemaReady) return;
        lock (SchemaLock)
        {
            if (_schemaReady) return;
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("""
                IF OBJECT_ID(N'dbo.tbl_ServiceRequests', N'U') IS NULL
                BEGIN
                    CREATE TABLE dbo.tbl_ServiceRequests
                    (
                        Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_tbl_ServiceRequests PRIMARY KEY,
                        Name NVARCHAR(150) NOT NULL,
                        Phone NVARCHAR(20) NOT NULL,
                        Service NVARCHAR(100) NOT NULL,
                        Location NVARCHAR(200) NULL,
                        Message NVARCHAR(2000) NULL,
                        Status NVARCHAR(20) NOT NULL CONSTRAINT DF_tbl_ServiceRequests_Status DEFAULT N'New',
                        CreatedAt DATETIME2(0) NOT NULL
                            CONSTRAINT DF_tbl_ServiceRequests_CreatedAt DEFAULT SYSUTCDATETIME()
                    );
                    CREATE INDEX IX_tbl_ServiceRequests_CreatedAt
                        ON dbo.tbl_ServiceRequests (CreatedAt DESC);
                END;
                IF COL_LENGTH(N'dbo.tbl_ServiceRequests', N'Status') IS NULL
                    ALTER TABLE dbo.tbl_ServiceRequests ADD Status NVARCHAR(20) NOT NULL
                        CONSTRAINT DF_tbl_ServiceRequests_Status_Upgrade DEFAULT N'New';
                """, connection);
            connection.Open();
            command.ExecuteNonQuery();
            _schemaReady = true;
        }
    }

    private static object DbValue(string? value) =>
        string.IsNullOrWhiteSpace(value) ? DBNull.Value : value.Trim();

    private static ServiceRequest Map(SqlDataReader reader) => new()
    {
        Id = reader.GetInt32(reader.GetOrdinal("Id")),
        Name = reader.GetString(reader.GetOrdinal("Name")),
        Phone = reader.GetString(reader.GetOrdinal("Phone")),
        Service = reader.GetString(reader.GetOrdinal("Service")),
        Location = reader.IsDBNull(reader.GetOrdinal("Location")) ? null : reader.GetString(reader.GetOrdinal("Location")),
        Message = reader.IsDBNull(reader.GetOrdinal("Message")) ? null : reader.GetString(reader.GetOrdinal("Message")),
        Status = reader.GetString(reader.GetOrdinal("Status")),
        CreatedAt = reader.GetDateTime(reader.GetOrdinal("CreatedAt"))
    };
}
