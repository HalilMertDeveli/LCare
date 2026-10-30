# LEDCare OS — mobile (Flutter)

Phase 0 Android + iOS client for the LEDCare OS API (`services/api`). Customer, staff (admin) and
technician shells, chosen from `GET /api/me`. Contract: [`docs/api/contracts.md`](../../docs/api/contracts.md)
and [`packages/contracts/openapi.json`](../../packages/contracts/openapi.json).

## Toolchain

Flutter 3.47.9 / Dart 3.13 (stable). Android SDK with platform 36 and **NDK 28.2.13676358** (required by the
Flutter Gradle plugin). On the reference Windows machine Flutter is not on `PATH`:

```powershell
$env:Path = "D:\DevTools\flutter\bin;D:\DevTools\android-sdk\platform-tools;$env:Path"
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"
```

## Configuration (`--dart-define`)

| Define | Default | Notes |
|---|---|---|
| `API_BASE_URL` | `http://10.0.2.2:5080` | API origin. Android emulator → host loopback. iOS Simulator: `http://localhost:5080`. Release builds must use `https://`. |
| `APP_LOCALE` | `tr` | `tr` (product default) or `en` (strings prepared). |
| `LEDCARE_TEST_PASSWORD` | — | Integration tests only. Dev password = `Seed:DevPassword` in `services/api/src/LedCare.Api/appsettings.Development.json`. Never commit it. |
| `LEDCARE_TARGET_TITLE` | — | Integration test `admin_change_status_test`: title of a `New` request to move to `InReview`. Test is skipped when absent. |

Cleartext HTTP is allowed **only in debug builds** for `10.0.2.2`, `localhost`, `127.0.0.1`
(`android/app/src/debug/res/xml/network_security_config.xml`, wired via the debug manifest). The main manifest sets
`usesCleartextTraffic="false"`, so release/profile builds are HTTPS-only.

## Commands

```powershell
flutter pub get
flutter gen-l10n                     # also runs automatically (flutter: generate: true)
flutter analyze
flutter test                         # unit + widget tests (no network)
flutter build apk --debug
flutter run -d emulator-5554         # API must be running on the host at :5080

# Integration tests against the real API on the emulator
flutter test integration_test/customer_create_request_test.dart -d emulator-5554 `
  --dart-define=LEDCARE_TEST_PASSWORD=<dev password>
#   prints LEDCARE_CREATED_TITLE=<title>; feed it to the admin test:
flutter test integration_test/admin_change_status_test.dart -d emulator-5554 `
  --dart-define=LEDCARE_TEST_PASSWORD=<dev password> --dart-define=LEDCARE_TARGET_TITLE="<title>"
```

> **Pitfall:** `flutter test integration_test/...` writes its test-harness APK to the same
> `build/app/outputs/flutter-apk/app-debug.apk` path (with the dart-defines compiled in). Installing that file by hand
> launches the idle test harness, which sits on the native splash and eventually ANRs. Run `flutter build apk --debug`
> again before `adb install`. `build/` is git-ignored.

Screenshots from the emulator against the real API: [`docs/screenshots/`](docs/screenshots).

## Architecture

```
lib/
  main.dart, app.dart                 ProviderScope (auto-retry off), MaterialApp.router, themes, l10n, AppLifecycleListener
  core/config/                        AppConfig (dart-defines)
  core/network/                       ApiClient (Dio + AuthInterceptor), ApiException (problem+json), providers
  core/auth/                          DTOs (AccessTokenResponse, MeResponse…), TokenStore, AuthRepository, AuthController
  core/realtime/                      SignalR connection, RealtimeController, refresh signal, status indicator
  core/router/                        GoRouter + pure authRedirect() guard
  core/theme/                         brand themes (light/dark), status colours/labels/chip
  core/widgets/                       loading / empty / error(+retry) views, formatting
  features/auth/                      splash (session restore), login
  features/service_requests/data/     DTOs matching openapi.json, repository, Riverpod providers
  features/service_requests/presentation/  list (filters for staff), create form, detail (+status actions)
  features/shell/                     bottom-nav shell, profile, technician empty state, no-access
  l10n/                               app_tr.arb (template), app_en.arb, generated/
```

