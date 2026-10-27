// Standard responses, the error middleware and small validation helpers.
//
// Every error in the API has the same shape:
//   {"error": {"code": "SOME_CODE", "message": "human readable text"}}

namespace PamBackend;

public static class Errors
{
    /// <summary>The standard error body: {"error": {"code": ..., "message": ...}}.</summary>
    public static IResult Error(int status, string code, string message) =>
        Results.Json(new { error = new { code, message } }, statusCode: status);

    public static IResult Validation(string message) =>
        Error(400, "VALIDATION_ERROR", message);

    public static IResult Unauthorized(string message = "Missing or invalid token") =>
        Error(401, "UNAUTHORIZED", message);

    public static IResult NotFound(string message = "Resource not found") =>
        Error(404, "NOT_FOUND", message);

    public static IResult EmailTaken() =>
        Error(409, "EMAIL_TAKEN", "An account with this email already exists");

    /// <summary>Returns the value as a trimmed non-empty string, or null when
    /// it is missing/empty (the equivalent of Dart's `stringField`).</summary>
    public static string? Trimmed(string? value)
    {
        var trimmed = value?.Trim();
        return string.IsNullOrEmpty(trimmed) ? null : trimmed;
    }

    /// <summary>
    /// Global error middleware. Because ThrowOnBadRequest is enabled (see
    /// Program.cs), a malformed JSON body or an unparseable parameter throws
    /// BadHttpRequestException - here it becomes a contract-shaped 400 instead
    /// of a bare framework response. Anything else unexpected becomes a 500.
    /// </summary>
    public static async Task HandleExceptions(HttpContext context, RequestDelegate next)
    {
        try
        {
            await next(context);
        }
        catch (BadHttpRequestException ex) when (!context.Response.HasStarted)
        {
            await Write(context, 400, "VALIDATION_ERROR", ex.Message);
        }
        catch (Exception ex) when (!context.Response.HasStarted)
        {
            context.RequestServices.GetRequiredService<ILoggerFactory>()
                .CreateLogger("PamBackend.Errors").LogError(ex, "Unhandled exception");
            await Write(context, 500, "INTERNAL", "Unexpected server error");
        }
    }

    private static Task Write(HttpContext context, int status, string code, string message)
    {
        context.Response.StatusCode = status;
        return context.Response.WriteAsJsonAsync(new { error = new { code, message } });
    }
}
