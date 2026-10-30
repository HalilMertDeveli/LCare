using LedCare.Api.Infrastructure.Persistence;
using LedCare.Api.Modules.Identity;
using LedCare.Api.Modules.Organizations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace LedCare.Api.Infrastructure.Realtime;

/// <summary>
/// Server-to-client change notifications. Events carry identifiers only; clients re-fetch authoritative
/// state from the REST API, which applies full authorization. Clients never send business data over the hub.
/// </summary>
[Authorize]
public sealed class NotificationsHub(LedCareDbContext db) : Hub
{
    public const string Path = "/hubs/notifications";
    public const string ServiceRequestChangedEvent = "serviceRequestChanged";

    public static string StaffGroup(Guid organizationId) => $"org:{organizationId}:staff";
    public static string CustomerGroup(Guid organizationId, Guid customerId) => $"org:{organizationId}:customer:{customerId}";

    public override async Task OnConnectedAsync()
    {
        var user = Context.User!;
        var userId = user.GetUserId();
        var isPlatformAdmin = user.IsInRole(PlatformRoles.PlatformSuperAdmin);
        var memberships = await db.OrganizationMemberships.AsNoTracking().Where(m => m.UserId == userId).ToListAsync();

        foreach (var m in memberships)
        {
            var scope = new AccessScope(userId, m.OrganizationId, m.Roles.ToHashSet(), m.CustomerId, isPlatformAdmin);
            if (scope.IsStaff)
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, StaffGroup(m.OrganizationId));
            }
            else if (m.CustomerId is { } customerId)
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, CustomerGroup(m.OrganizationId, customerId));
            }
        }

        await base.OnConnectedAsync();
    }
}

public sealed record ServiceRequestChangedEvent(
    Guid ServiceRequestId,
    Guid OrganizationId,
    string Change,
    string Status,
    uint Version,
    DateTimeOffset OccurredAt);

public sealed class RealtimeNotifier(IHubContext<NotificationsHub> hub, ILogger<RealtimeNotifier> logger)
{
    public async Task ServiceRequestChangedAsync(Guid organizationId, Guid customerId, ServiceRequestChangedEvent payload)
    {
        try
        {
            await hub.Clients
                .Groups(NotificationsHub.StaffGroup(organizationId), NotificationsHub.CustomerGroup(organizationId, customerId))
                .SendAsync(NotificationsHub.ServiceRequestChangedEvent, payload);
        }
        catch (Exception ex)
        {
            // The change is already committed; clients also refresh on reconnect/resume, so a missed push is recoverable.
            logger.LogWarning(ex, "Failed to publish {Event} for {ServiceRequestId}", NotificationsHub.ServiceRequestChangedEvent, payload.ServiceRequestId);
        }
    }
}
