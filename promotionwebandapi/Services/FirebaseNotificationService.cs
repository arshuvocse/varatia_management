using Dapper;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Options;
using OrderProcessAPI.Configuration;
using OrderProcessAPI.Contracts;

namespace OrderProcessAPI.Services;

public sealed class FirebaseNotificationService : INotificationService
{
    private static readonly object FirebaseAppLock = new();

    private readonly SqlConnectionFactory _connectionFactory;
    private readonly IWebHostEnvironment _environment;
    private readonly FirebaseNotificationOptions _options;

    public FirebaseNotificationService(
        SqlConnectionFactory connectionFactory,
        IWebHostEnvironment environment,
        IOptions<FirebaseNotificationOptions> options)
    {
        _connectionFactory = connectionFactory;
        _environment = environment;
        _options = options.Value;
    }

    public async Task<IReadOnlyList<NotificationListItemDto>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var items = await connection.QueryAsync<NotificationListItemDto>(
            new CommandDefinition(
                """
                SELECT Id, Title, Subtitle, CreatedAt, IsUnread
                FROM dbo.Notifications
                ORDER BY CreatedAt DESC;
                """,
                cancellationToken: cancellationToken));

        return items.ToList();
    }

    public async Task<SendUserNotificationResponse> SendToUserAsync(
        SendUserNotificationRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(request.UserId.Trim(), out var userId))
        {
            throw new NotificationValidationException("Valid user id is required.");
        }

        var title = request.Title.Trim();
        var body = request.Body.Trim();
        if (string.IsNullOrWhiteSpace(title))
        {
            throw new NotificationValidationException("Notification title is required.");
        }

        if (string.IsNullOrWhiteSpace(body))
        {
            throw new NotificationValidationException("Notification body is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var user = await connection.QuerySingleOrDefaultAsync<UserNotificationLookup>(
            new CommandDefinition(
                """
                SELECT TOP (1)
                    Id,
                    FirebaseDeviceToken
                FROM dbo.Users
                WHERE Id = @UserId;
                """,
                new { UserId = userId },
                cancellationToken: cancellationToken));

        if (user is null)
        {
            throw new NotificationNotFoundException("User was not found.");
        }

        if (string.IsNullOrWhiteSpace(user.FirebaseDeviceToken))
        {
            throw new NotificationValidationException(
                "User does not have a saved Firebase device token.");
        }

        var firebaseMessageId = _environment.IsDevelopment()
            ? $"dev-notification-{Guid.NewGuid():N}"
            : await SendFirebaseNotificationAsync(
                user.FirebaseDeviceToken,
                title,
                body,
                request.Data,
                cancellationToken);

        await connection.ExecuteAsync(
            new CommandDefinition(
                """
                INSERT INTO dbo.Notifications (Title, Subtitle, CreatedAt, IsUnread)
                VALUES (@Title, @Subtitle, SYSUTCDATETIME(), 1);
                """,
                new
                {
                    Title = title,
                    Subtitle = body,
                },
                cancellationToken: cancellationToken));

        return new SendUserNotificationResponse
        {
            UserId = userId.ToString(),
            FirebaseMessageId = firebaseMessageId,
            Message = "Notification sent successfully.",
        };
    }

    public async Task<MarkNotificationReadResponse> MarkAsReadAsync(
        int notificationId,
        CancellationToken cancellationToken = default)
    {
        if (notificationId <= 0)
        {
            throw new NotificationValidationException(
                "Valid notification id is required.");
        }

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var affectedRows = await connection.ExecuteAsync(
            new CommandDefinition(
                """
                UPDATE dbo.Notifications
                SET IsUnread = 0
                WHERE Id = @NotificationId;
                """,
                new { NotificationId = notificationId },
                cancellationToken: cancellationToken));

        if (affectedRows == 0)
        {
            throw new NotificationNotFoundException("Notification was not found.");
        }

        return new MarkNotificationReadResponse
        {
            NotificationId = notificationId,
            Message = "Notification marked as read.",
        };
    }

    public async Task<SendRentNoticeResponse> SendRentNoticeAsync(
        SendRentNoticeRequest request,
        CancellationToken cancellationToken = default)
    {
        var propertyName = (request.PropertyName ?? string.Empty).Trim();
        var tenantName = (request.TenantName ?? string.Empty).Trim();
        var amount = request.Amount;

        if (string.IsNullOrWhiteSpace(propertyName))
        {
            throw new NotificationValidationException("Property name is required.");
        }

        var now = DateTime.Now;
        var todayBangla = $"{ToBanglaDigits(now.Day)} {GetBanglaMonth(now.Month)}, {ToBanglaDigits(now.Year)}";
        var title = "📢 ভাড়ার নোটিশ";
        var body = $"আপনার আজকে {todayBangla}, আপনাকে {propertyName}-এর ভাড়া ৳{ToBanglaDigits((long)amount)} পেমেন্ট করতে হবে।";

        await using var connection = _connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        var notificationId = await connection.ExecuteScalarAsync<int>(
            new CommandDefinition(
                """
                INSERT INTO dbo.Notifications (Title, Subtitle, CreatedAt, IsUnread)
                OUTPUT INSERTED.Id
                VALUES (@Title, @Subtitle, SYSUTCDATETIME(), 1);
                """,
                new
                {
                    Title = title,
                    Subtitle = body,
                },
                cancellationToken: cancellationToken));

        var timeLabel = now.ToString("hh:mm tt");
        try
        {
            await connection.ExecuteAsync(
                new CommandDefinition(
                    """
                    INSERT INTO dbo.Messages (Sender, Message, PropertyName, TimeLabel)
                    VALUES (@Sender, @Message, @PropertyName, @TimeLabel);
                    """,
                    new
                    {
                        Sender = "বাড়িওয়ালা (Owner)",
                        Message = body,
                        PropertyName = propertyName,
                        TimeLabel = timeLabel,
                    },
                    cancellationToken: cancellationToken));
        }
        catch
        {
            // Optional message insertion fallback
        }

        if (!string.IsNullOrWhiteSpace(request.UserId) && Guid.TryParse(request.UserId.Trim(), out var parsedUserId))
        {
            try
            {
                var user = await connection.QuerySingleOrDefaultAsync<UserNotificationLookup>(
                    new CommandDefinition(
                        """
                        SELECT TOP (1) Id, FirebaseDeviceToken
                        FROM dbo.Users
                        WHERE Id = @UserId;
                        """,
                        new { UserId = parsedUserId },
                        cancellationToken: cancellationToken));

                if (user is not null && !string.IsNullOrWhiteSpace(user.FirebaseDeviceToken) && !_environment.IsDevelopment())
                {
                    await SendFirebaseNotificationAsync(
                        user.FirebaseDeviceToken,
                        title,
                        body,
                        new Dictionary<string, string>
                        {
                            ["type"] = "rent_notice",
                            ["propertyName"] = propertyName,
                            ["amount"] = amount.ToString("0"),
                        },
                        cancellationToken);
                }
            }
            catch
            {
                // Push delivery failure shouldn't cancel notice creation
            }
        }

        return new SendRentNoticeResponse
        {
            NotificationId = notificationId,
            Title = title,
            Subtitle = body,
            Message = "Rent notice sent successfully.",
        };
    }

    private static string ToBanglaDigits(long value)
    {
        var str = value.ToString();
        var sb = new System.Text.StringBuilder();
        foreach (var c in str)
        {
            sb.Append(c switch
            {
                '0' => '০',
                '1' => '১',
                '2' => '২',
                '3' => '৩',
                '4' => '৪',
                '5' => '৫',
                '6' => '৬',
                '7' => '৭',
                '8' => '৮',
                '9' => '৯',
                _ => c
            });
        }
        return sb.ToString();
    }

    private static string GetBanglaMonth(int month) => month switch
    {
        1 => "জানুয়ারি",
        2 => "ফেব্রুয়ারি",
        3 => "মার্চ",
        4 => "এপ্রিল",
        5 => "মে",
        6 => "জুন",
        7 => "জুলাই",
        8 => "আগস্ট",
        9 => "সেপ্টেম্বর",
        10 => "অক্টোবর",
        11 => "নভেম্বর",
        12 => "ডিসেম্বর",
        _ => string.Empty
    };

    private FirebaseApp GetOrCreateFirebaseApp()
    {
        if (FirebaseApp.DefaultInstance is not null)
        {
            return FirebaseApp.DefaultInstance;
        }

        lock (FirebaseAppLock)
        {
            if (FirebaseApp.DefaultInstance is not null)
            {
                return FirebaseApp.DefaultInstance;
            }

            var credentialPath = ResolveServiceAccountPath();

            if (!File.Exists(credentialPath))
            {
                throw new NotificationValidationException(
                    "Firebase service account file was not found.");
            }

            return FirebaseApp.Create(
                new AppOptions
                {
                    Credential = CredentialFactory
                        .FromFile<ServiceAccountCredential>(credentialPath)
                        .ToGoogleCredential(),
                });
        }
    }

    private string ResolveAndroidChannelId()
    {
        return string.IsNullOrWhiteSpace(_options.AndroidChannelId)
            ? FirebaseNotificationOptions.DefaultAndroidChannelId
            : _options.AndroidChannelId.Trim();
    }

    private string ResolveServiceAccountPath()
    {
        var configuredPath = string.IsNullOrWhiteSpace(_options.ServiceAccountPath)
            ? FirebaseNotificationOptions.DefaultServiceAccountPath
            : _options.ServiceAccountPath.Trim();

        return Path.IsPathRooted(configuredPath)
            ? configuredPath
            : Path.GetFullPath(Path.Combine(_environment.ContentRootPath, configuredPath));
    }

    private async Task<string> SendFirebaseNotificationAsync(
        string deviceToken,
        string title,
        string body,
        IReadOnlyDictionary<string, string>? data,
        CancellationToken cancellationToken)
    {
        var firebaseApp = GetOrCreateFirebaseApp();
        var message = new Message
        {
            Token = deviceToken,
            Notification = new Notification
            {
                Title = title,
                Body = body,
            },
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    ChannelId = ResolveAndroidChannelId(),
                    DefaultSound = true,
                    DefaultVibrateTimings = true,
                    Priority = NotificationPriority.MAX,
                },
            },
            Data = data is null
                ? null
                : new Dictionary<string, string>(data),
        };

        return await FirebaseMessaging
            .GetMessaging(firebaseApp)
            .SendAsync(message, dryRun: false, cancellationToken);
    }

    private sealed class UserNotificationLookup
    {
        public Guid Id { get; init; }
        public string? FirebaseDeviceToken { get; init; }
    }
}

public sealed class NotificationValidationException : Exception
{
    public NotificationValidationException(string message)
        : base(message)
    {
    }
}

public sealed class NotificationNotFoundException : Exception
{
    public NotificationNotFoundException(string message)
        : base(message)
    {
    }
}
