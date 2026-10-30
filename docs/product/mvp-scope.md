# MVP scope

The MVP is the smallest product a paying customer in Türkiye can use end to end:

1. Customer self-registration and login (web + mobile).
2. Service requests with LED screen details and photo/video attachments.
3. Admin ticket dashboard: triage, assignment, status workflow, internal notes.
4. Customer ↔ support messaging per request.
5. Quotations (create, send, accept/reject) and iyzico payment.
6. Remote support records (authorized AnyDesk IDs, customer approval, session log).
7. Field service work orders with technician assignment and service reports.
8. Notifications (in-app realtime, e-mail, FCM push).
9. Audit log for administrative actions.

## Phase 0 (delivered in this branch)

Only the architecture proof: login, minimal service request (title + description), status workflow,
cross-platform visibility and updates, realtime hints, organization/customer isolation. See
[platform-parity](../development/platform-parity.md) for the verified status.
