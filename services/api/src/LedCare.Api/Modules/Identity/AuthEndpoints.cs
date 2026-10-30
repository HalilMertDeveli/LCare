using System.ComponentModel.DataAnnotations;
using LedCare.Api.Infrastructure.Persistence;
using LedCare.Api.Modules.Audit;
using LedCare.Api.Modules.Organizations;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LedCare.Api.Modules.Identity;

public sealed record LoginRequest(
    [property: Required, EmailAddress, MaxLength(256)] string Email,
    [property: Required, MaxLength(256)] string Password);

public sealed record RefreshRequest([property: Required] string RefreshToken);

public sealed record MembershipDto(Guid OrganizationId, string OrganizationName, IReadOnlyList<OrganizationRole> Roles, Guid? CustomerId, string? CustomerName);

public sealed record MeResponse(Guid UserId, string Email, string DisplayName, IReadOnlyList<string> PlatformRoles, IReadOnlyList<MembershipDto> Memberships);

/// <summary>
/// Authentication endpoints built on ASP.NET Core Identity.
/// Browsers: <c>POST /api/auth/login?useCookies=true</c> issues an HttpOnly cookie.
/// Native apps: <c>POST /api/auth/login</c> returns Identity bearer access + refresh tokens.
/// There is intentionally no public registration endpoint in Phase 0.
/// </summary>
public static class AuthEndpoints
{
    public const string LoginRateLimitPolicy = "login";

    public static IEndpointRouteBuilder MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth").WithTags("Auth");

        group.MapPost("/login", async Task<Results<EmptyHttpResult, ProblemHttpResult>> (
            LoginRequest request, bool? useCookies, SignInManager<AppUser> signInManager, AuditLog audit, LedCareDbContext db) =>
        {
            var cookieMode = useCookies == true;
            signInManager.AuthenticationScheme = cookieMode ? IdentityConstants.ApplicationScheme : IdentityConstants.BearerScheme;

            var result = await signInManager.PasswordSignInAsync(request.Email, request.Password, isPersistent: cookieMode, lockoutOnFailure: true);
            if (!result.Succeeded)
            {
                var detail = result.IsLockedOut
                    ? "Çok fazla hatalı deneme. Hesabınız geçici olarak kilitlendi."
                    : "E-posta veya şifre hatalı.";
                return TypedResults.Problem(detail, statusCode: StatusCodes.Status401Unauthorized, title: "Giriş başarısız");
            }

            var user = await signInManager.UserManager.FindByNameAsync(request.Email);
            audit.Record(null, user?.Id, "auth.login", "User", user?.Id.ToString(), new { mode = cookieMode ? "cookie" : "bearer" });
            await db.SaveChangesAsync();

            // The sign-in handler has already written the cookie or the bearer token response body.
            return TypedResults.Empty;
        })
        .Produces<AccessTokenResponse>(StatusCodes.Status200OK, "application/json")
        .AllowAnonymous()
        .RequireRateLimiting(LoginRateLimitPolicy);

        group.MapPost("/refresh", async Task<Results<SignInHttpResult, ChallengeHttpResult>> (
            RefreshRequest request, SignInManager<AppUser> signInManager, IOptionsMonitor<BearerTokenOptions> bearerOptions, TimeProvider clock) =>
        {
            var protector = bearerOptions.Get(IdentityConstants.BearerScheme).RefreshTokenProtector;
            var ticket = protector.Unprotect(request.RefreshToken);

            // Refresh tokens are rejected once expired or once the user's security stamp changed (password change, revoke-sessions).
            if (ticket?.Properties.ExpiresUtc is not { } expiresUtc ||
                clock.GetUtcNow() >= expiresUtc ||
                await signInManager.ValidateSecurityStampAsync(ticket.Principal) is not { } user)
            {
                return TypedResults.Challenge();
            }

            var principal = await signInManager.CreateUserPrincipalAsync(user);
            return TypedResults.SignIn(principal, authenticationScheme: IdentityConstants.BearerScheme);
        })
        .Produces<AccessTokenResponse>(StatusCodes.Status200OK, "application/json")
        .AllowAnonymous()
        .RequireRateLimiting(LoginRateLimitPolicy);

        group.MapPost("/logout", async (HttpContext http) =>
        {
            // Clears the browser session cookie. Native clients discard their tokens locally.
            await http.SignOutAsync(IdentityConstants.ApplicationScheme);
            return TypedResults.NoContent();
        })
        .RequireAuthorization();

        group.MapPost("/revoke-sessions", async (HttpContext http, UserManager<AppUser> users, AuditLog audit, LedCareDbContext db) =>
        {
            var user = await users.GetUserAsync(http.User);
            if (user is null)
            {
                return Results.Unauthorized();
            }

            // Rotating the security stamp invalidates every refresh token and cookie for this user.
            await users.UpdateSecurityStampAsync(user);
            audit.Record(null, user.Id, "auth.revoke_sessions", "User", user.Id.ToString());
            await db.SaveChangesAsync();
            await http.SignOutAsync(IdentityConstants.ApplicationScheme);
            return Results.NoContent();
        })
        .RequireAuthorization();

        app.MapGet("/api/me", async Task<Results<Ok<MeResponse>, UnauthorizedHttpResult>> (
            HttpContext http, UserManager<AppUser> users, LedCareDbContext db, CancellationToken ct) =>
        {
            var user = await users.GetUserAsync(http.User);
            if (user is null)
            {
                return TypedResults.Unauthorized();
            }

            var roles = await users.GetRolesAsync(user);
            var memberships = await db.OrganizationMemberships
                .AsNoTracking()
                .Where(m => m.UserId == user.Id)
                .OrderBy(m => m.Organization.Name)
                .Select(m => new MembershipDto(m.OrganizationId, m.Organization.Name, m.Roles, m.CustomerId,
                    m.Customer != null ? m.Customer.Name : null))
                .ToListAsync(ct);

            return TypedResults.Ok(new MeResponse(user.Id, user.Email ?? "", user.DisplayName, roles.ToList(), memberships));
        })
        .WithTags("Auth")
        .RequireAuthorization();

        return app;
    }
}
