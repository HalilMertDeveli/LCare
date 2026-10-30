using LedCare.Api.Modules.Customers;
using LedCare.Api.Modules.Identity;
using LedCare.Api.Modules.Organizations;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace LedCare.Api.Infrastructure.Persistence;

/// <summary>
/// Creates LOCAL development/test accounts. Runs only when <c>Seed:Enabled=true</c> AND the environment is
/// Development or Testing; it refuses to run anywhere else. The shared password comes from configuration
/// (<c>Seed:DevPassword</c>), never from source code.
/// </summary>
public sealed class DevelopmentDataSeeder(
    LedCareDbContext db,
    UserManager<AppUser> users,
    RoleManager<IdentityRole<Guid>> roles,
    IConfiguration configuration,
    IHostEnvironment environment,
    TimeProvider clock,
    ILogger<DevelopmentDataSeeder> logger)
{
    public static readonly Guid CentralOrganizationId = Guid.Parse("0193a000-0000-7000-8000-000000000001");
    public static readonly Guid OtherOrganizationId = Guid.Parse("0193a000-0000-7000-8000-000000000002");
    public static readonly Guid CustomerAId = Guid.Parse("0193a000-0000-7000-8000-0000000000a1");
    public static readonly Guid CustomerBId = Guid.Parse("0193a000-0000-7000-8000-0000000000b1");
    public static readonly Guid OtherOrgCustomerId = Guid.Parse("0193a000-0000-7000-8000-0000000000c1");

    public const string AdminEmail = "admin@ledcare.local";
    public const string DispatcherEmail = "dispatcher@ledcare.local";
    public const string RemoteTechEmail = "uzaktan.teknisyen@ledcare.local";
    public const string FieldTechEmail = "saha.teknisyen@ledcare.local";
    public const string CustomerAEmail = "musteri.a@ledcare.local";
    public const string CustomerBEmail = "musteri.b@ledcare.local";
    public const string OtherOrgManagerEmail = "yonetici@diger-servis.local";
    public const string OtherOrgCustomerEmail = "musteri@diger-servis.local";

    public async Task SeedAsync(CancellationToken ct = default)
    {
        if (!environment.IsDevelopment() && !environment.IsEnvironment("Testing"))
        {
            throw new InvalidOperationException("Development seed data must never run outside Development/Testing.");
        }

        var password = configuration["Seed:DevPassword"];
        if (string.IsNullOrWhiteSpace(password))
        {
            throw new InvalidOperationException("Seed:DevPassword is not configured.");
        }

        if (!await roles.RoleExistsAsync(PlatformRoles.PlatformSuperAdmin))
        {
            await roles.CreateAsync(new IdentityRole<Guid>(PlatformRoles.PlatformSuperAdmin));
        }

        var now = clock.GetUtcNow();
        await EnsureOrganizationAsync(CentralOrganizationId, "LEDCare Merkez Teknik Servis", "ledcare-merkez", now, ct);
        await EnsureOrganizationAsync(OtherOrganizationId, "Diğer Servis Ltd. (izolasyon testi)", "diger-servis", now, ct);
        await EnsureCustomerAsync(CustomerAId, CentralOrganizationId, "Örnek Reklam A.Ş.", now, ct);
        await EnsureCustomerAsync(CustomerBId, CentralOrganizationId, "Demo Otel Turizm", now, ct);
        await EnsureCustomerAsync(OtherOrgCustomerId, OtherOrganizationId, "Başka Firma Müşterisi", now, ct);
        await db.SaveChangesAsync(ct);

        await EnsureUserAsync(AdminEmail, "Platform Yöneticisi", password, CentralOrganizationId, [OrganizationRole.ServiceManager], null, platformAdmin: true, ct);
        await EnsureUserAsync(DispatcherEmail, "Operasyon Planlayıcı", password, CentralOrganizationId, [OrganizationRole.Dispatcher], null, platformAdmin: false, ct);
        await EnsureUserAsync(RemoteTechEmail, "Uzaktan Destek Teknisyeni", password, CentralOrganizationId, [OrganizationRole.RemoteSupportTechnician], null, platformAdmin: false, ct);
        await EnsureUserAsync(FieldTechEmail, "Saha Teknisyeni", password, CentralOrganizationId, [OrganizationRole.FieldTechnician], null, platformAdmin: false, ct);
        await EnsureUserAsync(CustomerAEmail, "Ayşe Müşteri", password, CentralOrganizationId, [OrganizationRole.Customer], CustomerAId, platformAdmin: false, ct);
        await EnsureUserAsync(CustomerBEmail, "Burak Müşteri", password, CentralOrganizationId, [OrganizationRole.Customer], CustomerBId, platformAdmin: false, ct);
        await EnsureUserAsync(OtherOrgManagerEmail, "Diğer Servis Yöneticisi", password, OtherOrganizationId, [OrganizationRole.ServiceManager], null, platformAdmin: false, ct);
        await EnsureUserAsync(OtherOrgCustomerEmail, "Diğer Servis Müşterisi", password, OtherOrganizationId, [OrganizationRole.Customer], OtherOrgCustomerId, platformAdmin: false, ct);

        logger.LogInformation("Development seed data ensured.");
    }

    private async Task EnsureOrganizationAsync(Guid id, string name, string slug, DateTimeOffset now, CancellationToken ct)
    {
        if (!await db.Organizations.AnyAsync(o => o.Id == id, ct))
        {
            db.Organizations.Add(new Organization { Id = id, Name = name, Slug = slug, CreatedAt = now });
        }
    }

    private async Task EnsureCustomerAsync(Guid id, Guid organizationId, string name, DateTimeOffset now, CancellationToken ct)
    {
        if (!await db.Customers.AnyAsync(c => c.Id == id, ct))
        {
            db.Customers.Add(new Customer { Id = id, OrganizationId = organizationId, Name = name, CreatedAt = now });
        }
    }

    private async Task EnsureUserAsync(string email, string displayName, string password, Guid organizationId,
        OrganizationRole[] orgRoles, Guid? customerId, bool platformAdmin, CancellationToken ct)
    {
        var user = await users.FindByEmailAsync(email);
        if (user is null)
        {
            user = new AppUser
            {
                Id = Guid.CreateVersion7(),
                UserName = email,
                Email = email,
                EmailConfirmed = true,
                DisplayName = displayName,
                CreatedAt = clock.GetUtcNow(),
            };
            var created = await users.CreateAsync(user, password);
            if (!created.Succeeded)
            {
                throw new InvalidOperationException($"Seed user {email} failed: {string.Join(", ", created.Errors.Select(e => e.Code))}");
            }
        }

        if (platformAdmin && !await users.IsInRoleAsync(user, PlatformRoles.PlatformSuperAdmin))
        {
            await users.AddToRoleAsync(user, PlatformRoles.PlatformSuperAdmin);
        }

        if (!await db.OrganizationMemberships.AnyAsync(m => m.UserId == user.Id && m.OrganizationId == organizationId, ct))
        {
            db.OrganizationMemberships.Add(new OrganizationMembership
            {
                Id = Guid.CreateVersion7(),
                OrganizationId = organizationId,
                UserId = user.Id,
                Roles = [.. orgRoles],
                CustomerId = customerId,
                CreatedAt = clock.GetUtcNow(),
            });
            await db.SaveChangesAsync(ct);
        }
    }
}
