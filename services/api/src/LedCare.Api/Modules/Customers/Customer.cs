namespace LedCare.Api.Modules.Customers;

/// <summary>A customer account (company or individual) served by an organization.</summary>
public sealed class Customer
{
    public Guid Id { get; set; }
    public Guid OrganizationId { get; set; }
    public required string Name { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
