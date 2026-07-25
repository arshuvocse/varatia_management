using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Security;

namespace OrderProcessAPI.Services;

public sealed class AccountService : IAccountService
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly PasswordHasher _passwordHasher;

    public AccountService(
        SqlConnectionFactory connectionFactory,
        PasswordHasher passwordHasher)
    {
        _connectionFactory = connectionFactory;
        _passwordHasher = passwordHasher;
    }

    public async Task<UserProfileDto> GetProfileAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        var parsedUserId = ParseUserId(userId);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var user = await GetUserLookupAsync(
            connection,
            parsedUserId,
            transaction: null,
            cancellationToken);

        return MapToProfileDto(user);
    }

    public async Task<UpdateUserProfileResponse> UpdateProfileAsync(
        string userId,
        UpdateUserProfileRequest request,
        CancellationToken cancellationToken = default)
    {
        var parsedUserId = ParseUserId(userId);
        var fullName = request.FullName.Trim();
        var phoneNumber = request.PhoneNumber.Trim();
        var normalizedPhoneNumber = NormalizePhoneNumber(phoneNumber);

        ValidateProfile(fullName, normalizedPhoneNumber);

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        try
        {
            var user = await GetUserLookupAsync(
                connection,
                parsedUserId,
                transaction,
                cancellationToken);

            var duplicateUserId = await connection.ExecuteScalarAsync<Guid?>(
                new CommandDefinition(
                    """
                    SELECT TOP (1) Id
                    FROM dbo.Users
                    WHERE NormalizedPhoneNumber = @NormalizedPhoneNumber
                      AND Id <> @UserId;
                    """,
                    new
                    {
                        UserId = parsedUserId,
                        NormalizedPhoneNumber = normalizedPhoneNumber,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (duplicateUserId.HasValue)
            {
                throw new AccountConflictException(
                    "This phone number is already used by another account.");
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    UPDATE dbo.Users
                    SET
                        FullName = @FullName,
                        PhoneNumber = @PhoneNumber,
                        NormalizedPhoneNumber = @NormalizedPhoneNumber,
                        UpdatedAt = SYSUTCDATETIME()
                    WHERE Id = @UserId;
                    """,
                    new
                    {
                        UserId = parsedUserId,
                        FullName = fullName,
                        PhoneNumber = phoneNumber,
                        NormalizedPhoneNumber = normalizedPhoneNumber,
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            if (string.Equals(user.Role, "tenant", StringComparison.OrdinalIgnoreCase))
            {
                await SyncTenantProfileAsync(
                    connection,
                    transaction,
                    user,
                    fullName,
                    phoneNumber,
                    cancellationToken);
            }

            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Activities (Title, Subtitle, TimeLabel)
                    VALUES (@Title, @Subtitle, 'Today');
                    """,
                    new
                    {
                        Title = "Profile updated",
                        Subtitle = $"{fullName} updated account profile details.",
                    },
                    transaction: transaction,
                    cancellationToken: cancellationToken));

            await transaction.CommitAsync(cancellationToken);

            return new UpdateUserProfileResponse
            {
                Profile = new UserProfileDto
                {
                    UserId = parsedUserId.ToString(),
                    FullName = fullName,
                    PhoneNumber = phoneNumber,
                    Role = user.Role,
                    IsPhoneVerified = user.IsPhoneVerified,
                    FirebaseDeviceToken = user.FirebaseDeviceToken,
                    Imei = user.Imei,
                },
                Message = "Profile updated successfully.",
            };
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task<ChangePasswordResponse> ChangePasswordAsync(
        ChangePasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        var parsedUserId = ParseUserId(request.UserId);

        if (string.IsNullOrWhiteSpace(request.CurrentPassword))
        {
            throw new AccountValidationException("Current password is required.");
        }

        if (string.IsNullOrWhiteSpace(request.NewPassword) ||
            request.NewPassword.Length < 6)
        {
            throw new AccountValidationException(
                "New password must be at least 6 characters long.");
        }

        if (request.NewPassword != request.ConfirmPassword)
        {
            throw new AccountValidationException(
                "New password and confirm password do not match.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var user = await GetUserLookupAsync(
            connection,
            parsedUserId,
            transaction: null,
            cancellationToken);

        if (!_passwordHasher.Verify(
                request.CurrentPassword,
                user.PasswordHash,
                user.PasswordSalt))
        {
            throw new AccountSecurityException("Current password is incorrect.");
        }

        var passwordHash = _passwordHasher.Hash(request.NewPassword);

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Users
                SET
                    PasswordHash = @PasswordHash,
                    PasswordSalt = @PasswordSalt,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE Id = @UserId;
                """,
                new
                {
                    UserId = parsedUserId,
                    PasswordHash = passwordHash.Hash,
                    PasswordSalt = passwordHash.Salt,
                },
                cancellationToken: cancellationToken));

        return new ChangePasswordResponse
        {
            UserId = parsedUserId.ToString(),
            Message = "Password changed successfully.",
        };
    }

    private static Guid ParseUserId(string userId)
    {
        if (!Guid.TryParse(userId.Trim(), out var parsedUserId))
        {
            throw new AccountValidationException("Valid user id is required.");
        }

        return parsedUserId;
    }

    private static void ValidateProfile(string fullName, string normalizedPhoneNumber)
    {
        if (string.IsNullOrWhiteSpace(fullName) || fullName.Length < 3)
        {
            throw new AccountValidationException(
                "Full name must contain at least 3 characters.");
        }

        if (normalizedPhoneNumber.Length < 10 || normalizedPhoneNumber.Length > 15)
        {
            throw new AccountValidationException(
                "Phone number must contain 10 to 15 digits.");
        }
    }

    private static string NormalizePhoneNumber(string phoneNumber)
    {
        return new string(phoneNumber.Where(char.IsDigit).ToArray());
    }

    private static UserProfileDto MapToProfileDto(UserLookup user)
    {
        return new UserProfileDto
        {
            UserId = user.Id.ToString(),
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            Role = user.Role,
            IsPhoneVerified = user.IsPhoneVerified,
            FirebaseDeviceToken = user.FirebaseDeviceToken,
            Imei = user.Imei,
        };
    }

    private static async Task<UserLookup> GetUserLookupAsync(
        Microsoft.Data.SqlClient.SqlConnection connection,
        Guid userId,
        System.Data.Common.DbTransaction? transaction,
        CancellationToken cancellationToken)
    {
        var user = await connection.QuerySingleOrDefaultAsync<UserLookup>(
            new CommandDefinition(
                """
                SELECT
                    Id,
                    FullName,
                    PhoneNumber,
                    NormalizedPhoneNumber,
                    Role,
                    FirebaseDeviceToken,
                    Imei,
                    IsPhoneVerified,
                    PasswordHash,
                    PasswordSalt
                FROM dbo.Users
                WHERE Id = @UserId;
                """,
                new { UserId = userId },
                transaction: transaction,
                cancellationToken: cancellationToken));

        if (user is null)
        {
            throw new AccountNotFoundException("User was not found.");
        }

        return user;
    }

    private static async Task SyncTenantProfileAsync(
        Microsoft.Data.SqlClient.SqlConnection connection,
        System.Data.Common.DbTransaction transaction,
        UserLookup user,
        string fullName,
        string phoneNumber,
        CancellationToken cancellationToken)
    {
        var tenant = await connection.QuerySingleOrDefaultAsync<TenantLookup>(
            new CommandDefinition(
                """
                SELECT TOP (1)
                    t.Id,
                    t.Name,
                    t.Phone,
                    t.PropertyId
                FROM dbo.Tenants t
                WHERE t.Phone = @PhoneNumber;
                """,
                new { PhoneNumber = user.PhoneNumber },
                transaction: transaction,
                cancellationToken: cancellationToken));

        if (tenant is null)
        {
            return;
        }

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Tenants
                SET
                    Name = @Name,
                    Phone = @Phone
                WHERE Id = @TenantId;
                """,
                new
                {
                    TenantId = tenant.Id,
                    Name = fullName,
                    Phone = phoneNumber,
                },
                transaction: transaction,
                cancellationToken: cancellationToken));

        if (string.IsNullOrWhiteSpace(tenant.PropertyId))
        {
            return;
        }

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
                    PropertyId = tenant.PropertyId,
                    TenantName = fullName,
                    PreviousTenantName = tenant.Name,
                },
                transaction: transaction,
                cancellationToken: cancellationToken));
    }

    private sealed class UserLookup
    {
        public Guid Id { get; init; }
        public string FullName { get; init; } = string.Empty;
        public string PhoneNumber { get; init; } = string.Empty;
        public string NormalizedPhoneNumber { get; init; } = string.Empty;
        public string? Role { get; init; }
        public string? FirebaseDeviceToken { get; init; }
        public string? Imei { get; init; }
        public bool IsPhoneVerified { get; init; }
        public string PasswordHash { get; init; } = string.Empty;
        public string PasswordSalt { get; init; } = string.Empty;
    }

    private sealed class TenantLookup
    {
        public string Id { get; init; } = string.Empty;
        public string Name { get; init; } = string.Empty;
        public string Phone { get; init; } = string.Empty;
        public string? PropertyId { get; init; }
    }
}

public sealed class AccountValidationException : Exception
{
    public AccountValidationException(string message)
        : base(message)
    {
    }
}

public sealed class AccountNotFoundException : Exception
{
    public AccountNotFoundException(string message)
        : base(message)
    {
    }
}

public sealed class AccountConflictException : Exception
{
    public AccountConflictException(string message)
        : base(message)
    {
    }
}

public sealed class AccountSecurityException : Exception
{
    public AccountSecurityException(string message)
        : base(message)
    {
    }
}