**UI library.** Flutter 3.47 ships Material as the standalone `material_ui` package (go_router 18 depends on it).
The app imports `package:material_ui/material_ui.dart` everywhere and uses `GlobalMaterialLocalizations.delegates`
from it; do not mix in `package:flutter/material.dart` (separate widget/theme types). In widget tests, helpers such as
`tester.pageBack()` look for the legacy `BackButton`, so tests pop via the router instead.

**Auth / tokens.** Bearer mode: `POST /api/auth/login` (no `useCookies`) → `AccessTokenResponse`. Access token,
refresh token and a client-side expiry estimate (`now + expiresIn`) are stored only in `flutter_secure_storage`
(Android Keystore-backed, `allowBackup=false`; iOS Keychain `first_unlock_this_device`), with an in-memory copy
to avoid a keystore read per request. Nothing is logged.

**Refresh.** `AuthInterceptor` attaches `Authorization: Bearer`. On `401` it calls `POST /api/auth/refresh`
through a separate Dio (no interceptor). The refresh is **single-flight**: concurrent 401s await the same future;
a request that was sent with an already-rotated token is simply retried with the new one. Each request is retried at
most once. A 4xx from refresh clears storage and calls `AuthController.sessionExpired()` → router redirects to
login (with a "session expired" banner). A network error during refresh does *not* log the user out.

**Bootstrap.** `AuthController` starts in `AuthRestoring` (splash). If tokens exist it calls `GET /api/me`
(refreshing transparently if needed): success → `AuthSignedIn(me)`; rejected → signed out; offline/5xx →
`AuthRestoreFailed` with a retry button (tokens kept).

**Shells / routing.** `MeResponse.shell`: staff (`PlatformSuperAdmin` | `ServiceManager` | `Dispatcher`) → `/admin`,
`Customer` → `/customer`, Remote/Field technician only → `/technician` (empty state "Size atanmış iş bulunmuyor"),
no role → `/no-access`. `authRedirect()` is a pure function (unit-tested) used as GoRouter's top-level redirect,
re-evaluated on every auth state change. Each shell is a `StatefulShellRoute` with a bottom `NavigationBar`;
detail/create pages are pushed full-screen on the root navigator.

**Service requests.** Customers: own list (pull-to-refresh), create form (title 5–150, description 10–4000,
trimmed; server `400` field errors shown under the fields), detail with history and "Talebi iptal et" only when
`allowedTransitions` contains `Cancelled`. Staff: organization list with status filter chips; detail renders one
button per `allowedTransitions` entry → bottom sheet with optional note (≤1000) → `POST …/status` with the last-read
`version`. `409` → "Kayıt güncel değil" snackbar and reload. After every mutation the data is re-read from REST.

**Realtime.** `signalr_netcore` 1.4.4, WebSockets transport, JSON protocol, hub `/hubs/notifications`. The
`accessTokenFactory` returns a fresh access token (refreshing first, via the same single-flight path, when it expires
within 60 s) and the client sends it as `?access_token=`. Automatic reconnect never gives up (0/2/5/10 s, then every
30 s), plus a restart loop if the connection closes. The hub runs only while signed in. `serviceRequestChanged`
events, every (re)connect, and `AppLifecycleListener.onResume` bump `refreshSignalProvider` (debounced 300 ms); list
and detail providers `ref.watch` it, so they are invalidated and re-fetch from REST — event payloads are never
rendered. The dot in each app bar shows the connection state (green live / amber connecting / gray off).

**Localization.** gen-l10n with `app_tr.arb` as template; Turkish status labels from contracts.md. `en` is complete
but the app runs in `tr` unless `APP_LOCALE=en`.

## iOS

Project files are generated and configured (bundle id `com.ledcare.ledcareMobile`, display name "LEDCare OS",
`CFBundleLocalizations` tr/en, ATS `NSAllowsLocalNetworking` so the Simulator can reach `http://localhost:5080`
while every internet host still requires HTTPS). **Not built or run** — iOS builds need macOS/Xcode
(`pod install`, signing team). Use `--dart-define=API_BASE_URL=http://localhost:5080` on the Simulator.
