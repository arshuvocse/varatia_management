namespace OrderProcessAPI.Configuration;

public sealed class FirebaseNotificationOptions
{
    public const string SectionName = "Firebase";
    public const string DefaultAndroidChannelId = "high_importance_channel";
    public const string DefaultServiceAccountPath =
        "Firebase/varatiamanagement-firebase-adminsdk-fbsvc-f2c673db39.json";

    public string ServiceAccountPath { get; init; } = DefaultServiceAccountPath;
    public string AndroidChannelId { get; init; } = DefaultAndroidChannelId;
}
