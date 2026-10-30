# Testing

Results are always reported as PASS / FAIL / BLOCKED / NOT TESTABLE. Unit tests never count as device verification.

| Suite | Location | Command | Uses |
|---|---|---|---|
| Backend | `tests/backend/LedCare.Api.Tests` | `dotnet test --project tests/backend/LedCare.Api.Tests` | Real API in-process + disposable PostgreSQL container (Docker required) |
| Web unit | `apps/web/src/**/*.test.tsx` | `cd apps/web && npm test` | Vitest + Testing Library, stubbed fetch |
| Web E2E | `apps/web/e2e` | `cd apps/web && npm run test:e2e` | Playwright + real API + dev database |
| Mobile unit/widget | `apps/mobile/test` | `cd apps/mobile && flutter test` | Fake Dio adapter |
| Mobile on device | `apps/mobile/integration_test` | `flutter test integration_test/<file> -d emulator-5554 --dart-define=LEDCARE_TEST_PASSWORD=…` | Real app + real API |
| Cross-platform | `tests/integration/cross-platform.mjs` | see below | Emulator + browser + API + PostgreSQL |

Web and mobile tests stay next to their projects because their tooling expects it; `tests/web` and `tests/mobile`
are therefore not used.

## Cross-platform acceptance run

Needs PostgreSQL, the API on :5080, the web on :3000 (`npm run build && npm run start`) and a running emulator:

```bash
FLUTTER_BIN=flutter node tests/integration/cross-platform.mjs
```

- **Scenario A:** Flutter customer creates → web admin moves to `InReview` → the already open Flutter detail screen
  updates with no interaction.
- **Scenario B:** web customer creates → Flutter admin moves to `InReview` → the already open web page updates with
  no reload.
- After each: the row, 2 history entries and 2 audit events are read directly from PostgreSQL; another customer,
  another organization and an unassigned technician get 404; anonymous gets 401.

## Not covered by automation yet

- 409 in a real browser/device (API test + client unit tests only); login 429 on the clients.
- Refresh with a really expired token, app-resume refresh and hub reconnect on a device (fake-adapter/widget tests only).
- Release Android build; all iOS builds and runtime.

Test runs add records to the local dev database and there is no cleanup step. To reset:
`docker compose -f infra/docker/docker-compose.yml down -v`.
