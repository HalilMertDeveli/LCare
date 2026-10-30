using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using LedCare.Api.Infrastructure.Persistence;
using LedCare.Api.Modules.Identity;
using LedCare.Api.Tests.Infrastructure;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Mvc.Testing;

namespace LedCare.Api.Tests;

[Collection(ApiCollection.Name)]
public sealed class AuthTests(LedCareApiFactory factory)
{
    [Fact]
    public async Task Health_endpoints_report_healthy()
    {
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/health/live")).StatusCode);
        var ready = await client.GetAsync("/health/ready");
        Assert.Equal(HttpStatusCode.OK, ready.StatusCode);
        Assert.Equal("Healthy", await ready.Content.ReadAsStringAsync(TestContext.Current.CancellationToken));
    }

    [Fact]
    public async Task Bearer_login_returns_tokens_and_me_reports_roles()
    {
        using var client = await factory.CreateClientForAsync(DevelopmentDataSeeder.AdminEmail);
        var me = await (await client.GetAsync("/api/me")).ReadAsync<MeResponse>();

        Assert.NotNull(me);
        Assert.Contains(PlatformRoles.PlatformSuperAdmin, me.PlatformRoles);
        var membership = Assert.Single(me.Memberships);
        Assert.Equal(DevelopmentDataSeeder.CentralOrganizationId, membership.OrganizationId);
    }

    [Fact]
    public async Task Wrong_password_is_rejected()
    {
        using var client = factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/login", new { email = DevelopmentDataSeeder.DispatcherEmail, password = "yanlis-sifre-123" });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Anonymous_requests_are_rejected()
    {
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/service-requests")).StatusCode);
    }

    [Fact]
    public async Task There_is_no_public_registration_endpoint()
    {
        using var client = factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/register", new { email = "kotu@example.com", password = "Sifre12345!" });
        Assert.True(response.StatusCode is HttpStatusCode.NotFound or HttpStatusCode.MethodNotAllowed, $"Got {response.StatusCode}");
    }

    [Fact]
    public async Task Refresh_issues_new_tokens_and_garbage_refresh_tokens_are_rejected()
    {
        var tokens = await factory.LoginAsync(DevelopmentDataSeeder.CustomerAEmail);
        using var client = factory.CreateClient();

        var refreshed = await client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = tokens.RefreshToken });
        Assert.Equal(HttpStatusCode.OK, refreshed.StatusCode);
        var newTokens = await refreshed.Content.ReadFromJsonAsync<AccessTokenResponse>();
        Assert.False(string.IsNullOrEmpty(newTokens!.AccessToken));

        var garbage = await client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = "not-a-token" });
        Assert.Equal(HttpStatusCode.Unauthorized, garbage.StatusCode);
    }

    [Fact]
    public async Task Revoke_sessions_invalidates_existing_refresh_tokens()
    {
        var tokens = await factory.LoginAsync(DevelopmentDataSeeder.FieldTechEmail);
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);

        Assert.Equal(HttpStatusCode.NoContent, (await client.PostAsync("/api/auth/revoke-sessions", null)).StatusCode);

        var refresh = await client.PostAsJsonAsync("/api/auth/refresh", new { refreshToken = tokens.RefreshToken });
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.StatusCode);
    }

    [Fact]
    public async Task Cookie_login_sets_http_only_session_cookie_usable_for_api_calls()
    {
        using var client = factory.CreateClient(new WebApplicationFactoryClientOptions { HandleCookies = true });
        var login = await client.PostAsJsonAsync("/api/auth/login?useCookies=true",
            new { email = DevelopmentDataSeeder.CustomerBEmail, password = factory.SeedPassword });

        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var setCookie = Assert.Single(login.Headers.GetValues("Set-Cookie"), c => c.StartsWith("ledcare_session=", StringComparison.Ordinal));
        Assert.Contains("httponly", setCookie, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("samesite=strict", setCookie, StringComparison.OrdinalIgnoreCase);

        var me = await (await client.GetAsync("/api/me")).ReadAsync<MeResponse>();
        Assert.Equal(DevelopmentDataSeeder.CustomerBEmail, me!.Email);

        Assert.Equal(HttpStatusCode.NoContent, (await client.PostAsync("/api/auth/logout", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/api/me")).StatusCode);
    }
}
