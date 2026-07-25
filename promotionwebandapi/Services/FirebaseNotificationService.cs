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
