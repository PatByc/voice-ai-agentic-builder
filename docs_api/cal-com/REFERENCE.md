# Cal.com API v2 — local integration reference

> **Local synthesis.** This file summarizes the official Cal.com sources retrieved on 2026-11-06 for this project's voice-agent scheduling flow. For exact and current schemas, consult [`openapi.json`](openapi.json) and the selected files under [`guides/`](guides/).

## Scope and authority

Scope: discover event types and slots, create/list/reschedule/cancel bookings, and receive booking webhooks.

Authority order:

1. [`openapi.json`](openapi.json), fetched from the official Cal.com v2 OpenAPI URL.
2. Selected official endpoint guides under [`guides/`](guides/).
3. Official API index [`llms.txt`](llms.txt).
4. This synthesized reference.

The OpenAPI document declares OpenAPI `3.0.0`, title `Cal.com API v2`, and document version `1.0.0`. That document version is **not** the value of `cal-api-version`. API date versions are endpoint-specific; never apply one date globally.

Canonical sources:

- API docs: https://cal.com/docs/api-reference/v2
- OpenAPI: https://cal.com/docs/api-reference/v2/openapi.json
- Docs index: https://cal.com/docs/llms.txt
- Docs repository: https://github.com/calcom/cal.diy

## Base URL and transport

Hosted Cal.com API base: `https://api.cal.com/v2`.

All hosted API requests must use HTTPS. A self-hosted API base is deployment-specific and is not established by the retained sources.

Typical headers:

```http
Authorization: Bearer cal_live_...  # keep server-side
Content-Type: application/json
cal-api-version: <date required by this endpoint>
```

## Authentication

The official introduction documents three modes:

- **OAuth** — recommended by Cal.com for integrations and applications. OAuth scopes are endpoint-specific (for example, `BOOKING_READ`, `WEBHOOK_READ`, and `WEBHOOK_WRITE`).
- **API key** — bearer authentication. Test keys use `cal_`; live keys use `cal_live_`. Never expose either in browser code, voice prompts, logs, or repositories.
- **Platform credentials** — documented as deprecated/maintenance-only. Some legacy platform operations use `x-cal-client-id` and `x-cal-secret-key`.

Managed-user access tokens are bearer tokens. The retained introduction says they last 60 minutes and refresh tokens last one year. These values concern managed-user platform tokens; do not assume they describe every OAuth token type.

The documented default rate limit is 120 requests/minute for API-key or unauthenticated use. Contact Cal.com for higher limits. No general retry contract or universal `Retry-After` behavior is documented in the retained sources.

## Recommended voice-agent flow

1. Resolve and persist the intended event type ID.
2. Ask for the caller's timezone and desired date/range.
3. Query slots with the endpoint's exact version header.
4. Read back the selected local date/time and timezone and obtain confirmation.
5. Convert the confirmed start to UTC and create the booking.
6. Persist the returned booking UID; use it for cancellation or rescheduling.
7. Treat a booking as successful only after a successful API response. Do not claim success from the voice conversation alone.
8. Reconcile state through verified webhooks.

Project decision: use numeric `eventTypeId` once configured rather than repeatedly resolving by slug. This reduces ambiguity between user, team, and organization event types.

## Core endpoints

### List event types

```http
GET /v2/event-types
cal-api-version: 2026-06-12
```

Authentication is optional in the current schema, but unauthenticated/other-user listing exposes only public event types and visible booking fields. Listing your own event types can include hidden event types and hidden booking fields.

Useful filters include `username`, `eventSlug`, `usernames`, `orgSlug`, `orgId`, and `sortCreatedAt`.

### Get available slots

```http
GET /v2/slots?eventTypeId=123&start=2026-11-10&end=2026-11-11&timeZone=Europe/Warsaw
cal-api-version: 2024-09-04
```

`start` and `end` are required. Identify an individual event by either `eventTypeId` or by `eventTypeSlug` + `username` (optionally `organizationSlug`). Identify a team event by ID or by `eventTypeSlug` + `teamSlug` (optionally `organizationSlug`). Managed-event parent templates cannot be queried directly; query the assigned child event type.

Optional fields include `timeZone` (defaults to UTC), `duration`, `format=range`, and `bookingUidToReschedule`. Use the latter while finding replacement slots so the original booking does not block itself.

### Create a booking

```http
POST /v2/bookings
cal-api-version: 2026-02-25
Content-Type: application/json
```

Minimal regular-booking shape for this project:

```json
{
  "start": "2026-11-10T09:00:00Z",
  "eventTypeId": 123,
  "attendee": {
    "name": "Jan Kowalski",
    "email": "jan@example.com",
    "timeZone": "Europe/Warsaw",
    "language": "pl"
  }
}
```

The current operation accepts standard, instant, and recurring variants. `start` and `attendee` are required by the standard schema. The guide requires `start` in UTC. Choose the event via `eventTypeId`, or by the documented slug/user/team combination. Optional fields include `bookingFieldsResponses`, `guests`, `location`, `metadata`, and `lengthInMinutes`; SMS-enabled workflows may require `attendee.phoneNumber` in international format.

The operation's current success response is `201`. Authentication is optional in the OpenAPI schema because public booking is supported, but authenticated calls can expose additional owner/host behavior.

### List bookings

