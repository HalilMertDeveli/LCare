# System architecture

```
 ┌───────────────────────┐        ┌──────────────────────────┐
 │ apps/web  (Next.js)    │        │ apps/mobile (Flutter)     │
 │ browser ──► Next origin│        │ Android / iOS             │
 │   /api/*, /hubs/*      │        │ Dio + bearer tokens       │
 │   rewritten (proxy) ───┼──┐  ┌──┼── SignalR (access_token)  │
 └───────────────────────┘  │  │  └──────────────────────────┘
                            ▼  ▼
              ┌───────────────────────────────┐
              │ services/api  ASP.NET Core 10  │  modular monolith
              │  REST /api/*   SignalR /hubs/* │
              │  Identity · EF Core 10         │
              └──────────────┬────────────────┘
                             ▼
                    PostgreSQL 17 (single database)
```

## Decisions

| Decision | Choice | Why |
|---|---|---|
| Backend shape | **Modular monolith**, one deployable (`LedCare.Api`) | One team, one database, strong consistency; modules can be split later if ever needed. |
| Module boundaries | Folders under `Modules/` (`Identity`, `Organizations`, `Customers`, `ServiceRequests`, `Audit`) + `Infrastructure/` (`Persistence`, `Http`, `Realtime`) | Each module owns its entities, DTOs, endpoints and policy. Only Phase 0 modules exist; the others (Screens, Messaging, Quotes, Payments, RemoteSupport, FieldService, Technicians, Reports, Notifications) are added when their phase starts. |
| Persistence | One `LedCareDbContext`, EF Core migrations, PostgreSQL | Simple transactions across modules; audit rows commit atomically with the change. |
| API style | Minimal APIs, ProblemDetails (RFC 9457), built-in .NET 10 validation, OpenAPI | Small surface, typed results feed the OpenAPI contract. |
| Contract | `packages/contracts/openapi.json` exported from the API; TS types generated for web | The API is the single source of truth. |
| Realtime | SignalR events carry IDs only; clients re-fetch via REST | Authorization stays in one place (REST); missed events are harmless. |
| Background jobs | None yet. `services/worker` is a placeholder; Hangfire arrives with the first persistent-job need (Phase 5). | Avoid infrastructure without a requirement. |
| Multi-tenancy | `Organization` tenant + `OrganizationId` on every business row + memberships | SaaS-ready without building billing now. |

## Runtime configuration

All settings come from `appsettings*.json` + environment variables (`ConnectionStrings__Default`, `Auth__*`,
`Cors__AllowedOrigins__0`, `Database__MigrateOnStartup`, `Seed__Enabled`, `OpenApi__Enabled`).
Development defaults live in `appsettings.Development.json`; preview/production values are injected by the
hosting platform and never committed.
