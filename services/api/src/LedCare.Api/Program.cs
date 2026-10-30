using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using LedCare.Api.Infrastructure.Http;
using LedCare.Api.Infrastructure.Persistence;
using LedCare.Api.Infrastructure.Realtime;
using LedCare.Api.Modules.Audit;
using LedCare.Api.Modules.Identity;
using LedCare.Api.Modules.Organizations;
using LedCare.Api.Modules.ServiceRequests;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
var config = builder.Configuration;

if (!builder.Environment.IsDevelopment())
{
    builder.Logging.ClearProviders().AddJsonConsole();
}

// ---------- Persistence ----------
var connectionString = config.GetConnectionString("Default")
    ?? throw new InvalidOperationException("ConnectionStrings:Default is not configured.");
builder.Services.AddDbContext<LedCareDbContext>(o => o.UseNpgsql(connectionString));
builder.Services.AddSingleton(TimeProvider.System);

// ---------- Identity & authentication ----------
// Browser sessions use an HttpOnly cookie; native apps use ASP.NET Core Identity bearer tokens.
// A policy scheme picks the handler per request (see docs/architecture/authentication.md).
const string smartScheme = "LedCare";
builder.Services
    .AddAuthentication(o =>
    {
        o.DefaultScheme = smartScheme;
        o.DefaultChallengeScheme = smartScheme;
    })
    .AddPolicyScheme(smartScheme, smartScheme, o =>
    {
        o.ForwardDefaultSelector = ctx =>
        {
            var authorization = ctx.Request.Headers.Authorization.ToString();
            var hubToken = ctx.Request.Path.StartsWithSegments("/hubs") && ctx.Request.Query.ContainsKey("access_token");
            return authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) || hubToken
                ? IdentityConstants.BearerScheme
                : IdentityConstants.ApplicationScheme;
        };
    })
    .AddBearerToken(IdentityConstants.BearerScheme, o =>
    {
        o.BearerTokenExpiration = TimeSpan.FromMinutes(config.GetValue("Auth:AccessTokenMinutes", 15));
        o.RefreshTokenExpiration = TimeSpan.FromDays(config.GetValue("Auth:RefreshTokenDays", 14));
        o.Events.OnMessageReceived = ctx =>
        {
            // WebSockets cannot send an Authorization header from every client; SignalR passes the token in the query string.
            if (ctx.Request.Path.StartsWithSegments("/hubs") && ctx.Request.Query.TryGetValue("access_token", out var token))
            {
                ctx.Token = token;
            }

            return Task.CompletedTask;
        };
    })
    .AddIdentityCookies();

builder.Services.ConfigureApplicationCookie(o =>
{
    o.Cookie.Name = "ledcare_session";
    o.Cookie.HttpOnly = true;
    o.Cookie.SameSite = SameSiteMode.Strict;
    o.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
    o.ExpireTimeSpan = TimeSpan.FromHours(config.GetValue("Auth:CookieHours", 8));
    o.SlidingExpiration = true;
    // APIs answer with status codes instead of redirecting to a login page.
    o.Events.OnRedirectToLogin = ctx => { ctx.Response.StatusCode = StatusCodes.Status401Unauthorized; return Task.CompletedTask; };
    o.Events.OnRedirectToAccessDenied = ctx => { ctx.Response.StatusCode = StatusCodes.Status403Forbidden; return Task.CompletedTask; };
});
builder.Services.Configure<SecurityStampValidatorOptions>(o => o.ValidationInterval = TimeSpan.FromMinutes(5));

builder.Services
    .AddIdentityCore<AppUser>(o =>
    {
        o.User.RequireUniqueEmail = true;
        o.Password.RequiredLength = 10;
        o.Password.RequireNonAlphanumeric = false;
        o.Lockout.MaxFailedAccessAttempts = 5;
        o.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    })
    .AddRoles<IdentityRole<Guid>>()
    .AddEntityFrameworkStores<LedCareDbContext>()
    .AddSignInManager()
    .AddDefaultTokenProviders();

builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    o.AddPolicy(AuthEndpoints.LoginRateLimitPolicy, http => RateLimitPartition.GetFixedWindowLimiter(
        http.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = config.GetValue("Auth:LoginPermitPerMinute", 10), Window = TimeSpan.FromMinutes(1) }));
});

// ---------- HTTP plumbing ----------
builder.Services.ConfigureHttpJsonOptions(o =>
{
    o.SerializerOptions.Converters.Add(new JsonStringEnumConverter());
    o.SerializerOptions.NumberHandling = JsonNumberHandling.Strict;
});
builder.Services.AddValidation();
builder.Services.AddProblemDetails(o => o.CustomizeProblemDetails = ProblemDetailsLocalization.Apply);
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddOpenApi();
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p
    .WithOrigins(config.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [])
    .AllowAnyHeader()
    .AllowAnyMethod()
    .AllowCredentials()));
builder.Services.AddHealthChecks().AddDbContextCheck<LedCareDbContext>("database", tags: ["ready"]);

// ---------- Realtime ----------
builder.Services
    .AddSignalR()
    .AddJsonProtocol(o => o.PayloadSerializerOptions.Converters.Add(new JsonStringEnumConverter()));

// ---------- Modules ----------
builder.Services.AddScoped<AccessScopeResolver>();
builder.Services.AddScoped<AuditLog>();
builder.Services.AddScoped<RealtimeNotifier>();
builder.Services.AddScoped<DevelopmentDataSeeder>();

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

if (app.Environment.IsDevelopment() || config.GetValue("OpenApi:Enabled", false))
{
    app.MapOpenApi();
}

app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false });
app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = c => c.Tags.Contains("ready") });
app.MapAuthEndpoints();
app.MapServiceRequestEndpoints();
app.MapHub<NotificationsHub>(NotificationsHub.Path);

await InitializeDatabaseAsync(app);

app.Run();

static async Task InitializeDatabaseAsync(WebApplication app)
{
    // Automatic migration is a LOCAL convenience only; preview/production apply reviewed migration bundles.
    if (!app.Configuration.GetValue("Database:MigrateOnStartup", false))
    {
        return;
    }

    await using var scope = app.Services.CreateAsyncScope();
    await scope.ServiceProvider.GetRequiredService<LedCareDbContext>().Database.MigrateAsync();

    if (app.Configuration.GetValue("Seed:Enabled", false))
    {
        await scope.ServiceProvider.GetRequiredService<DevelopmentDataSeeder>().SeedAsync();
    }
}

public partial class Program;
