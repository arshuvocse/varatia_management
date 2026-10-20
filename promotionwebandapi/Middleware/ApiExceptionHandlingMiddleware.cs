using System.Text.Json;

namespace OrderProcessAPI.Middleware;

public sealed class ApiExceptionHandlingMiddleware
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private readonly RequestDelegate _next;
    private readonly ILogger<ApiExceptionHandlingMiddleware> _logger;
    private readonly IHostEnvironment _environment;

    public ApiExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ApiExceptionHandlingMiddleware> logger,
        IHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception exception) when (context.Request.Path.StartsWithSegments("/api"))
        {
            _logger.LogError(exception, "Unhandled API request exception.");

            if (context.Response.HasStarted)
            {
                throw;
            }

            context.Response.Clear();
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/json";

            await JsonSerializer.SerializeAsync(
                context.Response.Body,
                new
                {
                    status = "failed",
                    message = exception.Message,
                    errorType = exception.GetType().FullName,
                    details = exception.ToString(),
                },
                JsonOptions,
                context.RequestAborted);
        }
    }
}
