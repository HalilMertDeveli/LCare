using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using LedCare.Api.Infrastructure.Http;
using LedCare.Api.Infrastructure.Persistence;
using LedCare.Api.Infrastructure.Realtime;
using LedCare.Api.Modules.Audit;
using LedCare.Api.Modules.Identity;
using LedCare.Api.Modules.Organizations;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;

namespace LedCare.Api.Modules.ServiceRequests;

public sealed record CreateServiceRequestRequest(
    [property: Required, StringLength(150, MinimumLength = 5)] string Title,
    [property: Required, StringLength(4000, MinimumLength = 10)] string Description);

public sealed record ChangeStatusRequest(
    [property: Required] ServiceRequestStatus Status,
    [property: Required] uint Version,
    [property: StringLength(1000)] string? Note);

public sealed record ServiceRequestSummaryDto(
    Guid Id,
    string ReferenceCode,
    string Title,
    ServiceRequestStatus Status,
    Guid CustomerId,
    string CustomerName,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    uint Version);

public sealed record StatusHistoryDto(ServiceRequestStatus? FromStatus, ServiceRequestStatus ToStatus, DateTimeOffset ChangedAt, string ChangedBy, string? Note);

public sealed record ServiceRequestDetailDto(
    Guid Id,
    string ReferenceCode,
    string Title,
    string Description,
    ServiceRequestStatus Status,
    Guid CustomerId,
    string CustomerName,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    uint Version,
    IReadOnlyList<ServiceRequestStatus> AllowedTransitions,
    IReadOnlyList<StatusHistoryDto> History);

public sealed record PagedResult<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalCount);

public static class ServiceRequestEndpoints
{
    public static IEndpointRouteBuilder MapServiceRequestEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/service-requests").WithTags("ServiceRequests").RequireAuthorization();

        group.MapGet("/", ListAsync);
        group.MapGet("/{id:guid}", GetAsync);
        group.MapPost("/", CreateAsync);
        group.MapPost("/{id:guid}/status", ChangeStatusAsync);

