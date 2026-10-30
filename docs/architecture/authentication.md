# Authentication

Built entirely on **ASP.NET Core Identity** and its maintained cookie and bearer-token handlers — no custom
cryptography. Passwords are hashed by Identity (PBKDF2); lockout after 5 failures for 15 minutes; login and
refresh are rate-limited per IP (`Auth:LoginPermitPerMinute`). There is **no public registration** in Phase 0
and the `PlatformSuperAdmin` role can never be self-assigned.

A policy scheme (`LedCare`) chooses the handler per request: `Authorization: Bearer …` (or `access_token`
on `/hubs/*`) → Identity bearer handler; otherwise → Identity application cookie.

## Web (browser)

| Aspect | Implementation |
|---|---|
| Issuance | `POST /api/auth/login?useCookies=true` → `ledcare_session` cookie |
| Cookie flags | `HttpOnly`, `SameSite=Strict`, `Secure` when served over HTTPS |
| Same-origin | The browser only talks to the Next.js origin; `/api/*` and `/hubs/*` are rewritten to the API, so the cookie is first-party and no CORS credentials are needed |
| Lifetime | 8 h, sliding |
| CSRF | SameSite=Strict + JSON-only endpoints (HTML forms cannot send `application/json` cross-site) |
| Logout | `POST /api/auth/logout` deletes the cookie |
| Revocation | Security-stamp validation every 5 min invalidates cookies after `revoke-sessions` or a password change |

## Mobile (Flutter)

| Aspect | Implementation |
|---|---|
| Issuance | `POST /api/auth/login` → `{ accessToken, refreshToken, expiresIn }` (Identity bearer tokens, protected by ASP.NET Data Protection) |
| Access token | 15 min (`Auth:AccessTokenMinutes`) |
| Refresh token | 14 days (`Auth:RefreshTokenDays`); `POST /api/auth/refresh` returns a new pair; refused once expired or after the user's security stamp changes |
| Storage | `flutter_secure_storage` only (Android Keystore / iOS Keychain); never logs tokens |
| Renewal | Dio interceptor refreshes once on 401 (single-flight) and retries; failure → local sign-out |
| Logout | Client deletes both tokens |
| Revocation | `POST /api/auth/revoke-sessions` rotates the security stamp → every refresh token stops working; outstanding access tokens expire within 15 min |

### Known limits of stateless bearer tokens (decide before production)

Identity bearer tokens are not stored on the server, which means (observed on the running API):

- **No one-time refresh tokens.** A refresh returns a new pair, but the previous refresh token remains valid until
  it expires or the security stamp changes. A stolen refresh token is not detected by reuse.
- **No per-device logout.** Mobile logout only deletes local tokens; only `revoke-sessions` ends sessions server-side,
  and it ends all of them.

Before production, either accept this or add a server-side refresh-token table (rotation, reuse detection,
per-device revocation).

## Production requirements (not needed locally)

- **Data Protection key ring must be persisted and shared** across API instances (e.g. PostgreSQL or private
  storage + key encryption). Otherwise every deploy invalidates all cookies and tokens.
- HTTPS everywhere; HSTS at the edge; `Cookie.SecurePolicy` becomes effectively `Always`.
- Web and API must be same-site (e.g. `app.<domain>` + `api.<domain>`) or the web keeps proxying through Next.js.
- E-mail confirmation and password reset arrive with customer registration (Phase 1).
