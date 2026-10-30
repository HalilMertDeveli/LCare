namespace LedCare.Api.Modules.Organizations;

/// <summary>
/// A tenant: the service company operating LEDCare OS. Phase 0 runs a single central service organization;
/// every business record carries an OrganizationId so later SaaS tenants stay isolated.
/// </summary>
public sealed class Organization
{
    public Guid Id { get; set; }
    public required string Name { get; set; }
    public required string Slug { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>Organization-scoped roles. A membership may hold several.</summary>
public enum OrganizationRole
{
    ServiceManager,
    Dispatcher,
    RemoteSupportTechnician,
    FieldTechnician,
    Customer,
}

/// <summary>Grants a user one or more roles inside an organization. Customer members are bound to a Customer record.</summary>
public sealed class OrganizationMembership
{
    public Guid Id { get; set; }
    public Guid OrganizationId { get; set; }
    public Organization Organization { get; set; } = null!;
    public Guid UserId { get; set; }
    public List<OrganizationRole> Roles { get; set; } = [];

    /// <summary>Required when <see cref="Roles"/> contains <see cref="OrganizationRole.Customer"/>.</summary>
    public Guid? CustomerId { get; set; }
    public Customers.Customer? Customer { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
