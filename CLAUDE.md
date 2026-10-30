# LEDCare OS — guidance for Claude Code

Commercial LED-screen technical-service platform (Türkiye). Monorepo with two independent clients sharing ONE
backend and ONE database:

- `services/api` — ASP.NET Core 10 minimal-API modular monolith (EF Core 10, PostgreSQL, Identity, SignalR). Authoritative for all business data.
- `apps/web` — Next.js + TypeScript + Tailwind + shadcn/ui (public site, customer portal, admin). Talks to the API through same-origin rewrites.
- `apps/mobile` — Flutter (Riverpod, GoRouter, Dio, flutter_secure_storage). Bearer tokens.
- `packages/contracts/openapi.json` — exported API contract; TS types generated from it.
- `tests/backend` — xUnit v3 + WebApplicationFactory + Testcontainers PostgreSQL (real database, no mocks).
- `docs/` — product, architecture, API and development docs. Keep them true to the code.

## Non-negotiable rules

- A user-facing feature is done only when backend + web + Flutter are implemented, use the same real API, enforce
  permissions server-side, have tests, and were verified web→mobile and mobile→web. Track it in
  `docs/development/platform-parity.md` with PASS / FAIL / BLOCKED / NOT TESTABLE.
- Authorization lives in the API: org scoping via `AccessScopeResolver`, record visibility via
  `*Policy.VisibleTo(scope)`, out-of-scope IDs return 404. Never trust client role checks.
- SignalR events are hints (IDs only); clients re-fetch via REST, also on reconnect and app resume.
- Out of scope: LED hardware SDKs (Colorlight/NovaStar), hardware monitoring, firmware, AI repair decisions,
  custom remote desktop. AnyDesk is external; never store AnyDesk passwords.
- No mock databases, hardcoded responses or fake success states in product code. Unit tests may stub HTTP.
- Never commit secrets. Dev-only seed password lives in `appsettings.Development.json`; preview/prod config comes from the host.
- Do not merge to `main`, push, or deploy without explicit approval. Work on feature branches.
- Add Hangfire/worker, new modules or tables only when a real requirement exists.
- UI text is Turkish by default (i18n-ready for English).

## Commands

```bash
docker compose -f infra/docker/docker-compose.yml up -d postgres
dotnet run --project services/api/src/LedCare.Api --launch-profile http        # :5080, migrates + seeds in Development
dotnet test --project tests/backend/LedCare.Api.Tests                           # needs Docker
dotnet ef migrations add <Name> --project services/api/src/LedCare.Api --output-dir Infrastructure/Persistence/Migrations
cd apps/web && npm run dev | npm run lint | npm test | npm run build | npm run test:e2e
cd apps/mobile && flutter analyze && flutter test && flutter build apk --debug
```

On Windows, Git Bash `curl -d` mangles Turkish characters — use Node `fetch` or a UTF-8 file for ad-hoc API calls.
While `dotnet run` holds the API DLL, build tests with `-p:BuildProjectReferences=false`.
