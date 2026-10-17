<!-- Sources: https://docs.livekit.io/deploy/agents/quickstart.md ; https://docs.livekit.io/deploy/admin/quotas-and-limits.md -->
<!-- Retrieved: 2026-10-17 -->
<!-- License: citation-only; this file is local paraphrased synthesis -->

# Deployment, errors, and limits

LiveKit Cloud agents are deployed from a project linked with `lk cloud auth`; `lk agent create` performs initial registration/deployment. Keep credentials in deployment secrets rather than source control. Self-hosted agents run as workers that register with LiveKit and require separate container/orchestration operations.

LiveKit Cloud documents a Server API limit of 1,000 requests per minute per project for services such as RoomService and EgressService. This does not cover room joins, data packets, or inference, which have separate limits. Re-check the live quotas page because plan limits can change.

Twirp failures expose HTTP status plus a Twirp code/message and may include metadata. Treat malformed requests, invalid grants, and most other 4xx responses as terminal. Retry transport failures, `429`, and appropriate 5xx responses with bounded exponential backoff and jitter. Before retrying a create/dispatch/call operation, ensure application-level deduplication; the retained sources do not define a universal idempotency-key contract.

Canonical sources:
- https://docs.livekit.io/deploy/agents/quickstart
- https://docs.livekit.io/deploy/admin/quotas-and-limits
