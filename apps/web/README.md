# LEDCare OS — Web (Phase 0)

Next.js (App Router) web client for LEDCare OS: public marketing page, login, customer area,
admin (staff) area and a technician placeholder. All UI text is Turkish.

## Requirements

- Node 24, npm 11
- The LEDCare API running (default `http://localhost:5080`, see `services/api`)

## Commands

```bash
npm install
cp .env.example .env.local      # optional; defaults work for local development

npm run dev         # next dev on http://localhost:3000
npm run build       # production build
npm run start       # serve the production build on port 3000
npm run lint        # eslint
npm run typecheck   # next typegen + tsc --noEmit
npm test            # Vitest unit/component tests (jsdom, fetch mocked)
npm run test:e2e    # Playwright E2E (= npx playwright test), Chromium, against the REAL API
```

First-time E2E setup: `npx playwright install chromium`.

E2E runs `next dev` on port 3000 itself (or reuses one already running). To test a production
server instead: `npm run build && npm run start`, then `E2E_BASE_URL=http://localhost:3000 npx playwright test`.
The tests log in with the seeded dev accounts; the password is read at runtime from
`services/api/src/LedCare.Api/appsettings.Development.json` (`Seed:DevPassword`) — or from
`E2E_DEV_PASSWORD` — and is never printed. Request titles contain a timestamp, so reruns do not collide.

## Environment variables

| Variable | Where | Default | Purpose |
|---|---|---|---|
| `LEDCARE_API_URL` | server (build + runtime of the rewrites) | `http://localhost:5080` | Target of the `/api/*` and `/hubs/*` rewrites |
| `NEXT_PUBLIC_SITE_URL` | build | `http://localhost:3000` | `metadataBase` for canonical/OG URLs |
| `E2E_BASE_URL` | Playwright | — | Test an already running server instead of starting `next dev` |
| `E2E_DEV_PASSWORD` | Playwright | from appsettings | Dev account password override |

Note: Next.js evaluates `rewrites()` at build time for `next build`, so set `LEDCARE_API_URL`
before building for a non-default API.

## Architecture

```
src/
  app/                    routes: / (marketing), /giris, /musteri, /yonetim, /teknisyen
  proxy.ts                UX-only redirect to /giris when the session cookie is missing
  components/             app shell, status badge, connection indicator, request UI
    views/                page-level client components (dashboard, detail, login)
    ui/                   shadcn/ui primitives
  lib/
    api/                  fetch client (ApiError mapping), endpoints, DTO type aliases
    i18n/                 message dictionary (tr) + date formatting
    realtime/             SignalR provider + useRealtimeRefresh hook
    session.ts            /api/me → shell (staff | customer | technician)
    status.ts             status labels + colours (shared meaning with mobile)
    validation.ts         client-side limits mirroring the API
e2e/                      Playwright config + specs
```

### Same-origin API proxy

`next.config.ts` rewrites `/api/:path*` and `/hubs/:path*` to `LEDCARE_API_URL`. The browser only
talks to the Next.js origin, so the API's `ledcare_session` cookie (HttpOnly, SameSite=Strict) is
first-party. No API URL is exposed to the client bundle.

### Auth

- `/giris` posts to `POST /api/auth/login?useCookies=true`, then `GET /api/me` picks the shell:
  staff (`PlatformSuperAdmin`, `ServiceManager`, `Dispatcher`) → `/yonetim`; customer → `/musteri`;
  technician-only → `/teknisyen`. A `?next=` path is honoured only inside the user's own area.
- `src/proxy.ts` (Next 16's renamed middleware) only checks that the cookie exists — it is UX, not
  security. Each area layout (`AppShell`) re-validates with `/api/me` and redirects users to the
  area matching their roles. **The API is the only authority**; the UI merely hides what it
  would refuse.
- Errors are normalised in `lib/api/client.ts` into `ApiError.kind`
  (`unauthorized | forbidden | notFound | conflict | rateLimited | validation | server | network`)
  and rendered with Turkish messages. A 401 on any data call redirects to `/giris?next=…`.
- Status changes send the `version` last read; a 409 shows "Kayıt güncel değil…" and reloads.
- Logout: `POST /api/auth/logout`, then a full navigation to `/giris`.

### Realtime

`RealtimeProvider` opens a SignalR connection to `/hubs/notifications` (same origin, cookie auth,
`withAutomaticReconnect`, plus its own retry loop if the initial start or reconnect gives up).
The header shows a connection indicator (Canlı / Bağlanıyor / Yeniden bağlanıyor / Bağlantı yok).
Events are hints only: on `serviceRequestChanged`, after (re)connecting, and on window `focus` /
`visibilitychange` the visible list/detail is re-fetched from REST.

Transport: WebSockets work through the Next.js rewrite — verified with a raw WebSocket handshake
through `next dev` and `next start`, and in the E2E run (Playwright saw the `/hubs/notifications`
WebSocket and the `serviceRequestChanged` frames). If WebSockets were blocked (e.g. by a reverse
proxy), the SignalR client's negotiation automatically falls back to Server-Sent Events, then
Long Polling; no configuration is needed.

### i18n

`src/lib/i18n/tr.ts` holds every visible string; components import `t` from `@/lib/i18n`.
To add English, create `en.ts` satisfying the `Messages` type and register it in
`src/lib/i18n/index.ts`. Dates are formatted with `Intl` (`tr-TR`, Europe/Istanbul).

### Typed contracts

DTO types come from `packages/contracts/ts/api.d.ts`, generated from the API's OpenAPI document:

```bash
npm --prefix ../../packages/contracts install
npm --prefix ../../packages/contracts run export     # API must be running
npm --prefix ../../packages/contracts run generate
```

`src/lib/api/types.ts` only aliases the generated types (path alias `@contracts/*`); no DTO is
hand-written.

### Cache Components

The scaffold enables `cacheComponents` and `partialPrefetching`. The public pages are static.
Authenticated areas are client-rendered after `/api/me` resolves and export `instant = false`
to opt out of instant-navigation validation (their content depends on the session).
