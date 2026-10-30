using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using LedCare.Api.Modules.ServiceRequests;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Testcontainers.PostgreSql;

namespace LedCare.Api.Tests.Infrastructure;

/// <summary>
/// Boots the real API against a throwaway PostgreSQL container (no in-memory database), runs migrations and
/// seeds the development accounts with a random per-run password.
/// </summary>
public sealed class LedCareApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder("postgres:17-alpine").Build();

    public string SeedPassword { get; } = "Test-" + Convert.ToHexString(RandomNumberGenerator.GetBytes(12));

    public async ValueTask InitializeAsync() => await _postgres.StartAsync();

    public override async ValueTask DisposeAsync()
    {
        await base.DisposeAsync();
        await _postgres.DisposeAsync();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:Default", _postgres.GetConnectionString());
        builder.UseSetting("Database:MigrateOnStartup", "true");
        builder.UseSetting("Seed:Enabled", "true");
        builder.UseSetting("Seed:DevPassword", SeedPassword);
        builder.UseSetting("Auth:LoginPermitPerMinute", "10000");
    }

    public async Task<AccessTokenResponse> LoginAsync(string email)
    {
        using var client = CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/login", new { email, password = SeedPassword });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<AccessTokenResponse>())!;
    }

    public async Task<HttpClient> CreateClientForAsync(string email)
    {
        var tokens = await LoginAsync(email);
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);
        return client;
    }
}

[CollectionDefinition(Name)]
public sealed class ApiCollection : ICollectionFixture<LedCareApiFactory>
{
    public const string Name = "api";
}

public static class Json
{
    public static readonly System.Text.Json.JsonSerializerOptions Options = CreateOptions();

    private static System.Text.Json.JsonSerializerOptions CreateOptions()
    {
        var options = new System.Text.Json.JsonSerializerOptions(System.Text.Json.JsonSerializerDefaults.Web);
        options.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
        return options;
    }

    public static Task<T?> ReadAsync<T>(this HttpResponseMessage response) => response.Content.ReadFromJsonAsync<T>(Options);
}

public static class ServiceRequestTestData
{
    public static async Task<ServiceRequestDetailDto> CreateAsync(HttpClient customer, string? title = null)
    {
        var response = await customer.PostAsJsonAsync("/api/service-requests", new
        {
            title = title ?? $"Test talebi {Guid.NewGuid():N}"[..30],
            description = "Ekranın sağ üst köşesinde renk bozulması var.",
        });
        Assert.Equal(System.Net.HttpStatusCode.Created, response.StatusCode);
        return (await response.ReadAsync<ServiceRequestDetailDto>())!;
    }
}
