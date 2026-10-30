using LedCare.Api.Modules.Organizations;

namespace LedCare.Api.Modules.ServiceRequests;

/// <summary>Visibility and status-transition rules for service requests. All checks run on the server.</summary>
public static class ServiceRequestPolicy
{
    private static readonly Dictionary<ServiceRequestStatus, ServiceRequestStatus[]> Workflow = new()
    {
        [ServiceRequestStatus.New] = [ServiceRequestStatus.InReview, ServiceRequestStatus.InProgress, ServiceRequestStatus.Cancelled],
        [ServiceRequestStatus.InReview] = [ServiceRequestStatus.InProgress, ServiceRequestStatus.WaitingForCustomer, ServiceRequestStatus.Resolved, ServiceRequestStatus.Cancelled],
        [ServiceRequestStatus.InProgress] = [ServiceRequestStatus.WaitingForCustomer, ServiceRequestStatus.Resolved, ServiceRequestStatus.Cancelled],
        [ServiceRequestStatus.WaitingForCustomer] = [ServiceRequestStatus.InProgress, ServiceRequestStatus.Resolved, ServiceRequestStatus.Cancelled],
        [ServiceRequestStatus.Resolved] = [ServiceRequestStatus.Closed, ServiceRequestStatus.InProgress],
        [ServiceRequestStatus.Closed] = [],
        [ServiceRequestStatus.Cancelled] = [],
    };

    /// <summary>Customers may only withdraw a request before work has started.</summary>
    private static readonly ServiceRequestStatus[] CustomerCancellable = [ServiceRequestStatus.New, ServiceRequestStatus.InReview];

    /// <summary>
    /// Restricts a query to the requests the caller may see.
    /// Staff see the whole organization; customers see their own customer account's requests;
    /// technicians see nothing until assignments exist (Phase 1+).
    /// </summary>
    public static IQueryable<ServiceRequest> VisibleTo(this IQueryable<ServiceRequest> query, AccessScope scope)
    {
        query = query.Where(r => r.OrganizationId == scope.OrganizationId);
        if (scope.IsStaff)
        {
            return query;
        }

        if (scope.CustomerId is { } customerId)
        {
            return query.Where(r => r.CustomerId == customerId);
        }

        return query.Where(_ => false);
    }

    public static IReadOnlyList<ServiceRequestStatus> AllowedTransitions(AccessScope scope, ServiceRequest request)
    {
        var next = Workflow[request.Status];
        if (scope.IsStaff)
        {
            return next;
        }

        if (scope.CustomerId == request.CustomerId && CustomerCancellable.Contains(request.Status))
        {
            return [ServiceRequestStatus.Cancelled];
        }

        return [];
    }
}
