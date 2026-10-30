using LedCare.Api.Modules.Audit;
using LedCare.Api.Modules.Customers;
using LedCare.Api.Modules.Identity;
using LedCare.Api.Modules.Organizations;
using LedCare.Api.Modules.ServiceRequests;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace LedCare.Api.Infrastructure.Persistence;

public sealed class LedCareDbContext(DbContextOptions<LedCareDbContext> options)
    : IdentityDbContext<AppUser, IdentityRole<Guid>, Guid>(options)
{
    public const string ServiceRequestNumberSequence = "service_request_number_seq";

    public DbSet<Organization> Organizations => Set<Organization>();
    public DbSet<OrganizationMembership> OrganizationMemberships => Set<OrganizationMembership>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<ServiceRequest> ServiceRequests => Set<ServiceRequest>();
    public DbSet<ServiceRequestStatusHistory> ServiceRequestStatusHistory => Set<ServiceRequestStatusHistory>();
    public DbSet<AuditEvent> AuditEvents => Set<AuditEvent>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<AppUser>(e =>
        {
            e.Property(u => u.DisplayName).HasMaxLength(120).IsRequired();
        });

        builder.Entity<Organization>(e =>
        {
            e.Property(o => o.Name).HasMaxLength(200);
            e.Property(o => o.Slug).HasMaxLength(80);
            e.HasIndex(o => o.Slug).IsUnique();
        });

        builder.Entity<OrganizationMembership>(e =>
        {
            e.HasOne(m => m.Organization).WithMany().HasForeignKey(m => m.OrganizationId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne<AppUser>().WithMany().HasForeignKey(m => m.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(m => m.Customer).WithMany().HasForeignKey(m => m.CustomerId).OnDelete(DeleteBehavior.Restrict);
            e.PrimitiveCollection(m => m.Roles).ElementType().HasConversion<string>().HasMaxLength(40);
            e.HasIndex(m => new { m.UserId, m.OrganizationId }).IsUnique();
            e.HasIndex(m => m.CustomerId);
            e.ToTable(t => t.HasCheckConstraint("CK_Membership_CustomerRoleRequiresCustomer",
                "NOT ('Customer' = ANY(\"Roles\")) OR \"CustomerId\" IS NOT NULL"));
        });

        builder.Entity<Customer>(e =>
        {
            e.Property(c => c.Name).HasMaxLength(200);
            e.Property(c => c.Email).HasMaxLength(256);
            e.Property(c => c.Phone).HasMaxLength(40);
            e.HasOne<Organization>().WithMany().HasForeignKey(c => c.OrganizationId).OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(c => c.OrganizationId);
        });

        builder.HasSequence<long>(ServiceRequestNumberSequence).StartsAt(1);

        builder.Entity<ServiceRequest>(e =>
        {
            e.Property(r => r.Title).HasMaxLength(150);
            e.Property(r => r.Description).HasMaxLength(4000);
            e.Property(r => r.Status).HasConversion<string>().HasMaxLength(40);
            e.Property(r => r.Number).HasDefaultValueSql($"nextval('\"{ServiceRequestNumberSequence}\"')");
            e.Property(r => r.Version).IsRowVersion();
            e.Ignore(r => r.ReferenceCode);
            e.HasOne(r => r.Customer).WithMany().HasForeignKey(r => r.CustomerId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne<Organization>().WithMany().HasForeignKey(r => r.OrganizationId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne<AppUser>().WithMany().HasForeignKey(r => r.CreatedByUserId).OnDelete(DeleteBehavior.Restrict);
            e.HasMany(r => r.StatusHistory).WithOne().HasForeignKey(h => h.ServiceRequestId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(r => r.Number).IsUnique();
            e.HasIndex(r => new { r.OrganizationId, r.Status, r.CreatedAt });
            e.HasIndex(r => new { r.OrganizationId, r.CustomerId, r.CreatedAt });
        });

        builder.Entity<ServiceRequestStatusHistory>(e =>
        {
            e.Property(h => h.FromStatus).HasConversion<string>().HasMaxLength(40);
            e.Property(h => h.ToStatus).HasConversion<string>().HasMaxLength(40);
            e.Property(h => h.Note).HasMaxLength(1000);
            e.HasOne<AppUser>().WithMany().HasForeignKey(h => h.ChangedByUserId).OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(h => new { h.ServiceRequestId, h.ChangedAt });
        });

        builder.Entity<AuditEvent>(e =>
        {
            e.Property(a => a.Action).HasMaxLength(100);
            e.Property(a => a.EntityType).HasMaxLength(100);
            e.Property(a => a.EntityId).HasMaxLength(100);
            e.HasIndex(a => new { a.OrganizationId, a.OccurredAt });
            e.HasIndex(a => new { a.EntityType, a.EntityId });
        });
    }
}
