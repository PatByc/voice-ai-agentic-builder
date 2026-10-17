# PRX02 calendar-tool rebuild evaluation

Date: 2026-10-17

## Change

Replace ambiguous `requestedTime` calendar input and inferred availability with:

- `checkCalendar-Make(requestedDate)` using Cal.com's Slots API;
- `bookCalendar-Make(selectedStart, name, email)` using an exact returned slot;
- fixed `Europe/Warsaw` handling inside Make;
- deterministic structured availability and booking results.

## Assumptions and verification

| Assumption | Verification | Result |
|---|---|---|
| All PRX02 meeting times are interpreted for Poland | Product-owner direction: caller timezone input is unnecessary | Accepted; fixed `Europe/Warsaw` |
| Availability should come from bookable slots, not inferred gaps between bookings | Cal.com Slots API reference states slots account for schedule, bookings, busy times, buffers, minimum notice, and booking limits | Verified |
| Booking must use the exact slot returned by availability | Cal.com booking documentation requires a UTC/ISO start; slot response provides an exact ISO start | Verified |
| Current Slots API query uses `start` and `end` | Live API rejected `startTime`/`endTime` and explicitly required `start`/`end`; the corrected request returned HTTP 200 | Verified against live endpoint |
| Timezone/DST should not be calculated by the voice model | Live Slots responses returned `+02:00` before the 2026 DST transition and `+01:00` afterward | Verified |
| Weekend availability should not be hardcoded | Live data returned slots on some weekends and none on others | Verified; Cal.com remains authoritative |

## Primary references

- Cal.com API v2 booking reference: https://cal.com/docs/api-reference/v2/bookings/create-a-booking
- Cal.com maintained API skill, slots and availability: https://github.com/calcom/cal.diy/blob/main/agents/skills/calcom-api/references/slots-availability.md

## Live provider measurement

Twenty read-only requests were made against the real Cal.com Slots endpoint for event type `3073479`, covering 2026-10-19 through 2026-11-07.

- HTTP/API success: 20/20
- Dates with slots: 8/20
- Dates without slots: 12/20
- Typical available date: 16 half-hour slots
- Weekend behavior: mixed; some weekends had slots and others did not
- DST behavior: `+02:00` through 2026-10-24 and `+01:00` from 2026-10-25
- No booking or other write operation was performed by this suite

This measurement caught two consequential differences from the initial proposal:

1. The live endpoint requires `start` and `end`, not `startTime` and `endTime`.
2. The live response places date keys directly under `data`, not under `data.slots`.

Both mappings were corrected before final verification.

## End-to-end Make measurement

Twelve read-only requests were sent through the production Make webhook using the Vapi tool-call payload shape.

| Date | Slots | First | Last |
|---|---:|---|---|
| 2026-10-19 | 16 | 09:00 +02:00 | 16:30 +02:00 |
| 2026-10-20 | 0 | — | — |
| 2026-10-22 | 16 | 09:00 +02:00 | 16:30 +02:00 |
| 2026-10-24 | 16 | 09:00 +02:00 | 16:30 +02:00 |
| 2026-10-25 | 16 | 09:00 +01:00 | 16:30 +01:00 |
| 2026-10-26 | 0 | — | — |
| 2026-10-29 | 0 | — | — |
| 2026-10-31 | 0 | — | — |
| 2026-11-01 | 0 | — | — |
| 2026-11-03 | 16 | 09:00 +01:00 | 16:30 +01:00 |
| 2026-11-04 | 16 | 09:00 +01:00 | 16:30 +01:00 |
| 2026-11-07 | 0 | — | — |

Results:

- HTTP success: 12/12
- Correct tool-call correlation ID: 12/12
- Structured `availability_result`: 12/12
- Empty availability represented as an empty `slotsByDate`: 6/12
- Exact ISO slot starts preserved: 6/12 dates with availability

## Booking-path verification

A deliberately invalid `selectedStart` was sent through the booking route.

- HTTP response: 200
- Tool result: `status: failed`
- Calendar booking created: no

A successful booking was intentionally not tested because it would create a real external appointment. It still requires controlled UAT with a disposable slot and immediate manual verification in Cal.com.

## Security observations

- The hardcoded Cal.com Authorization header was removed from both HTTP modules.
- The Make API-key connection remains configured on the modules.
- The previously exposed Cal.com API key should still be rotated because removing it from the blueprint does not invalidate the old credential.
- Rollback exports containing credentials are stored only under `C:\Users\aiagent\AppData\Local\Temp\voice-agent-backups`, outside the repository.

## Verdict

Availability path: **verified against live data and safe to use**.

Booking failure path: **verified**.

Successful booking path: **requires one controlled UAT booking before relying on it for production calls**.
