using System.Collections;
using System.Reflection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace OrderProcessAPI.Filters;

public sealed class ApiStatusResultFilter : IResultFilter
{
    private const string SuccessStatus = "success";
    private const string FailedStatus = "failed";

    public void OnResultExecuting(ResultExecutingContext context)
    {
        var controllerNamespace = context.Controller?.GetType().Namespace;
        if (controllerNamespace is null || !controllerNamespace.StartsWith("OrderProcessAPI", StringComparison.Ordinal))
        {
            return;
        }

        if (context.Result is not ObjectResult objectResult)
        {
            return;
        }

        var isFailure = IsFailure(context, objectResult);
        var value = objectResult.Value;
        if (value is null)
        {
            objectResult.Value = new Dictionary<string, object?>
            {
                ["status"] = isFailure ? FailedStatus : SuccessStatus,
            };
            return;
        }

        objectResult.Value = NormalizeResponse(value, isFailure);
    }

    public void OnResultExecuted(ResultExecutedContext context)
    {
    }

    private static bool IsFailure(ResultExecutingContext context, ObjectResult objectResult)
    {
        var statusCode =
            objectResult.StatusCode
            ?? context.HttpContext.Response.StatusCode;

        return statusCode >= StatusCodes.Status400BadRequest;
    }

    private static object NormalizeResponse(object value, bool isFailure)
    {
        var status = isFailure ? FailedStatus : SuccessStatus;

        if (value is string)
        {
            return new Dictionary<string, object?>
            {
                ["status"] = status,
                ["message"] = value,
            };
        }

        if (value is IDictionary dictionary)
        {
            return ToDictionaryWithStatus(dictionary, status);
        }

        if (value is IEnumerable && value is not string)
        {
            return new Dictionary<string, object?>
            {
                ["status"] = status,
                ["data"] = value,
            };
        }

        return ToObjectDictionaryWithStatus(value, status);
    }

    private static Dictionary<string, object?> ToDictionaryWithStatus(
        IDictionary dictionary,
        string status)
    {
        var response = new Dictionary<string, object?>
        {
            ["status"] = status,
        };

        foreach (DictionaryEntry entry in dictionary)
        {
            if (entry.Key is null)
            {
                continue;
            }

            var key = entry.Key.ToString() ?? string.Empty;
            if (key.Length == 0 || IsStatusKey(key))
            {
                continue;
            }

            response[ToCamelCase(key)] = entry.Value;
        }

        return response;
    }

    private static Dictionary<string, object?> ToObjectDictionaryWithStatus(
        object value,
        string status)
    {
        var response = new Dictionary<string, object?>
        {
            ["status"] = status,
        };

        var properties = value
            .GetType()
            .GetProperties(BindingFlags.Instance | BindingFlags.Public)
            .Where(property => property.GetIndexParameters().Length == 0);

        foreach (var property in properties)
        {
            if (IsStatusKey(property.Name))
            {
                continue;
            }

            response[ToCamelCase(property.Name)] = property.GetValue(value);
        }

        return response;
    }

    private static bool IsStatusKey(string key)
    {
        return string.Equals(key, "status", StringComparison.OrdinalIgnoreCase);
    }

    private static string ToCamelCase(string value)
    {
        if (string.IsNullOrEmpty(value) || char.IsLower(value[0]))
        {
            return value;
        }

        return char.ToLowerInvariant(value[0]) + value[1..];
    }
}
