# Local development setup

## Prerequisites

| Tool | Version used in Phase 0 | Notes |
|---|---|---|
| .NET SDK | 10.0.402 (pinned by `global.json`, roll-forward latestFeature) | |
| Node.js / npm | 24.x / 11.x | web app |
| Flutter / Dart | 3.47.x stable / 3.13 | mobile app |
| JDK | 21 (Microsoft OpenJDK) | Android Gradle builds |
| Android SDK | platform 36, build-tools 36.1, emulator, `system-images;android-36;google_apis;x86_64` | |
| Docker Desktop | 29.x with Compose v2 | PostgreSQL + Testcontainers |
| Xcode | — | iOS builds need macOS (not available on the Windows dev machine) |

On the Phase 0 machine Flutter and the Android SDK live in `D:\DevTools\flutter` and `D:\DevTools\android-sdk`
(not on the global PATH). Prepend them per shell:

```powershell
$env:Path = "D:\DevTools\flutter\bin;D:\DevTools\android-sdk\platform-tools;$env:Path"
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"
```

## 1. Database

```bash
docker compose -f infra/docker/docker-compose.yml up -d postgres
```

PostgreSQL listens on `127.0.0.1:5432` (db/user `ledcare`, local-only password from `infra/docker/.env.example`).

## 2. API

```bash
dotnet tool restore
dotnet run --project services/api/src/LedCare.Api --launch-profile http
```

- Listens on `http://localhost:5080`; OpenAPI at `/openapi/v1.json`; health at `/health/ready`.
- In Development it applies migrations and seeds the development accounts listed in
  [`docs/api/contracts.md`](../api/contracts.md#development-accounts). Their password is `Seed:DevPassword` in
  `services/api/src/LedCare.Api/appsettings.Development.json` (local test value only).
- Override anything locally with user secrets: `dotnet user-secrets set "Seed:DevPassword" "…" --project services/api/src/LedCare.Api`.

## 3. Web

```bash
cd apps/web
cp .env.example .env.local   # LEDCARE_API_URL=http://localhost:5080
npm install
npm run dev                  # http://localhost:3000
```

## 4. Mobile

```bash
emulator -avd ledcare_pixel            # or any Android 36 emulator / USB device
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080
```

`10.0.2.2` is the emulator's alias for the host's loopback. For a physical device on the same network, run the
API bound to the LAN IP and pass that URL (cleartext HTTP is allowed only in debug builds).

## 5. Tests

See [testing.md](testing.md).

## Contract regeneration

```bash
npm --prefix packages/contracts run export     # API must be running
npm --prefix packages/contracts run generate   # TypeScript types for apps/web
```
