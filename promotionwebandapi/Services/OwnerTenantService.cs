using System.Security.Cryptography;
using Dapper;
using Microsoft.Data.SqlClient;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Security;

namespace OrderProcessAPI.Services;

public sealed class OwnerTenantService : IOwnerTenantService
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly PasswordHasher _passwordHasher;
    private readonly ISmsOtpService _smsOtpService;

    public OwnerTenantService(
        SqlConnectionFactory connectionFactory,
        PasswordHasher passwordHasher,
        ISmsOtpService smsOtpService)
    {
        _connectionFactory = connectionFactory;
        _passwordHasher = passwordHasher;
        _smsOtpService = smsOtpService;
    }

    public async Task<OwnerTenantListResponse> GetTenantsAsync(
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var tenants = (await connection.QueryAsync<TenantProfileDto>(
            new CommandDefinition(
                """
                SELECT
                    Id,
                    Name,
                    Phone,
                    Nid,
                    PropertyName
                FROM dbo.vw_OwnerTenantList
                ORDER BY Id;
                """,
                cancellationToken: cancellationToken))).ToList();

        return new OwnerTenantListResponse
        {
            Tenants = tenants,
        };
    }

    public async Task<CreateOwnerTenantResponse> CreateTenantAsync(
        CreateOwnerTenantRequest request,
        CancellationToken cancellationToken = default)
    {
        var fullName = request.FullName.Trim();
        var phoneNumber = request.PhoneNumber.Trim();
        var normalizedPhoneNumber = NormalizeDigits(phoneNumber);
        var nid = request.Nid.Trim();
        var propertyId = request.PropertyId.Trim();

        ValidateRequest(fullName, normalizedPhoneNumber, nid, propertyId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var property = await connection.QuerySingleOrDefaultAsync<PropertyLookup>(
                new CommandDefinition(
                    """
                    SELECT Id, Name, Status, TenantName
                    FROM dbo.Properties
                    WHERE Id = @PropertyId;
                    """,
                    new { PropertyId = propertyId },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (property is null)
            {
                throw new OwnerTenantValidationException("Selected property was not found.");
            }

            if (!string.Equals(property.Status, "available", StringComparison.OrdinalIgnoreCase)
                || !string.IsNullOrWhiteSpace(property.TenantName))
            {
                throw new OwnerTenantConflictException(
                    "Selected property already has an active tenant.");
            }

            var duplicate = await connection.QuerySingleAsync<DuplicateLookup>(
                new CommandDefinition(
                    """
                    SELECT
                        CAST(MAX(CASE WHEN Phone = @PhoneNumber THEN 1 ELSE 0 END) AS bit) AS HasPhoneNumber,
                        CAST(MAX(CASE WHEN Nid = @Nid THEN 1 ELSE 0 END) AS bit) AS HasNid
                    FROM dbo.Tenants;
                    """,
                    new
                    {
                        PhoneNumber = phoneNumber,
                        Nid = nid,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (duplicate.HasPhoneNumber)
            {
                throw new OwnerTenantConflictException(
                    "This phone number is already assigned to another tenant.");
            }

            if (duplicate.HasNid)
            {
                throw new OwnerTenantConflictException(
                    "This NID is already assigned to another tenant.");
            }

            var nextNumericId = await connection.ExecuteScalarAsync<int>(
                new CommandDefinition(
                    """
                    SELECT ISNULL(MAX(TRY_CONVERT(int, SUBSTRING(Id, 3, LEN(Id) - 2))), 0) + 1
                    FROM dbo.Tenants
                    WHERE Id LIKE 'T-%';
                    """,
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            var tenantId = $"T-{nextNumericId:D2}";
            var temporaryPassword = GenerateTemporaryPassword();
            var passwordHash = _passwordHasher.Hash(temporaryPassword);

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Tenants (Id, Name, Phone, Nid, PropertyId)
                    VALUES (@Id, @Name, @Phone, @Nid, @PropertyId);
                    """,
                    new
                    {
                        Id = tenantId,
                        Name = fullName,
                        Phone = phoneNumber,
                        Nid = nid,
                        PropertyId = propertyId,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            var existingUserId = await connection.ExecuteScalarAsync<Guid?>(
                new CommandDefinition(
                    """
                    SELECT TOP (1) Id
                    FROM dbo.Users
                    WHERE NormalizedPhoneNumber = @NormalizedPhoneNumber;
                    """,
                    new { NormalizedPhoneNumber = normalizedPhoneNumber },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (existingUserId.HasValue)
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        UPDATE dbo.Users
                        SET
                            FullName = @FullName,
                            PhoneNumber = @PhoneNumber,
                            PasswordHash = @PasswordHash,
                            PasswordSalt = @PasswordSalt,
                            Role = 'tenant',
                            IsPhoneVerified = 1,
                            LastOtpCode = NULL,
                            OtpExpiresAt = NULL,
                            UpdatedAt = SYSUTCDATETIME()
                        WHERE Id = @UserId;
                        """,
                        new
                        {
                            UserId = existingUserId.Value,
                            FullName = fullName,
                            PhoneNumber = phoneNumber,
                            PasswordHash = passwordHash.Hash,
                            PasswordSalt = passwordHash.Salt,
                        },
                        transaction: transaction,
                        cancellationToken: cancellationToken));
            }
            else
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        INSERT INTO dbo.Users
                        (
                            Id,
                            FullName,
                            PhoneNumber,
                            NormalizedPhoneNumber,
                            PasswordHash,
                            PasswordSalt,
                            Role,
                            IsPhoneVerified,
                            CreatedAt,
                            UpdatedAt
                        )
                        VALUES
                        (
                            @Id,
                            @FullName,
                            @PhoneNumber,
                            @NormalizedPhoneNumber,
                            @PasswordHash,
                            @PasswordSalt,
                            'tenant',
                            1,
                            SYSUTCDATETIME(),
                            SYSUTCDATETIME()
                        );
                        """,
                        new
                        {
                            Id = Guid.NewGuid(),
                            FullName = fullName,
                            PhoneNumber = phoneNumber,
                            NormalizedPhoneNumber = normalizedPhoneNumber,
                            PasswordHash = passwordHash.Hash,
                            PasswordSalt = passwordHash.Salt,
                        },
                        transaction: transaction,
                        cancellationToken: cancellationToken));
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.Properties
                    SET
                        Status = 'rented',
                        TenantName = @TenantName,
                        DueAmount = 0
                    WHERE Id = @PropertyId;

                    UPDATE dbo.RentPayments
                    SET TenantName = @TenantName
                    WHERE PropertyId = @PropertyId
                      AND Status = 'due'
                      AND TenantName IS NULL;
                    """,
                    new
                    {
                        TenantName = fullName,
                        PropertyId = propertyId,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                    VALUES (@Title, @Subtitle, 'Today');
                    """,
                    new
                    {
                        Title = "New tenant added",
                        Subtitle = $"{fullName} was assigned to {property.Name}.",
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await transaction.CommitAsync(cancellationToken);

            var credentialMessage =
                $"Welcome to Amar Abas. Tenant ID: {tenantId}. Mobile: {phoneNumber}. Password: {temporaryPassword}. Please login and change your password.";
            var smsResult = await _smsOtpService.SendMessageAsync(
                phoneNumber,
                credentialMessage,
                cancellationToken);

            return new CreateOwnerTenantResponse
            {
                Tenant = new TenantProfileDto
                {
                    Id = tenantId,
                    Name = fullName,
                    Phone = phoneNumber,
                    Nid = nid,
                    PropertyName = property.Name,
                },
                PropertyId = propertyId,
                PropertyName = property.Name,
                LoginPhoneNumber = phoneNumber,
                TemporaryPassword = temporaryPassword,
                CredentialSmsSent = smsResult.IsSuccess,
                CredentialSmsError = smsResult.ErrorMessage,
                Message = smsResult.IsSuccess
                    ? "Tenant created successfully. Login credentials were sent by SMS."
                    : $"Tenant created successfully. Credential SMS failed: {smsResult.ErrorMessage}",
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task<UpdateOwnerTenantResponse> UpdateTenantAsync(
        string tenantId,
        UpdateOwnerTenantRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedTenantId = tenantId.Trim();
        var fullName = request.FullName.Trim();
        var phoneNumber = request.PhoneNumber.Trim();
        var normalizedPhoneNumber = NormalizeDigits(phoneNumber);
        var nid = request.Nid.Trim();

        ValidateRequest(fullName, normalizedPhoneNumber, nid, "assigned");

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var existingTenant = await GetTenantLookupAsync(
                connection,
                normalizedTenantId,
                transaction,
                cancellationToken);

            var duplicate = await connection.QuerySingleAsync<DuplicateLookup>(
                new CommandDefinition(
                    """
                    SELECT
                        CAST(MAX(CASE WHEN Phone = @PhoneNumber THEN 1 ELSE 0 END) AS bit) AS HasPhoneNumber,
                        CAST(MAX(CASE WHEN Nid = @Nid THEN 1 ELSE 0 END) AS bit) AS HasNid
                    FROM dbo.Tenants
                    WHERE Id <> @TenantId;
                    """,
                    new
                    {
                        PhoneNumber = phoneNumber,
                        Nid = nid,
                        TenantId = normalizedTenantId,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (duplicate.HasPhoneNumber)
            {
                throw new OwnerTenantConflictException(
                    "This phone number is already assigned to another tenant.");
            }

            if (duplicate.HasNid)
            {
                throw new OwnerTenantConflictException(
                    "This NID is already assigned to another tenant.");
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.Tenants
                    SET
                        Name = @Name,
                        Phone = @Phone,
                        Nid = @Nid
                    WHERE Id = @TenantId;
                    """,
                    new
                    {
                        Name = fullName,
                        Phone = phoneNumber,
                        Nid = nid,
                        TenantId = normalizedTenantId,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (!string.IsNullOrWhiteSpace(existingTenant.PropertyId))
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        UPDATE dbo.Properties
                        SET TenantName = @TenantName
                        WHERE Id = @PropertyId;

                        UPDATE dbo.RentPayments
                        SET TenantName = @TenantName
                        WHERE PropertyId = @PropertyId
                          AND TenantName = @PreviousTenantName;
                        """,
                        new
                        {
                            TenantName = fullName,
                            PreviousTenantName = existingTenant.Name,
                            PropertyId = existingTenant.PropertyId,
                        },
                        transaction: transaction,
                        cancellationToken: cancellationToken));
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                    VALUES (@Title, @Subtitle, 'Today');
                    """,
                    new
                    {
                        Title = "Tenant profile updated",
                        Subtitle =
                            $"{fullName} profile was updated for {existingTenant.PropertyName}.",
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await transaction.CommitAsync(cancellationToken);

            return new UpdateOwnerTenantResponse
            {
                Tenant = new TenantProfileDto
                {
                    Id = normalizedTenantId,
                    Name = fullName,
                    Phone = phoneNumber,
                    Nid = nid,
                    PropertyName = existingTenant.PropertyName,
                },
                PropertyId = existingTenant.PropertyId ?? string.Empty,
                PropertyName = existingTenant.PropertyName,
                Message = "Tenant updated successfully.",
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task<DeleteOwnerTenantResponse> DeleteTenantAsync(
        string tenantId,
        CancellationToken cancellationToken = default)
    {
        var normalizedTenantId = tenantId.Trim();

        if (string.IsNullOrWhiteSpace(normalizedTenantId))
        {
            throw new OwnerTenantValidationException("Tenant id is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var existingTenant = await GetTenantLookupAsync(
                connection,
                normalizedTenantId,
                transaction,
                cancellationToken);

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    DELETE FROM dbo.Tenants
                    WHERE Id = @TenantId;
                    """,
                    new { TenantId = normalizedTenantId },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (!string.IsNullOrWhiteSpace(existingTenant.PropertyId))
            {
                await connection.ExecuteAsync(
                    new CommandDefinition(
                        """
                        UPDATE dbo.Properties
                        SET
                            Status = 'available',
                            TenantName = NULL,
                            DueAmount = MonthlyRent
                        WHERE Id = @PropertyId;

                        UPDATE dbo.RentPayments
                        SET TenantName = NULL
                        WHERE PropertyId = @PropertyId
                          AND Status = 'due';
                        """,
                        new { PropertyId = existingTenant.PropertyId },
                        transaction: transaction,
                        cancellationToken: cancellationToken));
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                    VALUES (@Title, @Subtitle, 'Today');
                    """,
                    new
                    {
                        Title = "Tenant removed",
                        Subtitle =
                            $"{existingTenant.Name} was removed from {existingTenant.PropertyName}.",
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await transaction.CommitAsync(cancellationToken);

            return new DeleteOwnerTenantResponse
            {
                TenantId = normalizedTenantId,
                PropertyId = existingTenant.PropertyId ?? string.Empty,
                PropertyName = existingTenant.PropertyName,
                Message = "Tenant deleted successfully.",
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task<MoveOutOwnerTenantResponse> MoveOutTenantAsync(
        string tenantId,
        CancellationToken cancellationToken = default)
    {
        var normalizedTenantId = tenantId.Trim();
        if (string.IsNullOrWhiteSpace(normalizedTenantId))
        {
            throw new OwnerTenantValidationException("Tenant id is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var existingTenant = await GetTenantLookupAsync(
                connection,
                normalizedTenantId,
                transaction,
                cancellationToken);

            if (string.IsNullOrWhiteSpace(existingTenant.PropertyId))
            {
                throw new OwnerTenantConflictException(
                    "Tenant is not assigned to any property.");
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.Tenants
                    SET PropertyId = NULL
                    WHERE Id = @TenantId;

                    UPDATE dbo.Properties
                    SET
                        Status = 'available',
                        TenantName = NULL,
                        DueAmount = MonthlyRent
                    WHERE Id = @PropertyId;

                    UPDATE dbo.RentPayments
                    SET TenantName = NULL
                    WHERE PropertyId = @PropertyId
                      AND Status = 'due';

                    INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                    VALUES (@Title, @Subtitle, 'Today');

                    INSERT INTO dbo.Notifications (Title, Subtitle, CreatedAt, IsUnread)
                    VALUES (@NotificationTitle, @NotificationSubtitle, SYSUTCDATETIME(), 1);
                    """,
                    new
                    {
                        TenantId = normalizedTenantId,
                        PropertyId = existingTenant.PropertyId,
                        Title = "Tenant moved out",
                        Subtitle =
                            $"{existingTenant.Name} moved out from {existingTenant.PropertyName}.",
                        NotificationTitle = "Tenant moved out",
                        NotificationSubtitle =
                            $"{existingTenant.Name} moved out from {existingTenant.PropertyName}.",
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await transaction.CommitAsync(cancellationToken);

            return new MoveOutOwnerTenantResponse
            {
                Tenant = new TenantProfileDto
                {
                    Id = existingTenant.Id,
                    Name = existingTenant.Name,
                    Phone = existingTenant.Phone,
                    Nid = existingTenant.Nid,
                    PropertyName = string.Empty,
                },
                PreviousPropertyId = existingTenant.PropertyId,
                PreviousPropertyName = existingTenant.PropertyName,
                Message = "Tenant moved out successfully.",
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    private static void ValidateRequest(
        string fullName,
        string normalizedPhoneNumber,
        string nid,
        string propertyId)
    {
        if (string.IsNullOrWhiteSpace(fullName) || fullName.Length < 3)
        {
            throw new OwnerTenantValidationException(
                "Tenant name must contain at least 3 characters.");
        }

        if (normalizedPhoneNumber.Length < 10 || normalizedPhoneNumber.Length > 15)
        {
            throw new OwnerTenantValidationException(
                "Phone number must contain 10 to 15 digits.");
        }

        if (string.IsNullOrWhiteSpace(nid) || nid.Length < 10)
        {
            throw new OwnerTenantValidationException(
                "NID must contain at least 10 characters.");
        }

        if (string.IsNullOrWhiteSpace(propertyId))
        {
            throw new OwnerTenantValidationException("Property is required.");
        }
    }

    private static async Task<TenantLookup> GetTenantLookupAsync(
        SqlConnection connection,
        string tenantId,
        System.Data.Common.DbTransaction transaction,
        CancellationToken cancellationToken)
    {
        var tenant = await connection.QuerySingleOrDefaultAsync<TenantLookup>(
            new CommandDefinition(
                """
                SELECT
                    t.Id,
                    t.Name,
                    t.Phone,
                    t.Nid,
                    t.PropertyId,
                    COALESCE(p.Name, '') AS PropertyName
                FROM dbo.Tenants t
                LEFT JOIN dbo.Properties p ON p.Id = t.PropertyId
                WHERE t.Id = @TenantId;
                """,
                new { TenantId = tenantId },
                transaction: transaction,
                cancellationToken: cancellationToken));

        if (tenant is null)
        {
            throw new OwnerTenantNotFoundException("Tenant was not found.");
        }

        return tenant;
    }

    private static string NormalizeDigits(string value)
    {
        return new string(value.Where(char.IsDigit).ToArray());
    }

    private static string GenerateTemporaryPassword()
    {
        return $"Aa@{RandomNumberGenerator.GetInt32(100000, 1000000)}";
    }

    private sealed class PropertyLookup
    {
        public string Id { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public string Status { get; init; } = string.Empty;
        public string? TenantName { get; init; }
    }

    private sealed class DuplicateLookup
    {
        public bool HasPhoneNumber { get; init; }
        public bool HasNid { get; init; }
    }

    private sealed class TenantLookup
    {
        public string Id { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public string Phone { get; init; } = string.Empty;
        public string Nid { get; init; } = string.Empty;
        public string? PropertyId { get; init; }
        public string PropertyName { get; init; } = string.Empty;
    }
}

public sealed class OwnerTenantValidationException : Exception
{
    public OwnerTenantValidationException(string message)
        : base(message)
    {
    }
}

public sealed class OwnerTenantConflictException : Exception
{
    public OwnerTenantConflictException(string message)
        : base(message)
    {
    }
}

public sealed class OwnerTenantNotFoundException : Exception
{
    public OwnerTenantNotFoundException(string message)
        : base(message)
    {
    }
}
