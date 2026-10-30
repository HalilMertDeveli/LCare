# Authorization

All checks run on the server. Clients only *hide* actions the API would refuse (using `allowedTransitions`).

## Roles

| Role | Scope | Phase 0 capability |
|---|---|---|
| `PlatformSuperAdmin` | Platform (Identity role) | Staff rights in any organization it selects with `X-Organization-Id` |
| `ServiceManager` | Organization | All requests of the organization; every workflow transition |
| `Dispatcher` | Organization | Same as ServiceManager for requests (scheduling arrives later) |
| `RemoteSupportTechnician` | Organization | Nothing visible until assignments exist (Phase 4) |
| `FieldTechnician` | Organization | Nothing visible until assignments exist (Phase 4) |
| `Customer` | Organization + one Customer account | Own customer account's requests; create; cancel while `New`/`InReview` |

A membership can hold several roles; a user can belong to several organizations.

## How a request is authorized

1. Authentication (cookie or bearer) → user id + platform roles.
2. `AccessScopeResolver` reads the membership **from the database on every request** (revocations are immediate):
   the organization from `X-Organization-Id` or the single membership; a header naming an organization the user
   is not a member of → 403.
3. Queries go through `ServiceRequestPolicy.VisibleTo(scope)`: always filtered by `OrganizationId`, then by
   `CustomerId` for customers; technicians get an empty set.
4. Detail/update of a record outside the scope returns **404**, so guessing or swapping IDs reveals nothing.
5. Status changes must be in `ServiceRequestPolicy.AllowedTransitions(scope, request)` → otherwise 403.
6. Creating requests is restricted to customer members in Phase 0 (staff-on-behalf creation comes in Phase 1).
7. Audit events are written for logins, session revocation, request creation and status changes.

Covered by tests in `tests/backend/LedCare.Api.Tests` (`Customers_are_isolated_from_each_other`,
`Organizations_are_isolated_from_each_other`, `Technicians_without_assignments_see_no_requests`,
`Customer_may_only_cancel_own_request`, `Workflow_rejects_transitions_that_skip_steps`, realtime group tests).
