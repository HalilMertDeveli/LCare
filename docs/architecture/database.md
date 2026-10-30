# Database

PostgreSQL 17, EF Core 10 (Npgsql). Identifiers are UUIDv7 (`Guid.CreateVersion7()`, time-ordered for index
locality). All timestamps are `timestamptz` written in UTC.

## Phase 0 tables

| Table | Purpose | Notes |
|---|---|---|
| `AspNetUsers` (+ Identity tables) | `AppUser` accounts | `DisplayName`, `CreatedAt`; lockout enabled |
| `AspNetRoles` | Platform-wide roles | only `PlatformSuperAdmin` |
| `Organizations` | Tenants | unique `Slug` |
| `OrganizationMemberships` | User ↔ organization with `Roles text[]` | unique (`UserId`,`OrganizationId`); CHECK: `Customer` role requires `CustomerId` |
| `Customers` | Customer accounts of an organization | index on `OrganizationId` |
| `ServiceRequests` | Support requests | `Number` from sequence `service_request_number_seq` (shown as `LC-000001`); `Status` stored as text; concurrency token = PostgreSQL `xmin`; indexes (`OrganizationId`,`Status`,`CreatedAt`), (`OrganizationId`,`CustomerId`,`CreatedAt`) |
| `ServiceRequestStatusHistory` | Every status transition with actor and note | index (`ServiceRequestId`,`ChangedAt`) |
| `AuditEvents` | Append-only audit trail (`Data jsonb`) | indexes (`OrganizationId`,`OccurredAt`), (`EntityType`,`EntityId`); never stores credentials |

Enums are stored as strings so the data stays readable and reordering enum members is safe.

## Concurrency

Status changes require the client's last-seen `version` (the row's `xmin`). The API compares it before the
update and EF Core re-checks it in the `UPDATE … WHERE xmin = @v`; any mismatch returns **409**.
Verified by `Concurrent_status_changes_with_same_version_allow_only_one_winner`.

## Migrations

- Created with `dotnet ef migrations add <Name> --project services/api/src/LedCare.Api --output-dir Infrastructure/Persistence/Migrations`.
- Local: applied at startup only when `Database:MigrateOnStartup=true` (Development default).
- Preview/production: **never** auto-migrate. Generate an idempotent script or bundle in CI
  (`dotnet ef migrations script --idempotent` / `dotnet ef migrations bundle`), review it, apply it as a release
  step, back up first. Destructive changes require an explicit expand/contract plan.
- CI fails if the model has changes without a migration (`has-pending-model-changes`).

## Prepared for later phases

New tables will reference `OrganizationId` and existing keys: `Screens` (→ Customer), `Attachments`
(private object storage keys, → ServiceRequest), `Conversations`/`Messages`, `Quotes`/`QuoteLines`,
`Payments`, `WorkOrders`, `TechnicianAssignments` (drives technician visibility), `RemoteSessions`
(AnyDesk ID + approval, no passwords), `ServiceReports`. None are created before their phase.
