using System.Text.Json;

namespace LedCare.Api.Infrastructure.Http;

/// <summary>
/// Gives framework-generated problems Turkish titles and camelCase validation keys, matching the API contract
/// (docs/api/contracts.md). Problems that already carry a custom title (ApiException) are left as they are.
/// </summary>
public static class ProblemDetailsLocalization
{
    private static readonly Dictionary<int, string> Titles = new()
    {
        [StatusCodes.Status400BadRequest] = "Geçersiz istek",
        [StatusCodes.Status401Unauthorized] = "Oturum gerekli",
        [StatusCodes.Status403Forbidden] = "Yetkisiz erişim",
        [StatusCodes.Status404NotFound] = "Kayıt bulunamadı",
        [StatusCodes.Status405MethodNotAllowed] = "Desteklenmeyen işlem",
        [StatusCodes.Status409Conflict] = "Kayıt güncel değil",
        [StatusCodes.Status429TooManyRequests] = "Çok fazla istek",
        [StatusCodes.Status500InternalServerError] = "Beklenmeyen hata",
    };

    public static void Apply(ProblemDetailsContext context)
    {
        var problem = context.ProblemDetails;

        if (problem is HttpValidationProblemDetails validation)
        {
            problem.Title = "Girilen bilgiler geçersiz";
            var camelCased = validation.Errors.ToDictionary(e => ToCamelCase(e.Key), e => e.Value);
            validation.Errors.Clear();
            foreach (var (key, messages) in camelCased)
            {
                validation.Errors[key] = messages;
            }

            return;
        }

        // Framework defaults use the English reason phrase as title; replace only those.
        if (problem.Status is { } status && Titles.TryGetValue(status, out var title) &&
            (problem.Title is null || problem.Title == ReasonPhrase(status)))
        {
            problem.Title = title;
        }
    }

    private static string ToCamelCase(string key) =>
        string.Join('.', key.Split('.').Select(part => JsonNamingPolicy.CamelCase.ConvertName(part)));

    private static string ReasonPhrase(int status) => Microsoft.AspNetCore.WebUtilities.ReasonPhrases.GetReasonPhrase(status);
}
