using System.Collections.Concurrent;

namespace PromotionWeb.Services;

public sealed class DeliveryApiTokenStore
{
    private readonly ConcurrentDictionary<string, DeliveryApiSession> _sessions = new();

    public string Create(int userId, string name, string phone, string role = "")
    {
        var token = Guid.NewGuid().ToString("N");
        _sessions[token] = new DeliveryApiSession(userId, name, phone, role, DateTimeOffset.UtcNow.AddDays(30));
        return token;
    }

    public DeliveryApiSession? Get(string? authorizationHeader)
    {
        const string prefix = "Bearer ";
        if (string.IsNullOrWhiteSpace(authorizationHeader)
            || !authorizationHeader.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var token = authorizationHeader[prefix.Length..].Trim();
        if (!_sessions.TryGetValue(token, out var session))
        {
            return null;
        }

        if (session.ExpiresAt <= DateTimeOffset.UtcNow)
        {
            _sessions.TryRemove(token, out _);
            return null;
        }

        return session;
    }

    public DeliveryApiSession? GetToken(string? token)
    {
        if (string.IsNullOrWhiteSpace(token) || !_sessions.TryGetValue(token.Trim(), out var session))
        {
            return null;
        }

        if (session.ExpiresAt <= DateTimeOffset.UtcNow)
        {
            _sessions.TryRemove(token.Trim(), out _);
            return null;
        }

        return session;
    }

    public void Revoke(string? authorizationHeader)
    {
        const string prefix = "Bearer ";
        if (!string.IsNullOrWhiteSpace(authorizationHeader)
            && authorizationHeader.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            _sessions.TryRemove(authorizationHeader[prefix.Length..].Trim(), out _);
        }
    }
}

public sealed record DeliveryApiSession(int UserId, string Name, string Phone, string Role, DateTimeOffset ExpiresAt);
