# LEDCare OS

LED ekran teknik servis yönetim platformu — müşteriler LED ekranlarını nereden almış olurlarsa olsunlar
profesyonel teknik destek talep eder; merkezi servis ekibi talepleri uzaktan (AnyDesk), sahada veya birlikte çözer.

LED-screen technical-service management platform. Two independent clients (Next.js web, Flutter mobile) share one
ASP.NET Core 10 API and one PostgreSQL database.

```
apps/web            Next.js + TypeScript + Tailwind + shadcn/ui
apps/mobile         Flutter (Android, iOS)
services/api        ASP.NET Core 10 modular monolith (EF Core, Identity, SignalR)
services/worker     reserved for background jobs (empty until needed)
packages/contracts  OpenAPI contract + generated TypeScript types
tests/              backend · web · mobile · integration
infra/              docker (local stack) · deployment (Vercel / Railway / Supabase notes)
docs/               product · architecture · api · development
```

## Quick start

```bash
docker compose -f infra/docker/docker-compose.yml up -d postgres
dotnet tool restore
dotnet run --project services/api/src/LedCare.Api --launch-profile http   # http://localhost:5080
cd apps/web && npm install && npm run dev                                  # http://localhost:3000
cd apps/mobile && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080
```

Full instructions: [docs/development/setup.md](docs/development/setup.md) ·
API contract: [docs/api/contracts.md](docs/api/contracts.md) ·
Feature status: [docs/development/platform-parity.md](docs/development/platform-parity.md)

## Status

Phase 0 (foundation) — see the parity matrix for what is verified on each platform. Not deployed anywhere.
