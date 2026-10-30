# Platform parity matrix

A feature is complete only when every applicable platform is implemented and verified.
Last verified: 2026-10-30, branch `feature/phase-0-foundation`, Android 36 emulator, Chromium, local API + PostgreSQL 17.

| Feature | Backend | Web | Android | iOS | Integration | Tests |
|---|---|---|---|---|---|---|
| Login, session restore, logout | PASS | PASS | PASS | NOT TESTABLE | n/a | PASS |
| Role-based shells | PASS | PASS (customer, admin; technician unit level) | PASS (customer, admin, technician) | NOT TESTABLE | n/a | PASS |
| Create service request | PASS | PASS | PASS | NOT TESTABLE | PASS (A, B) | PASS |
| List and detail with history | PASS | PASS | PASS | NOT TESTABLE | PASS (A, B) | PASS |
| Staff status change | PASS | PASS | PASS | NOT TESTABLE | PASS (A, B) | PASS |
| Customer cancel | PASS | PASS | PASS | NOT TESTABLE | not run across platforms | PASS |
| Realtime update + re-fetch | PASS | PASS | PASS | NOT TESTABLE | PASS (A, B) | PASS |
| Refresh on resume/reconnect | n/a | Unit level | Widget level | NOT TESTABLE | not run | PASS |
| Customer and organization isolation | PASS | PASS | n/a (API enforced) | n/a | PASS | PASS |

**Overall:** Phase 0 is verified on web and Android. It is not complete for iOS, which needs a Mac to build and run.

Technician shells are honest empty states on both clients: assignments do not exist yet, so technicians see no requests.
