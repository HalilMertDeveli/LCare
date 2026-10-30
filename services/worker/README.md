# services/worker (placeholder)

Reserved for background processing (reminders, notification dispatch, SLA escalation, automation rules).

It is intentionally **empty in Phase 0**: there is no persistent background job yet, so no Hangfire or worker
host is introduced. When the first real requirement appears (planned for Phase 5), add a .NET worker project
here that shares the API's persistence module and uses Hangfire with PostgreSQL storage.
