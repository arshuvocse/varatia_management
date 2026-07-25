using System.Text.Json;
using Microsoft.AspNetCore.Diagnostics;

namespace OrderProcessAPI.Middleware;

public static class ApiStatusCodePages
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public static async Task WriteFailureResponseAsync(StatusCodeContext context)
    {
        var httpContext = context.HttpContext;

        if (!httpContext.Request.Path.StartsWithSegments("/api")
            || httpContext.Response.HasStarted
            || httpContext.Response.StatusCode < StatusCodes.Status400BadRequest)
        {
            return;
        }

        httpContext.Response.ContentType = "application/json";

        await JsonSerializer.SerializeAsync(
            httpContext.Response.Body,
            new
            {
                status = "failed",
                message = GetMessage(httpContext.Response.StatusCode),
            },
            JsonOptions,
            httpContext.RequestAborted);
    }

    private static string GetMessage(int statusCode)
    {
        return statusCode switch
        {
            StatusCodes.Status400BadRequest => "Bad request.",
            StatusCodes.Status401Unauthorized => "Unauthorized.",
            StatusCodes.Status403Forbidden => "Forbidden.",
            StatusCodes.Status404NotFound => "Not found.",
            StatusCodes.Status405MethodNotAllowed => "Method not allowed.",
            StatusCodes.Status415UnsupportedMediaType => "Unsupported media type.",
            StatusCodes.Status500InternalServerError => "Internal server error.",
            _ => "Request failed.",
        };
    }
}
