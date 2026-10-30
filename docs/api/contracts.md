# API contracts (Phase 0)

**Authoritative source:** the ASP.NET Core API. The machine-readable contract is exported to
[`packages/contracts/openapi.json`](../../packages/contracts/openapi.json) from the running API
(`/openapi/v1.json`, Development only). Regenerate it whenever an endpoint or DTO changes:

```bash
npm --prefix packages/contracts run export   # requires the API running on http://localhost:5080
npm --prefix packages/contracts run generate # regenerates the TypeScript types used by apps/web
```

Base URL (local): `http://localhost:5080` — Android emulator: `http://10.0.2.2:5080`.

## Conventions

- JSON, camelCase properties, enums serialized as **strings** (`"InReview"`), timestamps ISO-8601 UTC.
- Errors use RFC 9457 `application/problem+json` with Turkish `title`/`detail`. Validation errors (400) carry an
  `errors` map keyed by property name.
- Status codes: `401` not signed in · `403` signed in but not allowed · `404` not found **or not visible to you**
  (resource-level checks never reveal existence) · `409` stale `version` · `429` login rate limit.
- Multi-organization users send `X-Organization-Id: <guid>`. Phase 0 users have one membership, so it is optional.

## Authentication

| Client | Login | Session |
|---|---|---|
| Web (browser) | `POST /api/auth/login?useCookies=true` `{email,password}` → `200` empty body + `ledcare_session` HttpOnly cookie | Cookie (SameSite=Strict, 8h sliding). Calls go through the Next.js same-origin proxy. `POST /api/auth/logout` clears it. |
| Mobile (Flutter) | `POST /api/auth/login` `{email,password}` → `200 AccessTokenResponse` | `Authorization: Bearer <accessToken>` (15 min). Refresh with `POST /api/auth/refresh {refreshToken}` (14 days, rotated on every refresh). Store tokens in secure storage only. |

`AccessTokenResponse`: `{ tokenType: "Bearer", accessToken, expiresIn (seconds), refreshToken }`.
Refresh returns `401` when the refresh token is expired/revoked → client must sign in again.
`POST /api/auth/revoke-sessions` (authenticated) rotates the user's security stamp: every refresh token and cookie stops working.

## Endpoints

### `GET /api/me`
```json
{ "userId": "…", "email": "…", "displayName": "…", "platformRoles": ["PlatformSuperAdmin"],
  "memberships": [ { "organizationId": "…", "organizationName": "…", "roles": ["ServiceManager"], "customerId": null, "customerName": null } ] }
```
`roles` ⊆ `ServiceManager | Dispatcher | RemoteSupportTechnician | FieldTechnician | Customer`.
Clients pick the UI shell from this: **staff** = `PlatformSuperAdmin` or `ServiceManager` or `Dispatcher`;
**technician** = Remote/Field technician only; **customer** = `Customer`.

### `GET /api/service-requests?status=&page=1&pageSize=25`
`200 { items: ServiceRequestSummaryDto[], page, pageSize, totalCount }`, newest first.
Staff see the whole organization, customers see only their own customer account, technicians see nothing until
assignments exist (Phase 1).

`ServiceRequestSummaryDto`: `{ id, referenceCode ("LC-000001"), title, status, customerId, customerName, createdAt, updatedAt, version }`

### `GET /api/service-requests/{id}`
`200 ServiceRequestDetailDto` = summary fields + `description`, `allowedTransitions: ServiceRequestStatus[]`
(computed **for the caller** — render only these buttons), `history: [{ fromStatus|null, toStatus, changedAt, changedBy, note|null }]`.

### `POST /api/service-requests`
Body `{ title (5–150 chars), description (10–4000 chars) }`. Customer accounts only (staff → 403 in Phase 0).
`201 ServiceRequestDetailDto`.

### `POST /api/service-requests/{id}/status`
Body `{ status, version, note? (≤1000) }`. `version` must equal the version the client last read.
`200 ServiceRequestDetailDto` · `403` transition not allowed for caller · `404` · `409` stale version.

Workflow: `New → InReview | InProgress | Cancelled`; `InReview → InProgress | WaitingForCustomer | Resolved | Cancelled`;
`InProgress → WaitingForCustomer | Resolved | Cancelled`; `WaitingForCustomer → InProgress | Resolved | Cancelled`;
`Resolved → Closed | InProgress`; `Closed`, `Cancelled` are terminal. Customers may only cancel while `New`/`InReview`.

Turkish labels (shared by both clients):
`New` Yeni · `InReview` İnceleniyor · `InProgress` İşlemde · `WaitingForCustomer` Müşteri Yanıtı Bekleniyor ·
`Resolved` Çözüldü · `Closed` Kapatıldı · `Cancelled` İptal Edildi.

### Health
`GET /health/live` (process up) · `GET /health/ready` (database reachable).

## Realtime (SignalR)

Hub: `/hubs/notifications` (JSON protocol). Web authenticates with the session cookie; mobile passes
`?access_token=<accessToken>` (the SignalR client's `accessTokenFactory`).

Server → client event `serviceRequestChanged`:
```json
{ "serviceRequestId": "…", "organizationId": "…", "change": "created" | "statusChanged", "status": "InReview", "version": 788, "occurredAt": "…" }
```
Delivered to the organization's staff and to the owning customer account. **Events are hints, not data**:
clients re-fetch the list/detail through REST. Clients must also re-fetch after (re)connecting and when the app
returns to the foreground, because events missed while disconnected are not replayed.

## Development accounts

Seeded only in Development/Testing (`Seed:Enabled`). Password: `Seed:DevPassword` in
`services/api/src/LedCare.Api/appsettings.Development.json`.

| Email | Role | Notes |
|---|---|---|
| `admin@ledcare.local` | PlatformSuperAdmin + ServiceManager | Central organization |
| `dispatcher@ledcare.local` | Dispatcher | |
| `uzaktan.teknisyen@ledcare.local` | RemoteSupportTechnician | No visible requests in Phase 0 |
| `saha.teknisyen@ledcare.local` | FieldTechnician | No visible requests in Phase 0 |
| `musteri.a@ledcare.local` | Customer — Örnek Reklam A.Ş. | |
| `musteri.b@ledcare.local` | Customer — Demo Otel Turizm | Isolation counterpart of customer A |
| `yonetici@diger-servis.local` | ServiceManager of a second organization | Organization-isolation tests |
| `musteri@diger-servis.local` | Customer of the second organization | |
