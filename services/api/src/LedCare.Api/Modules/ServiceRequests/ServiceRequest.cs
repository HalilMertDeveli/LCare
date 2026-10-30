namespace LedCare.Api.Modules.ServiceRequests;

public enum ServiceRequestStatus
{
    New,
    InReview,
    InProgress,
    WaitingForCustomer,
    Resolved,
    Closed,
    Cancelled,
}

/// <summary>A customer's technical support request. Phase 0 keeps the model minimal (title + description + status).</summary>
public sealed class ServiceRequest
{
    public Guid Id { get; set; }
    public Guid OrganizationId { get; set; }
    public Guid CustomerId { get; set; }
    public Customers.Customer Customer { get; set; } = null!;

    /// <summary>Human-friendly sequential number, assigned by a database sequence.</summary>
    public long Number { get; set; }
    public required string Title { get; set; }
    public required string Description { get; set; }
    public ServiceRequestStatus Status { get; set; }
    public Guid CreatedByUserId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    /// <summary>Optimistic concurrency token (PostgreSQL xmin). Clients must echo it when changing status.</summary>
    public uint Version { get; set; }

    public List<ServiceRequestStatusHistory> StatusHistory { get; set; } = [];

    public string ReferenceCode => FormatReference(Number);

    public static string FormatReference(long number) => $"LC-{number:D6}";
}

public sealed class ServiceRequestStatusHistory
{
    public Guid Id { get; set; }
    public Guid ServiceRequestId { get; set; }
    public ServiceRequestStatus? FromStatus { get; set; }
    public ServiceRequestStatus ToStatus { get; set; }
    public Guid ChangedByUserId { get; set; }
    public DateTimeOffset ChangedAt { get; set; }
    public string? Note { get; set; }
}
