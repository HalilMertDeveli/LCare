using Microsoft.AspNetCore.Diagnostics;
using Microsoft.EntityFrameworkCore;

namespace LedCare.Api.Infrastructure.Http;

/// <summary>An expected failure that maps directly to an RFC 9457 problem response.</summary>
public sealed class ApiException(int statusCode, string title, string detail) : Exception(detail)
{
    public int StatusCode { get; } = statusCode;
    public string Title { get; } = title;
}

/// <summary>Converts known exceptions into ProblemDetails; everything else becomes a generic 500 without internals.</summary>
public sealed class ApiExceptionHandler(IProblemDetailsService problemDetails, ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var (status, title, detail) = exception switch
        {
            ApiException api => (api.StatusCode, api.Title, api.Message),
            DbUpdateConcurrencyException => (StatusCodes.Status409Conflict, "Kayıt güncel değil",
                "Kayıt başka biri tarafından değiştirildi. Lütfen yenileyip tekrar deneyin."),
            BadHttpRequestException bad => (bad.StatusCode, "Geçersiz istek", "İstek gövdesi okunamadı."),
            _ => (StatusCodes.Status500InternalServerError, "Beklenmeyen hata", "Sunucuda beklenmeyen bir hata oluştu."),
        };

        if (status >= 500)
        {
            logger.LogError(exception, "Unhandled exception for {Method} {Path}", httpContext.Request.Method, httpContext.Request.Path);
        }

        httpContext.Response.StatusCode = status;
        return await problemDetails.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            Exception = exception,
            ProblemDetails = { Status = status, Title = title, Detail = detail },
        });
    }
}
