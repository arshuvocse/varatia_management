using System.Security.Cryptography;
using Dapper;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;
using OrderProcessAPI.Security;

namespace OrderProcessAPI.Services;

public sealed class AuthService : IAuthService
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly PasswordHasher _passwordHasher;
    private readonly ISmsOtpService _smsOtpService;

    public AuthService(
        SqlConnectionFactory connectionFactory,
        PasswordHasher passwordHasher,
        ISmsOtpService smsOtpService)
    {
        _connectionFactory = connectionFactory;
        _passwordHasher = passwordHasher;
        _smsOtpService = smsOtpService;
    }

    public async Task<RegisterUserResponse> RegisterAsync(
        RegisterUserRequest request,
        CancellationToken cancellationToken = default)
    {
        var fullName = request.FullName.Trim();
        var phoneNumber = request.PhoneNumber.Trim();
        var normalizedPhoneNumber = NormalizePhoneNumber(phoneNumber);
        var role = NormalizeRegistrationRole(request.Role);
        var firebaseDeviceToken = NormalizeOptionalValue(request.FirebaseDeviceToken);
        var imei = NormalizeOptionalValue(request.Imei);

        ValidateRequest(request, fullName, normalizedPhoneNumber);

        if (normalizedPhoneNumber == "+8801711111111" || normalizedPhoneNumber == "01711111111" || normalizedPhoneNumber == "8801711111111")
        {
            throw new AuthValidationException(
                "This phone number is reserved for admin login only. Registration is not allowed.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var existingUserId = await connection.ExecuteScalarAsync<Guid?>(
            new CommandDefinition(
                """
                SELECT TOP (1) Id
                FROM dbo.Users
                WHERE NormalizedPhoneNumber = @NormalizedPhoneNumber;
                """,
                new { NormalizedPhoneNumber = normalizedPhoneNumber },
                cancellationToken: cancellationToken));

        if (existingUserId.HasValue)
        {
            throw new DuplicatePhoneNumberException(
                "An account already exists for this phone number.");
        }

        var passwordHash = _passwordHasher.Hash(request.Password);
        var userId = Guid.NewGuid();
        var otpCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        var otpExpiresAt = DateTime.UtcNow.AddMinutes(10);

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
                    FirebaseDeviceToken,
                    Imei,
                    DeviceUpdatedAt,
                    IsPhoneVerified,
                    LastOtpCode,
                    OtpExpiresAt,
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
                    @Role,
                    @FirebaseDeviceToken,
                    @Imei,
                    CASE
                        WHEN @FirebaseDeviceToken IS NULL AND @Imei IS NULL
                        THEN NULL
                        ELSE SYSUTCDATETIME()
                    END,
                    0,
                    @LastOtpCode,
                    @OtpExpiresAt,
                    SYSUTCDATETIME(),
                    SYSUTCDATETIME()
                );
                """,
                new
                {
                    Id = userId,
                    FullName = fullName,
                    PhoneNumber = phoneNumber,
                    NormalizedPhoneNumber = normalizedPhoneNumber,
                    PasswordHash = passwordHash.Hash,
                    PasswordSalt = passwordHash.Salt,
                    Role = role,
                    FirebaseDeviceToken = firebaseDeviceToken,
                    Imei = imei,
                    LastOtpCode = otpCode,
                    OtpExpiresAt = otpExpiresAt,
                },
                cancellationToken: cancellationToken));

        var smsResult = await _smsOtpService.SendOtpAsync(
            phoneNumber,
            otpCode,
            cancellationToken);

        return new RegisterUserResponse
        {
            UserId = userId.ToString(),
            FullName = fullName,
            PhoneNumber = phoneNumber,
            OtpRequired = true,
            OtpExpiresAt = otpExpiresAt,
            DebugOtpCode = otpCode,
            Message = smsResult.IsSuccess
                ? "Registration completed successfully. OTP was sent."
                : $"Registration completed successfully. OTP SMS failed: {smsResult.ErrorMessage}",
        };
    }

    public async Task<LoginUserResponse> LoginAsync(
        LoginUserRequest request,
        CancellationToken cancellationToken = default)
    {
        var phoneNumber = request.PhoneNumber.Trim();
        var normalizedPhoneNumber = NormalizePhoneNumber(phoneNumber);
        var firebaseDeviceToken = NormalizeOptionalValue(request.FirebaseDeviceToken);
        var imei = NormalizeOptionalValue(request.Imei);

        if (normalizedPhoneNumber.Length < 10 || normalizedPhoneNumber.Length > 15)
        {
            throw new AuthValidationException(
                "Phone number must contain 10 to 15 digits.");
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            throw new AuthValidationException("Password is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var user = await connection.QuerySingleOrDefaultAsync<AuthUserLookup>(
            new CommandDefinition(
                """
                SELECT TOP (1)
                    Id,
                    FullName,
                    PhoneNumber,
                    PasswordHash,
                    PasswordSalt,
                    CreatedAt,
                    Role,
                    IsPhoneVerified
                FROM dbo.Users
                WHERE NormalizedPhoneNumber = @NormalizedPhoneNumber;
                """,
                new { NormalizedPhoneNumber = normalizedPhoneNumber },
                cancellationToken: cancellationToken));

        if (user is null ||
            !_passwordHasher.Verify(
                request.Password,
                user.PasswordHash,
                user.PasswordSalt))
        {
            throw new InvalidCredentialsException(
                "Invalid phone number or password.");
        }

        // Auto-assign admin role for a specific demo phone number
        if (normalizedPhoneNumber == "+8801711111111" || normalizedPhoneNumber == "01711111111" || normalizedPhoneNumber == "8801711111111")
        {
            user.Role = "admin";
            await connection.ExecuteAsync(
                "UPDATE dbo.Users SET Role = 'admin' WHERE Id = @Id", 
                new { Id = user.Id });
        }

        await SaveDeviceAsync(
            user.Id,
            firebaseDeviceToken,
            imei,
            connection,
            cancellationToken);

        if (!user.IsPhoneVerified)
        {
            var otpCode = RandomNumberGenerator
                .GetInt32(100000, 1000000)
                .ToString();
            var otpExpiresAt = DateTime.UtcNow.AddMinutes(10);

            await SaveOtpAsync(
                user.Id,
                otpCode,
                otpExpiresAt,
                connection,
                cancellationToken);

            var smsResult = await _smsOtpService.SendOtpAsync(
                user.PhoneNumber,
                otpCode,
                cancellationToken);

            return new LoginUserResponse
            {
                UserId = user.Id.ToString(),
                FullName = user.FullName,
                PhoneNumber = user.PhoneNumber,
                CreatedAt = user.CreatedAt,
                Role = user.Role,
                IsPhoneVerified = false,
                OtpRequired = true,
                OtpExpiresAt = otpExpiresAt,
                DebugOtpCode = otpCode,
                Message = smsResult.IsSuccess
                    ? "Please verify OTP before continuing."
                    : $"Please verify OTP before continuing. OTP SMS failed: {smsResult.ErrorMessage}",
            };
        }

        return new LoginUserResponse
        {
            UserId = user.Id.ToString(),
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            CreatedAt = user.CreatedAt,
            Role = user.Role,
            IsPhoneVerified = true,
            OtpRequired = false,
            Message = "Login successful.",
        };
    }

    public async Task<VerifyOtpResponse> VerifyOtpAsync(
        VerifyOtpRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(request.UserId.Trim(), out var userId))
        {
            throw new AuthValidationException("Valid user id is required.");
        }

        var otpCode = NormalizePhoneNumber(request.OtpCode);
        if (otpCode.Length != 6)
        {
            throw new AuthValidationException("OTP code must contain 6 digits.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var user = await connection.QuerySingleOrDefaultAsync<AuthUserOtpLookup>(
            new CommandDefinition(
                """
                SELECT TOP (1)
                    Id,
                    FullName,
                    PhoneNumber,
                    LastOtpCode,
                    OtpExpiresAt
                FROM dbo.Users
                WHERE Id = @UserId;
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        if (user is null)
        {
            throw new AuthNotFoundException("User was not found.");
        }

        if (string.IsNullOrWhiteSpace(user.LastOtpCode) ||
            user.OtpExpiresAt is null ||
            user.OtpExpiresAt <= DateTime.UtcNow ||
            user.LastOtpCode != otpCode)
        {
            throw new AuthValidationException("OTP code is invalid or expired.");
        }

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Users
                SET
                    IsPhoneVerified = 1,
                    LastOtpCode = NULL,
                    OtpExpiresAt = NULL,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE Id = @UserId;
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        return new VerifyOtpResponse
        {
            UserId = user.Id.ToString(),
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            IsPhoneVerified = true,
            Message = "OTP verified successfully.",
        };
    }

    public async Task<ResendOtpResponse> ResendOtpAsync(
        ResendOtpRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(request.UserId.Trim(), out var userId))
        {
            throw new AuthValidationException("Valid user id is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var user = await connection.QuerySingleOrDefaultAsync<AuthUserPhoneLookup>(
            new CommandDefinition(
                """
                SELECT TOP (1) Id, PhoneNumber
                FROM dbo.Users
                WHERE Id = @UserId;
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        if (user is null)
        {
            throw new AuthNotFoundException("User was not found.");
        }

        var otpCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        var otpExpiresAt = DateTime.UtcNow.AddMinutes(10);

        await SaveOtpAsync(
            user.Id,
            otpCode,
            otpExpiresAt,
            connection,
            cancellationToken);

        var smsResult = await _smsOtpService.SendOtpAsync(
            user.PhoneNumber,
            otpCode,
            cancellationToken);

        return new ResendOtpResponse
        {
            UserId = user.Id.ToString(),
            PhoneNumber = user.PhoneNumber,
            OtpExpiresAt = otpExpiresAt,
            DebugOtpCode = otpCode,
            Message = smsResult.IsSuccess
                ? "OTP code was resent successfully."
                : $"OTP code was generated, but SMS failed: {smsResult.ErrorMessage}",
        };
    }

    public async Task<ForgotPasswordResponse> RequestPasswordResetAsync(
        ForgotPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        var phoneNumber = request.PhoneNumber.Trim();
        var normalizedPhoneNumber = NormalizePhoneNumber(phoneNumber);

        if (normalizedPhoneNumber.Length < 10 || normalizedPhoneNumber.Length > 15)
        {
            throw new AuthValidationException(
                "Phone number must contain 10 to 15 digits.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var user = await connection.QuerySingleOrDefaultAsync<AuthUserPhoneLookup>(
            new CommandDefinition(
                """
                SELECT TOP (1) Id, PhoneNumber
                FROM dbo.Users
                WHERE NormalizedPhoneNumber = @NormalizedPhoneNumber;
                """,
                new { NormalizedPhoneNumber = normalizedPhoneNumber },
                cancellationToken: cancellationToken));

        if (user is null)
        {
            throw new AuthNotFoundException(
                "No account was found for this phone number.");
        }

        var otpCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        var otpExpiresAt = DateTime.UtcNow.AddMinutes(10);

        await SaveOtpAsync(
            user.Id,
            otpCode,
            otpExpiresAt,
            connection,
            cancellationToken);

        var smsResult = await _smsOtpService.SendOtpAsync(
            user.PhoneNumber,
            otpCode,
            cancellationToken);

        return new ForgotPasswordResponse
        {
            UserId = user.Id.ToString(),
            PhoneNumber = user.PhoneNumber,
            OtpExpiresAt = otpExpiresAt,
            DebugOtpCode = otpCode,
            Message = smsResult.IsSuccess
                ? "Password reset OTP was sent successfully."
                : $"Password reset OTP was generated, but SMS failed: {smsResult.ErrorMessage}",
        };
    }

    public async Task<ResetPasswordResponse> ResetPasswordAsync(
        ResetPasswordRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(request.UserId.Trim(), out var userId))
        {
            throw new AuthValidationException("Valid user id is required.");
        }

        var otpCode = NormalizePhoneNumber(request.OtpCode);
        if (otpCode.Length != 6)
        {
            throw new AuthValidationException("OTP code must contain 6 digits.");
        }

        if (string.IsNullOrWhiteSpace(request.NewPassword) ||
            request.NewPassword.Length < 6)
        {
            throw new AuthValidationException(
                "New password must be at least 6 characters long.");
        }

        if (request.NewPassword != request.ConfirmPassword)
        {
            throw new AuthValidationException(
                "New password and confirm password do not match.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var user = await connection.QuerySingleOrDefaultAsync<AuthUserOtpLookup>(
            new CommandDefinition(
                """
                SELECT TOP (1)
                    Id,
                    FullName,
                    PhoneNumber,
                    LastOtpCode,
                    OtpExpiresAt
                FROM dbo.Users
                WHERE Id = @UserId;
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        if (user is null)
        {
            throw new AuthNotFoundException("User was not found.");
        }

        if (string.IsNullOrWhiteSpace(user.LastOtpCode) ||
            user.OtpExpiresAt is null ||
            user.OtpExpiresAt <= DateTime.UtcNow ||
            user.LastOtpCode != otpCode)
        {
            throw new AuthValidationException("OTP code is invalid or expired.");
        }

        var passwordHash = _passwordHasher.Hash(request.NewPassword);

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Users
                SET
                    PasswordHash = @PasswordHash,
                    PasswordSalt = @PasswordSalt,
                    IsPhoneVerified = 1,
                    LastOtpCode = NULL,
                    OtpExpiresAt = NULL,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE Id = @UserId;
                """,
                new
                {
                    UserId = userId,
                    PasswordHash = passwordHash.Hash,
                    PasswordSalt = passwordHash.Salt,
                },
                cancellationToken: cancellationToken));

        return new ResetPasswordResponse
        {
            UserId = userId.ToString(),
            PhoneNumber = user.PhoneNumber,
            Message = "Password reset successfully.",
        };
    }

    public async Task<UpdateDeviceInfoResponse> UpdateDeviceInfoAsync(
        UpdateDeviceInfoRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(request.UserId.Trim(), out var userId))
        {
            throw new AuthValidationException("Valid user id is required.");
        }

        var firebaseDeviceToken = NormalizeOptionalValue(request.FirebaseDeviceToken);
        var imei = NormalizeOptionalValue(request.Imei);

        if (firebaseDeviceToken is null && imei is null)
        {
            throw new AuthValidationException(
                "At least one device field is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var exists = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                SELECT COUNT(1)
                FROM dbo.Users
                WHERE Id = @UserId;
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        if (exists == 0)
        {
            throw new AuthNotFoundException("User was not found.");
        }

        await SaveDeviceAsync(
            userId,
            firebaseDeviceToken,
            imei,
            connection,
            cancellationToken);

        return new UpdateDeviceInfoResponse
        {
            UserId = userId.ToString(),
            FirebaseDeviceToken = firebaseDeviceToken,
            Imei = imei,
            Message = "Device info updated successfully.",
        };
    }

    public async Task<SendOtpResponse> SendOtpAsync(
        SendOtpRequest request,
        CancellationToken cancellationToken = default)
    {
        var mobileNumber = NormalizePhoneNumber(request.MobileNumber);
        var otpCode = NormalizePhoneNumber(request.OtpCode);

        if (mobileNumber.Length < 10 || mobileNumber.Length > 15)
        {
            throw new AuthValidationException(
                "Mobile number must contain 10 to 15 digits.");
        }

        if (otpCode.Length != 6)
        {
            throw new AuthValidationException("OTP code must contain 6 digits.");
        }

        var result = await _smsOtpService.SendOtpAsync(
            mobileNumber,
            otpCode,
            cancellationToken);

        return new SendOtpResponse
        {
            IsSuccess = result.IsSuccess,
            IsError = result.IsError,
            ProviderResponse = result.ProviderResponse,
            ErrorMessage = result.ErrorMessage,
            Message = result.IsSuccess
                ? "OTP sent successfully."
                : "OTP send failed.",
        };
    }

    private static void ValidateRequest(
        RegisterUserRequest request,
        string fullName,
        string normalizedPhoneNumber)
    {
        if (string.IsNullOrWhiteSpace(fullName) || fullName.Length < 3)
        {
            throw new AuthValidationException(
                "Full name must contain at least 3 characters.");
        }

        if (normalizedPhoneNumber.Length < 10 || normalizedPhoneNumber.Length > 15)
        {
            throw new AuthValidationException(
                "Phone number must contain 10 to 15 digits.");
        }

        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
        {
            throw new AuthValidationException(
                "Password must be at least 6 characters long.");
        }

        if (request.Password != request.ConfirmPassword)
        {
            throw new AuthValidationException(
                "Password and confirm password do not match.");
        }
    }

    private static string NormalizePhoneNumber(string phoneNumber)
    {
        return new string(phoneNumber.Where(char.IsDigit).ToArray());
    }

    private static string? NormalizeOptionalValue(string? value)
    {
        var normalizedValue = value?.Trim();
        return string.IsNullOrWhiteSpace(normalizedValue) ? null : normalizedValue;
    }

    private static string NormalizeRegistrationRole(string? role)
    {
        var normalizedRole = role?.Trim().ToLowerInvariant();
        return normalizedRole switch
        {
            null or "" => "tenant",
            "tenant" => "tenant",
            "owner" or "propertyowner" or "property owner" or "flat owner" => "owner",
            _ => throw new AuthValidationException(
                "Role must be either tenant or owner."),
        };
    }

    private static async Task SaveOtpAsync(
        Guid userId,
        string otpCode,
        DateTime otpExpiresAt,
        System.Data.IDbConnection connection,
        CancellationToken cancellationToken)
    {
        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Users
                SET
                    LastOtpCode = @OtpCode,
                    OtpExpiresAt = @OtpExpiresAt,
                    UpdatedAt = SYSUTCDATETIME()
                WHERE Id = @UserId;
                """,
                new
                {
                    UserId = userId,
                    OtpCode = otpCode,
                    OtpExpiresAt = otpExpiresAt,
                },
                cancellationToken: cancellationToken));
    }

    private static async Task SaveDeviceAsync(
        Guid userId,
        string? firebaseDeviceToken,
        string? imei,
        System.Data.IDbConnection connection,
        CancellationToken cancellationToken)
    {
        if (firebaseDeviceToken is null && imei is null)
        {
            return;
        }

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Users
                SET
                    FirebaseDeviceToken = COALESCE(@FirebaseDeviceToken, FirebaseDeviceToken),
                    Imei = COALESCE(@Imei, Imei),
                    DeviceUpdatedAt = SYSUTCDATETIME(),
                    UpdatedAt = SYSUTCDATETIME()
                WHERE Id = @UserId;
                """,
                new
                {
                    UserId = userId,
                    FirebaseDeviceToken = firebaseDeviceToken,
                    Imei = imei,
                },
                cancellationToken: cancellationToken));
    }

    private sealed class AuthUserLookup
    {
        public Guid Id { get; init; }
        public string FullName { get; init; } = string.Empty;
        public string PhoneNumber { get; init; } = string.Empty;
        public string PasswordHash { get; init; } = string.Empty;
        public string PasswordSalt { get; init; } = string.Empty;
        public DateTime CreatedAt { get; init; }
        public string? Role { get; set; }
        public bool IsPhoneVerified { get; init; }
    }

    private sealed class AuthUserOtpLookup
    {
        public Guid Id { get; init; }
        public string FullName { get; init; } = string.Empty;
        public string PhoneNumber { get; init; } = string.Empty;
        public string? LastOtpCode { get; init; }
        public DateTime? OtpExpiresAt { get; init; }
    }

    private sealed class AuthUserPhoneLookup
    {
        public Guid Id { get; init; }
        public string PhoneNumber { get; init; } = string.Empty;
    }
}

public sealed class AuthValidationException : Exception
{
    public AuthValidationException(string message)
        : base(message)
    {
    }
}

public sealed class DuplicatePhoneNumberException : Exception
{
    public DuplicatePhoneNumberException(string message)
        : base(message)
    {
    }
}

public sealed class InvalidCredentialsException : Exception
{
    public InvalidCredentialsException(string message)
        : base(message)
    {
    }
}

public sealed class AuthNotFoundException : Exception
{
    public AuthNotFoundException(string message)
        : base(message)
    {
    }
}
