# Realtime synchronization

Web and mobile never sync with each other; both read and write the same API. SignalR only tells clients
*that* something changed so they can re-fetch the authoritative state.

## Flow

1. A client changes data through REST (e.g. `POST /api/service-requests/{id}/status`).
2. The API commits the change (and its history + audit rows) in one transaction.
3. After commit, `RealtimeNotifier` publishes `serviceRequestChanged { serviceRequestId, organizationId, change, status, version, occurredAt }`
   to the groups `org:{org}:staff` and `org:{org}:customer:{customer}`.
4. Clients receiving the event re-fetch list/detail through REST (which re-applies authorization).

Group membership is computed server-side in `NotificationsHub.OnConnectedAsync` from the database — clients
cannot join groups themselves and the hub accepts no client-to-server business calls.

## Reliability rules (both clients)

- Automatic reconnect with backoff; show connection state unobtrusively.
- Re-fetch after every (re)connect and when the app/tab returns to the foreground — events missed while
  disconnected are not replayed.
- A failed publish never fails the HTTP request (the change is already committed); it is logged.

## Transports & auth

- Web: same-origin `/hubs/notifications` through the Next.js proxy, authenticated by the session cookie.
- Mobile: `access_token` query parameter supplied by the SignalR client's token factory; the API reads it only
  on `/hubs/*` paths. Tokens in URLs can appear in proxy logs — keep access tokens short-lived (15 min) and
  avoid logging query strings for `/hubs/*` in production.

## Scaling note

A single API instance needs nothing else. Multiple instances will require a SignalR backplane (Redis or Azure
SignalR) — to be added only when the API is scaled out.
