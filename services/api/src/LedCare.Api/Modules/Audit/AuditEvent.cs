using System.Text.Json;
using LedCare.Api.Infrastructure.Persistence;

namespace LedCare.Api.Modules.Audit;

/// <summary>Append-only record of a security- or business-relevant action. Never store credentials here.</summary>
public sealed class AuditEvent
{
    public Guid Id { get; set; }
    public Guid? OrganizationId { get; set; }
    public Guid? ActorUserId { get; set; }
    public required string Action { get; set; }
    public required string EntityType { get; set; }
    public string? EntityId { get; set; }
    public DateTimeOffset OccurredAt { get; set; }
    public JsonDocument? Data { get; set; }
}

/// <summary>Adds audit events to the current unit of work so they commit atomically with the change they describe.</summary>
public sealed class AuditLog(LedCareDbContext db, TimeProvider clock)
{
    public void Record(Guid? organizationId, Guid? actorUserId, string action, string entityType, string? entityId, object? data = null)
    {
        db.AuditEvents.Add(new AuditEvent
        {
            Id = Guid.CreateVersion7(),
            OrganizationId = organizationId,
            ActorUserId = actorUserId,
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            OccurredAt = clock.GetUtcNow(),
            Data = data is null ? null : JsonSerializer.SerializeToDocument(data),
        });
    }
}
