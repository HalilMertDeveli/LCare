using System.Security.Claims;
using LedCare.Api.Infrastructure.Http;
using LedCare.Api.Infrastructure.Persistence;
using LedCare.Api.Modules.Identity;
using Microsoft.EntityFrameworkCore;

namespace LedCare.Api.Modules.Organizations;

/// <summary>The caller's effective permissions inside one organization for the current request.</summary>
public sealed record AccessScope(
    Guid UserId,
    Guid OrganizationId,
    IReadOnlySet<OrganizationRole> Roles,
    Guid? CustomerId,
    bool IsPlatformAdmin)
{
    /// <summary>Staff manage every service request of the organization.</summary>
    public bool IsStaff => IsPlatformAdmin || Roles.Contains(OrganizationRole.ServiceManager) || Roles.Contains(OrganizationRole.Dispatcher);
}

/// <summary>
/// Resolves the organization a request acts on and the caller's roles there.
/// Membership is always re-read from the database, so revoked memberships take effect immediately.
/// </summary>
public sealed class AccessScopeResolver(LedCareDbContext db, IHttpContextAccessor httpContextAccessor)
{
    public const string OrganizationHeader = "X-Organization-Id";

    public async Task<AccessScope> ResolveAsync(ClaimsPrincipal user, CancellationToken ct)
    {
        var userId = user.GetUserId();
        var isPlatformAdmin = user.IsInRole(PlatformRoles.PlatformSuperAdmin);
        var requestedOrganizationId = ReadRequestedOrganization();

        var memberships = await db.OrganizationMemberships
            .AsNoTracking()
            .Where(m => m.UserId == userId && (requestedOrganizationId == null || m.OrganizationId == requestedOrganizationId))
            .ToListAsync(ct);

        if (memberships.Count == 1)
        {
            var m = memberships[0];
            return new AccessScope(userId, m.OrganizationId, m.Roles.ToHashSet(), m.CustomerId, isPlatformAdmin);
        }

        if (memberships.Count > 1)
        {
            throw new ApiException(StatusCodes.Status400BadRequest, "Organizasyon seçilmedi",
                $"Birden fazla organizasyon üyeliğiniz var; '{OrganizationHeader}' başlığını gönderin.");
        }

        if (isPlatformAdmin && requestedOrganizationId is { } orgId && await db.Organizations.AnyAsync(o => o.Id == orgId, ct))
        {
            return new AccessScope(userId, orgId, new HashSet<OrganizationRole>(), null, IsPlatformAdmin: true);
        }

        throw new ApiException(StatusCodes.Status403Forbidden, "Yetkisiz erişim", "Bu organizasyon için yetkiniz bulunmuyor.");
    }

    private Guid? ReadRequestedOrganization()
    {
        var raw = httpContextAccessor.HttpContext?.Request.Headers[OrganizationHeader].ToString();
        if (string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        return Guid.TryParse(raw, out var id)
            ? id
            : throw new ApiException(StatusCodes.Status400BadRequest, "Geçersiz organizasyon", $"'{OrganizationHeader}' geçerli bir kimlik değil.");
    }
}

public static class ClaimsPrincipalExtensions
{
    public static Guid GetUserId(this ClaimsPrincipal user) =>
        Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var id)
            ? id
            : throw new ApiException(StatusCodes.Status401Unauthorized, "Oturum gerekli", "Geçerli bir oturum bulunamadı.");
}
