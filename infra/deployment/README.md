# Deployment (prepared, not connected)

Nothing is deployed in Phase 0. No cloud resource, paid integration or credential has been configured.
Each step below needs explicit approval and credentials from the owner before it is performed.

## Environments

| | LOCAL | PREVIEW | PRODUCTION |
|---|---|---|---|
| Purpose | development + automated tests | feature/integration validation | live customers |
| Web | `next dev` :3000 | Vercel preview deployment per PR | Vercel production |
| API | `dotnet run` :5080 | Railway service (preview environment) | Railway service (production environment) |
| Database | Docker `postgres:17-alpine` | Supabase project **ledcare-preview** | Supabase project **ledcare-prod** (separate project, never shared) |
| Seed data | yes (`Seed:Enabled`) | no | no |
| Auto-migrate | yes | no — migration bundle step | no — reviewed migration bundle + backup |
| OpenAPI UI | yes | `OpenApi__Enabled=true` | off |

Preview must never point at the production database; each environment has its own secrets.

## API on Railway

- Build from `services/api/Dockerfile` (build context = repository root).
- Required variables: `ASPNETCORE_ENVIRONMENT` (`Preview`/`Production`), `ConnectionStrings__Default`
  (Supabase **session pooler / direct** connection string with `SSL Mode=Require`), `Auth__*` overrides if any.
- Health check path: `/health/ready`.
- Before go-live: persist the ASP.NET Data Protection key ring (see docs/architecture/authentication.md),
  configure forwarded headers for Railway's proxy, restrict `AllowedHosts`.
- Migrations: CI produces `dotnet ef migrations bundle`; a manual, approved release job runs it.

## Web on Vercel

- Root directory `apps/web`, framework Next.js.
- `LEDCARE_API_URL` = the Railway API URL of the same environment (server-side only; used by rewrites).
- Prefer custom domains on one site (`app.<domain>`, `api.<domain>`) so cookies stay same-site.

## PostgreSQL on Supabase

- Use Supabase only as managed PostgreSQL (no Supabase Auth/Storage APIs in the app; the API owns auth).
- Separate projects per environment; point-in-time recovery on production; least-privilege DB user for the API.

## Private file storage (Phase 1)

- S3-compatible private bucket (e.g. Supabase Storage or Cloudflare R2), no public objects.
- Uploads/downloads via short-lived pre-signed URLs issued by the API after authorization checks.

## Mobile

- Android: Play Console internal testing track; release signing key kept outside the repo.
- iOS: requires a Mac with Xcode + Apple Developer account; TestFlight.
- Firebase Cloud Messaging is added in Phase 5.
