# LiveKit API reference

> **Local synthesis.** Start here. Use [`schemas/`](schemas/) for exact protobuf/Twirp messages and [`llms.txt`](llms.txt) to find current official documentation. Selected workflow notes under [`guides/`](guides/) are paraphrased, citation-only summaries. Provenance and hashes are in [`SOURCE.yaml`](SOURCE.yaml).

## Authority and version assumptions

Authority order for this cache:

1. Apache-2.0 protobuf definitions retained from the official [`livekit/protocol`](https://github.com/livekit/protocol) repository.
2. Current official pages at `docs.livekit.io`, indexed by [`llms.txt`](llms.txt).
3. Official Python SDK source in [`livekit/python-sdks`](https://github.com/livekit/python-sdks) and Agents source in [`livekit/agents`](https://github.com/livekit/agents).
4. Local paraphrased guides in [`guides/`](guides/).

LiveKit's server API is Twirp/protobuf, not a conventional REST/OpenAPI API. No official OpenAPI artifact or single API semantic version was found, so `openapi_url` and `api_version` are `null` in `SOURCE.yaml`. Use the pinned protocol revision for schema reproducibility.

At retrieval time, official Python source reports:

- `livekit-agents` `1.8.8`, Python `>=3.10,<3.15`.
- `livekit-api` `1.2.2`, Python `>=3.9`.
- `livekit` RTC SDK `1.1.21`, Python `>=3.9`.

## Hosts and environments

There is no universal API base URL. Use the project/server URL supplied by LiveKit Cloud or the self-hosted deployment:

- Realtime client/agent connections commonly use `wss://...` through `LIVEKIT_URL`.
- Server API calls use the corresponding HTTPS host and Twirp paths.
- Separate development and production with distinct LiveKit projects, URLs, keys, secrets, trunks, and deployment secrets.

Official Python SDK constructors read `LIVEKIT_URL`, `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET` when explicit values are absent.

## Authentication

Both realtime clients and server API calls use signed JWT access tokens. Generate tokens only on a trusted backend with the API key and API secret.

Server API request headers:

```http
Authorization: Bearer <signed-access-token>
Content-Type: application/json
```

Tokens carry grants. Match the grant to the operation, such as `roomCreate`, `roomList`, or `roomAdmin`; do not issue broad grants to browser/mobile clients. Never expose `LIVEKIT_API_SECRET` in client code, repositories, logs, screenshots, or prompts. See the [authentication guide](guides/authentication.md).

## Twirp request contract

Server methods are HTTP `POST` requests at:

```text
/twirp/<protobuf-package>.<Service>/<Method>
```

Example:

```text
/twirp/livekit.RoomService/ListRooms
```

Bodies are JSON objects, including `{}` for methods without parameters. LiveKit accepts snake_case or camelCase request keys. Prefer official server SDKs, which generate grants, paths, serialization, and error handling. See the [server API guide](guides/server-api.md).

## Canonical services and resources

Exact messages and fields are retained under [`schemas/`](schemas/):

| Service/domain | Schema | Representative operations |
|---|---|---|
| Rooms and participants | [`livekit_room.proto`](schemas/livekit_room.proto) | create/list/delete room; list/get/remove/update participant; mute track; update subscriptions; send data; update room metadata; move/forward participant; perform RPC |
| Agent dispatch | [`livekit_agent_dispatch.proto`](schemas/livekit_agent_dispatch.proto) | create, list, and delete dispatches |
| SIP telephony | [`livekit_sip.proto`](schemas/livekit_sip.proto) | manage inbound/outbound trunks and dispatch rules; create/transfer SIP participants |
| Egress | [`livekit_egress.proto`](schemas/livekit_egress.proto) | start/list/update/stop recordings and streams |
| Ingress | [`livekit_ingress.proto`](schemas/livekit_ingress.proto) | create/update/list/delete external stream inputs |
| Webhooks | [`livekit_webhook.proto`](schemas/livekit_webhook.proto) | room, participant, track, ingress, and egress lifecycle payloads |
| Shared models | [`livekit_models.proto`](schemas/livekit_models.proto) | rooms, participants, tracks, pagination, grants, and shared enums |

The retained files include their local import closure. Google well-known protobuf types are external toolchain dependencies.

## Voice agents

A LiveKit agent server registers workers that accept jobs and connect to rooms. For Python, the current design centers on `AgentServer`, `AgentSession`, `Agent`, and a job context. A session can use either a chained STT–LLM–TTS pipeline or a realtime speech-to-speech model. Keep agent instructions separate from session/model/room-I/O configuration.

Use `lk agent dev` for development, `lk agent start` for production mode, and `lk agent create` for initial LiveKit Cloud deployment. Model identifiers, provider plugins, and deployment CLI behavior are time-sensitive; consult current docs through `llms.txt`. See [voice agents](guides/voice-agents.md).

## Agent dispatch and per-call context

Explicit dispatch uses `AgentDispatchService`; named dispatch must match the worker's configured agent name. Dispatch metadata is an opaque string commonly encoded as JSON and delivered with the job. Validate it before using it for customer lookup, routing, or tool actions. Automatic dispatch can also be configured through room configuration and SIP routing. See [agent dispatch](guides/agent-dispatch.md).

## Telephony

LiveKit SIP maps telephone calls to room participants. Inbound flows use a phone number/inbound trunk plus a dispatch rule; outbound flows use an outbound trunk and SIP participant creation. Exact request unions are in `livekit_sip.proto`. Provider credentials, caller identity, supported regions, and regulatory requirements must be rechecked for the chosen carrier and country. See [telephony](guides/telephony.md).

## Pagination and filtering

Pagination is service-specific:

- Room list requests are filter-oriented and do not expose a universal page cursor in the retained schema.
- Egress and ingress list messages use `TokenPagination` and return `next_page_token`.
- SIP list messages define their own request filters and response shapes.

Read each protobuf request/response pair. Do not assume one list envelope or pagination mechanism across services.

## Errors, retries, idempotency, and limits

Twirp errors expose an HTTP status, Twirp code/message, and sometimes metadata. In the pinned Python `livekit-api` client, transport failures and HTTP `5xx` responses can enter failover/retry behavior; responses below `500` are surfaced directly.

Local integration policy:

- Retry transport failures, `429`, and appropriate `5xx` failures with bounded exponential backoff and jitter.
- Treat invalid tokens/grants, malformed requests, and most other `4xx` responses as terminal.
- Do not blindly retry state-changing room, dispatch, SIP, ingress, or egress creates. No universal idempotency-key contract was found; deduplicate in the application where duplicate side effects matter.

LiveKit Cloud currently documents a Server API limit of **1,000 requests per minute per project** for APIs such as RoomService and EgressService. Room joins, data packets, and inference use different accounting/limits. Treat limits as time-sensitive. See [deployment and limits](guides/deployment-and-limits.md).

## Webhooks, verification, and replay handling

Webhook requests use `Content-Type: application/webhook+json`. Their `Authorization` header carries a signed JWT containing a SHA-256 hash of the body. Validate with an official SDK `WebhookReceiver` using the exact raw body before parsing or mutating it.

LiveKit explicitly does not guarantee webhook delivery. It retries transient failures several times and sequences queued events before abandoning them. Every event includes an ID, creation time, and event name. Make consumers idempotent by atomically claiming the event ID before side effects; return success for duplicates. See [webhooks](guides/webhooks.md) and the exact [`WebhookEvent`](schemas/livekit_webhook.proto) schema.

## Official Docs MCP and developer tooling

LiveKit provides an official documentation MCP server at:

```text
https://docs.livekit.io/mcp
```

It uses Streamable HTTP and gives coding agents access to current LiveKit documentation, examples, public code search, changelogs, and pricing information. It is a documentation/developer-assistance surface, not the runtime API for creating rooms, dispatching agents, or managing SIP resources; use the official SDKs or CLI for those operations.

The LiveKit CLI can install both LiveKit Agent Skills and the Docs MCP configuration with `lk skills install`. See the official [Docs MCP reference](https://docs.livekit.io/reference/developer-tools/docs-mcp/) and [coding-agent guide](https://docs.livekit.io/intro/coding-agents/).

## Python SDK usage

Install the server SDK separately from the Agents framework as needed:

```bash
pip install livekit-api
pip install livekit-agents
```

Representative server client setup:

```python
from livekit import api

lkapi = api.LiveKitAPI()  # reads LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET
try:
    # Use lkapi.room, lkapi.sip, lkapi.agent_dispatch, etc.
    ...
finally:
    await lkapi.aclose()
```

Use generated request classes from `livekit.api`; do not construct protobuf field names from memory. Pin compatible package versions in production and review the SDK changelog before upgrades.

## Project-specific integration decisions

- This project currently manages provider agents and call behavior as configuration. Before adding LiveKit as a registered provider, define the account/project mapping and a deployable configuration convention analogous to the existing Vapi workflow.
- Store `LIVEKIT_URL`, `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET` outside agent folders and version control.
- Keep development and production projects separate. Require approval before creating trunks, phone numbers, dispatch rules, deployments, rooms, or outbound SIP participants because these can mutate production state or incur cost.
- Use stable internal project codes and external resource IDs; do not resolve mutation targets from display names alone.
- Treat dispatch metadata and webhook payloads as untrusted input before invoking business tools.

## Unresolved and time-sensitive behavior

- No official OpenAPI document or single API version was identified.
- Cloud hosts are project-specific; self-hosted URLs depend on deployment.
- No universal idempotency-key contract was found.
- Telephony availability, pricing, quotas, AI model identifiers, and plugin versions change over time.
- The public documentation pages used for workflow facts did not expose a reusable documentation license, so the retained guides are paraphrased citation-only synthesis. Raw protobufs and included schema license are Apache-2.0.
- LiveKit Agents turn-detection model assets have a separate LiveKit Model License; this cache does not retain those model assets.

## Canonical sources

- Documentation: https://docs.livekit.io/
- Documentation index: https://docs.livekit.io/llms.txt
- Official Docs MCP: https://docs.livekit.io/mcp
- Protocol schemas: https://github.com/livekit/protocol
- Python server/RTC SDKs: https://github.com/livekit/python-sdks
- Agents framework: https://github.com/livekit/agents