```http
GET /v2/bookings?status=upcoming&limit=50
Authorization: Bearer ...
cal-api-version: 2026-05-01
```

Requires bearer authentication; OAuth requires `BOOKING_READ`. `status` accepts one of `upcoming`, `recurring`, `past`, `cancelled`, or `unconfirmed`. Multiple statuses require separate requests and client-side merging.

Pagination is cursor-based: pass `pagination.nextCursor` as `cursor`. Stop when `pagination.hasMore` is false and `pagination.nextCursor` is null. `limit` is 1–100 and defaults to 50.

### Reschedule

```http
POST /v2/bookings/{bookingUid}/reschedule
cal-api-version: 2026-02-25
Content-Type: application/json

{"start":"2026-11-11T10:00:00Z","reschedulingReason":"Caller requested a new time"}
```

Regular/recurring requests require `start`. Seated-booking requests also require `seatUid`. The endpoint returns `201` on success. `accepted` and `pending` bookings are reschedulable; `cancelled`, `rejected`, and `awaiting_host` produce `400` according to the retained guide.

### Cancel

```http
POST /v2/bookings/{bookingUid}/cancel
cal-api-version: 2026-02-25
Content-Type: application/json

{"cancellationReason":"Caller requested cancellation"}
```

For a seated attendee cancellation, send `seatUid`. A host or organization admin can cancel all seats using owner credentials. A recurring non-seated series can be cancelled with its recurring booking UID; recurring seated occurrences must be cancelled individually. Success is `200`.

## Errors, retries, and idempotency

The retained OpenAPI operations often declare only success responses and therefore do not provide a universal error envelope. Preserve HTTP status, response body, request correlation data, endpoint date version, and booking/event identifiers in server-side logs (without secrets or unnecessary caller PII).

- Retry read-only requests after transient network errors, `429`, and `5xx` with bounded exponential backoff and jitter.
- Do **not** automatically retry booking creation, rescheduling, or cancellation unless the result is reconciled first. The retained booking docs do not document an `Idempotency-Key` contract.
- After an ambiguous write timeout, query bookings or await a webhook before attempting another write.
- Treat `400` as a request/state problem, `401` as missing/invalid credentials, and `403` as an authorization/scope problem only when the returned response confirms that interpretation; exact error bodies are endpoint-specific.

## Webhooks

Create a user webhook:

```http
POST /v2/webhooks
Authorization: Bearer ...
Content-Type: application/json
```

OAuth requires `WEBHOOK_WRITE`. Required body fields are `active`, `subscriberUrl`, and `triggers`; optional fields include `secret`, `payloadTemplate`, `customHeaders`, and payload `version`. Current documented payload versions are `2021-10-20` and `2026-07-27`. The subscriber URL on Cal.com SaaS must use HTTPS and cannot target private/internal or metadata addresses.

Example:

```json
{
  "active": true,
  "subscriberUrl": "https://example.com/webhooks/calcom",
  "triggers": ["BOOKING_CREATED", "BOOKING_RESCHEDULED", "BOOKING_CANCELLED"],
  "secret": "store-outside-source-control",
  "version": "2026-07-27"
}
```

### Signature verification

1. Read the **exact raw request body** before JSON parsing.
2. Compute HMAC-SHA256 with the configured webhook secret.
3. Compare the digest in constant time with `x-cal-signature-256`.
4. Reject missing or mismatched signatures.
5. Read `x-cal-webhook-version` and parse according to that payload contract.

Most payloads use `{ "triggerEvent", "createdAt", "payload" }`; `MEETING_STARTED` and `MEETING_ENDED` are documented exceptions with flat payloads.

The retained docs do not describe a signed timestamp/nonce or a built-in replay window. Project recommendation: deduplicate received deliveries in durable storage using stable event data (for example trigger, booking UID, and creation time) and make handlers idempotent. This is local guidance, not a Cal.com guarantee.

## SDK guidance

No standalone official general-purpose TypeScript SDK was established during discovery. The official `calcom/developer-starter-kit` contains a typed server-only API client and is useful as an implementation example. Its client agrees on `https://api.cal.com/v2` and bearer authentication, but at observed revision `5095882439600a0ce4e17955fac1c39f07764d0c` its environment helper defaults globally to `cal-api-version: 2024-08-13`. That conflicts with newer endpoint-specific versions in the current OpenAPI (for example bookings `2026-02-25`, booking listing `2026-05-01`, and event types `2026-06-12`). The starter client supports per-request version overrides; use them rather than its global default for these operations. The OpenAPI file remains the authoritative local schema artifact. Pin generated clients to the cached OpenAPI hash and review diffs before regeneration.

## Known gaps and time-sensitive facts

- Endpoint `cal-api-version` values vary and will change over time; use the value declared on the exact operation in [`openapi.json`](openapi.json).
- The official developer starter kit's global `2024-08-13` version default is stale for several representative operations in the retrieved OpenAPI; override it per request.
- OpenAPI declares no global `servers` entry, so the hosted base URL is documented separately above.
- No universal error model, retry policy, webhook retry schedule, or booking-write idempotency mechanism was established from the retained sources.
- Webhook replay protection is not documented beyond HMAC integrity verification.
- Platform authentication is deprecated/maintenance-only and is outside this project's normal voice-agent booking flow.
- No live API calls were made and no credentials were used while building this cache.
