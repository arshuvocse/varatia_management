using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;

namespace OrderProcessAPI.Middleware;

public sealed class SwaggerBasicAuthMiddleware
{
    private const string Username = "shuvoapi";
    private const string Password = "shuvo**10";

    private readonly RequestDelegate _next;

    public SwaggerBasicAuthMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (IsAuthorized(context.Request.Headers.Authorization))
        {
            await _next(context);
            return;
        }

        context.Response.Headers.WWWAuthenticate = "Basic realm=\"Swagger\", charset=\"UTF-8\"";
        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
        await context.Response.WriteAsync("Swagger authentication required.");
    }

    private static bool IsAuthorized(string? authorizationHeader)
    {
        if (string.IsNullOrWhiteSpace(authorizationHeader))
        {
            return false;
        }

        if (!AuthenticationHeaderValue.TryParse(authorizationHeader, out var headerValue))
        {
            return false;
        }

        if (!"Basic".Equals(headerValue.Scheme, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        if (string.IsNullOrWhiteSpace(headerValue.Parameter))
        {
            return false;
        }

        string credentials;
        try
        {
            credentials = Encoding.UTF8.GetString(Convert.FromBase64String(headerValue.Parameter));
        }
        catch (FormatException)
        {
            return false;
        }

        var separatorIndex = credentials.IndexOf(':');
        if (separatorIndex <= 0)
        {
            return false;
        }

        var providedUsername = credentials[..separatorIndex];
        var providedPassword = credentials[(separatorIndex + 1)..];

        return FixedTimeEquals(providedUsername, Username)
            && FixedTimeEquals(providedPassword, Password);
    }

    private static bool FixedTimeEquals(string left, string right)
    {
        var leftBytes = Encoding.UTF8.GetBytes(left);
        var rightBytes = Encoding.UTF8.GetBytes(right);

        return CryptographicOperations.FixedTimeEquals(leftBytes, rightBytes);
    }
}