        return app;
    }

    private static async Task<Ok<PagedResult<ServiceRequestSummaryDto>>> ListAsync(
        ClaimsPrincipal user, AccessScopeResolver resolver, LedCareDbContext db, CancellationToken ct,
        ServiceRequestStatus? status = null, int page = 1, int pageSize = 25)
    {
        var scope = await resolver.ResolveAsync(user, ct);
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = db.ServiceRequests.AsNoTracking().VisibleTo(scope);
        if (status is { } s)
        {
            query = query.Where(r => r.Status == s);
        }

        var total = await query.CountAsync(ct);
        var rows = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => new { r.Id, r.Number, r.Title, r.Status, r.CustomerId, CustomerName = r.Customer.Name, r.CreatedAt, r.UpdatedAt, r.Version })
            .ToListAsync(ct);

        var items = rows
            .Select(r => new ServiceRequestSummaryDto(r.Id, ServiceRequest.FormatReference(r.Number), r.Title, r.Status, r.CustomerId, r.CustomerName, r.CreatedAt, r.UpdatedAt, r.Version))
            .ToList();
        return TypedResults.Ok(new PagedResult<ServiceRequestSummaryDto>(items, page, pageSize, total));
    }

    private static async Task<Results<Ok<ServiceRequestDetailDto>, NotFound>> GetAsync(
        Guid id, ClaimsPrincipal user, AccessScopeResolver resolver, LedCareDbContext db, CancellationToken ct)
    {
        var scope = await resolver.ResolveAsync(user, ct);
        var detail = await LoadDetailAsync(db, scope, id, ct);
        // Requests outside the caller's scope return 404 so identifiers cannot be probed.
        return detail is null ? TypedResults.NotFound() : TypedResults.Ok(detail);
    }

    private static async Task<Created<ServiceRequestDetailDto>> CreateAsync(
        CreateServiceRequestRequest request, ClaimsPrincipal user, AccessScopeResolver resolver,
        LedCareDbContext db, AuditLog audit, RealtimeNotifier notifier, TimeProvider clock, CancellationToken ct)
    {
        var scope = await resolver.ResolveAsync(user, ct);

        // Phase 0: requests are opened by customer accounts for themselves. Staff-on-behalf creation arrives in Phase 1.
        if (!scope.Roles.Contains(OrganizationRole.Customer) || scope.CustomerId is not { } customerId)
        {
            throw new ApiException(StatusCodes.Status403Forbidden, "Yetkisiz işlem", "Servis talebini yalnızca müşteri hesapları oluşturabilir.");
        }

        var now = clock.GetUtcNow();
        var entity = new ServiceRequest
        {
            Id = Guid.CreateVersion7(),
            OrganizationId = scope.OrganizationId,
            CustomerId = customerId,
            Title = request.Title.Trim(),
            Description = request.Description.Trim(),
            Status = ServiceRequestStatus.New,
            CreatedByUserId = scope.UserId,
            CreatedAt = now,
            UpdatedAt = now,
        };
        entity.StatusHistory.Add(new ServiceRequestStatusHistory
        {
            Id = Guid.CreateVersion7(),
            FromStatus = null,
            ToStatus = ServiceRequestStatus.New,
            ChangedByUserId = scope.UserId,
            ChangedAt = now,
        });

        db.ServiceRequests.Add(entity);
        audit.Record(scope.OrganizationId, scope.UserId, "service_request.created", nameof(ServiceRequest), entity.Id.ToString());
        await db.SaveChangesAsync(ct);

        var detail = (await LoadDetailAsync(db, scope, entity.Id, ct))!;
        await notifier.ServiceRequestChangedAsync(scope.OrganizationId, customerId,
            new ServiceRequestChangedEvent(entity.Id, scope.OrganizationId, "created", detail.Status.ToString(), detail.Version, now));

        return TypedResults.Created($"/api/service-requests/{entity.Id}", detail);
    }

    private static async Task<Results<Ok<ServiceRequestDetailDto>, NotFound>> ChangeStatusAsync(
        Guid id, ChangeStatusRequest request, ClaimsPrincipal user, AccessScopeResolver resolver,
        LedCareDbContext db, AuditLog audit, RealtimeNotifier notifier, TimeProvider clock, CancellationToken ct)
    {
        var scope = await resolver.ResolveAsync(user, ct);
        var entity = await db.ServiceRequests.VisibleTo(scope).SingleOrDefaultAsync(r => r.Id == id, ct);
        if (entity is null)
        {
            return TypedResults.NotFound();
        }

        if (entity.Version != request.Version)
        {
            throw new ApiException(StatusCodes.Status409Conflict, "Kayıt güncel değil",
                "Talep siz görüntüledikten sonra değişti. Lütfen yenileyip tekrar deneyin.");
        }

        if (!ServiceRequestPolicy.AllowedTransitions(scope, entity).Contains(request.Status))
        {
            throw new ApiException(StatusCodes.Status403Forbidden, "Geçersiz durum değişikliği",
                $"'{entity.Status}' durumundan '{request.Status}' durumuna geçiş için yetkiniz yok.");
        }

        var now = clock.GetUtcNow();
        var previous = entity.Status;
        entity.Status = request.Status;
        entity.UpdatedAt = now;
        // xmin check: a concurrent writer between our read and this save produces a 409 via DbUpdateConcurrencyException.
        db.Entry(entity).Property(r => r.Version).OriginalValue = request.Version;
        db.ServiceRequestStatusHistory.Add(new ServiceRequestStatusHistory
        {
            Id = Guid.CreateVersion7(),
            ServiceRequestId = entity.Id,
            FromStatus = previous,
            ToStatus = request.Status,
            ChangedByUserId = scope.UserId,
            ChangedAt = now,
            Note = string.IsNullOrWhiteSpace(request.Note) ? null : request.Note.Trim(),
        });
        audit.Record(scope.OrganizationId, scope.UserId, "service_request.status_changed", nameof(ServiceRequest), entity.Id.ToString(),
            new { from = previous.ToString(), to = request.Status.ToString() });
        await db.SaveChangesAsync(ct);

        var detail = (await LoadDetailAsync(db, scope, entity.Id, ct))!;
        await notifier.ServiceRequestChangedAsync(entity.OrganizationId, entity.CustomerId,
            new ServiceRequestChangedEvent(entity.Id, entity.OrganizationId, "statusChanged", detail.Status.ToString(), detail.Version, now));

        return TypedResults.Ok(detail);
    }

    private static async Task<ServiceRequestDetailDto?> LoadDetailAsync(LedCareDbContext db, AccessScope scope, Guid id, CancellationToken ct)
    {
        var entity = await db.ServiceRequests
            .AsNoTracking()
            .VisibleTo(scope)
            .Include(r => r.Customer)
            .SingleOrDefaultAsync(r => r.Id == id, ct);
        if (entity is null)
        {
            return null;
        }

        var history = await db.ServiceRequestStatusHistory
            .AsNoTracking()
            .Where(h => h.ServiceRequestId == id)
            .OrderBy(h => h.ChangedAt)
            .Join(db.Users, h => h.ChangedByUserId, u => u.Id,
                (h, u) => new StatusHistoryDto(h.FromStatus, h.ToStatus, h.ChangedAt, u.DisplayName, h.Note))
            .ToListAsync(ct);

        return new ServiceRequestDetailDto(entity.Id, entity.ReferenceCode, entity.Title, entity.Description, entity.Status,
            entity.CustomerId, entity.Customer.Name, entity.CreatedAt, entity.UpdatedAt, entity.Version,
            ServiceRequestPolicy.AllowedTransitions(scope, entity), history);
    }
}
