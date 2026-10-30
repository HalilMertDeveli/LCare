# Phase 1 backlog: customer intake

Not started. Every feature ships on backend, web and Flutter and is verified in both directions before it counts as done.

## Decisions needed first

1. Must a request be possible without an account, or does the public form create the account?
2. Which private storage provider holds attachments?
3. Which e-mail provider sends verification and password-reset mail?
4. Keep stateless bearer tokens, or add server-side refresh tokens (see authentication.md)?

## 1. Customer registration

- `POST /api/auth/register`: creates a user, a `Customer` and a `Customer` membership in one transaction. Staff roles can never be requested.
- E-mail verification, forgot/reset password, phone number, KVKK consent record with version and timestamp.
- Abuse protection: per-IP and per-e-mail rate limits, no account-existence leaks.
- Web `/kayit` and Flutter registration screen.

## 2. Public service requests

- Public landing form that leads into registration or login, with the draft kept.
- Richer model: city/address, urgency, service-type preference (remote or on site).
- New `Screens` module: customer's LED screens (location, brand, pixel pitch, size, controller as free text); a request may reference one.
- Staff-created requests on behalf of a customer.
- SEO service pages on the web.

## 3. Photo and video uploads

- `Attachments` module: private bucket, API-issued short-lived pre-signed URLs, every download authorized against the request.
- Type, size and count limits, content-type verification, malware-scanning decision.
- Web drag-and-drop; Flutter camera and gallery with progress and retry.

## 4. Service request management

- Priority, category, internal staff notes (never visible to customers), resolution summary.
- Decide assignment scope with Phase 4: an `AssignedUserId` here would make the technician views real earlier.
- Audit-log view for managers.
- Pagination on the mobile lists and the web customer list (currently one page of 50).

## 5. Admin ticket dashboard

- Search by reference, customer and title; filters by status, priority, date; URL-persisted filters; sort and pagination.
- Operational counts computed from real data; customer list and customer detail pages.
- Mobile admin parity for search and filters.

## 6. Customer request tracking

- Customer-friendly status timeline with attachments; e-mail notification on status change.
- Reopen or respond when `WaitingForCustomer`.

## Hardening carried over from Phase 0

- Run CI on GitHub once a repository exists; add web E2E and API contract-drift checks.
- Persist the Data Protection key ring and configure forwarded headers before any preview deployment.
- Test-data cleanup or a separate E2E database.
- Device tests: expired-token refresh, app resume, hub reconnect, 409. Android release build.
- iOS build and runtime on a Mac. Real launcher icon and splash screen.
