using Microsoft.AspNetCore.Identity;

namespace LedCare.Api.Modules.Identity;

/// <summary>Platform user account. Organization access is granted through <c>OrganizationMembership</c>.</summary>
public sealed class AppUser : IdentityUser<Guid>
{
    public required string DisplayName { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>Platform-wide (non organization-scoped) roles, stored as ASP.NET Core Identity roles.</summary>
public static class PlatformRoles
{
    public const string PlatformSuperAdmin = "PlatformSuperAdmin";
}
