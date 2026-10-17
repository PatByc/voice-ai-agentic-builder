<!-- Source: https://docs.livekit.io/home/server/webhooks.md -->
<!-- Retrieved: 2026-10-17 -->
<!-- License: citation-only; this file is local paraphrased synthesis -->

# Webhooks

LiveKit sends webhook events as HTTP `POST` requests with `Content-Type: application/webhook+json`. The `Authorization` header contains a signed JWT whose claims include a SHA-256 hash of the payload.

Validate with an official server SDK webhook receiver and provide the exact raw request body, not reserialized parsed JSON. The receiver needs the matching API key and secret.

Delivery is not guaranteed. LiveKit retries transient failures several times and sequences queued events, but eventually abandons undeliverable messages. Every event includes an `id`, `createdAt`, and event name. Make side effects idempotent by atomically deduplicating on event ID and return a successful response for an already-processed event.

The exact `WebhookEvent` schema is retained in `schemas/livekit_webhook.proto`. Events include room, participant, track, ingress, and egress lifecycle notifications.

Canonical source: https://docs.livekit.io/home/server/webhooks
