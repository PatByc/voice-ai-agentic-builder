# Vapi API reference

> **Local synthesis.** Start here, then use [`openapi.json`](openapi.json) for exact REST and server-message schemas. The retained guides are snapshots of selected official documentation. Source provenance and hashes are in [`SOURCE.yaml`](SOURCE.yaml).

## Authority and version assumptions

Authority order for this cache:

1. [`openapi.json`](openapi.json), copied from the official `VapiAI/docs` repository, for REST paths and schemas.
2. Selected official guides under [`guides/`](guides/) for workflows and behavior.
3. The official TypeScript server SDK repository for SDK-specific behavior; it is citation-only here because no license was found in that repository.

The REST description declares OpenAPI `3.0.0`, API title `Vapi API`, and `info.version: 1.0`. Treat `1.0` as the specification's declared version, not as proof that every Vapi feature follows semantic versioning. This snapshot is pinned to the documentation commit recorded in `SOURCE.yaml`.

## Base URL and environments

- REST base URL: `https://api.vapi.ai` ([OpenAPI](openapi.json)).
- The OpenAPI document lists one server and does not document a separate sandbox REST host.
- Organization/environment separation should therefore be handled with separate Vapi organizations and keys. The official config-as-code workflow supports named org folders and promotion between orgs ([guide](guides/config-as-code.md)).

## Authentication

Server-side REST requests use a Vapi **private API key**:

```http
Authorization: Bearer <private-api-key>
```

Keys belong to one Vapi organization. Never expose a private key in browser/mobile code, logs, screenshots, repositories, or agent chats. Public keys are for client-side use and can be restricted by allowed origins and assistants; those restrictions do not prevent callers from sending `assistantOverrides` for an allowed assistant ([API keys guide](guides/api-keys.md)).

Project convention: keep the private key in `VAPI_API_KEY` or `VAPI_PRIVATE_API_KEY` as required by the consuming tool. This repository's MCP launcher and config workflow already keep the key outside version control.

## Core REST resources

All exact request and response unions are in `openapi.json`. Representative resource paths:

| Resource | Collection path | Common operations |
|---|---|---|
| Assistants | `/assistant` | create, list; get/update/delete at `/assistant/{id}` |
| Squads | `/squad` | create, list; get/update/delete at `/squad/{id}` |
| Calls | `/call` | create, list; get/update/delete at `/call/{id}`; recording/log artifact endpoints |
| Tools | `/tool` | create, list; get/update/delete at `/tool/{id}` |
| Phone numbers | `/phone-number` | create, list; item operations by ID |
| Files | `/file` | upload and list |
| Structured outputs | `/structured-output` | create and list; item operations by ID |
| Knowledge bases v2 | `/v2/knowledge-base` | create/list and item/file operations |
| Sessions and chats | `/session`, `/chat` | create/list and item operations |
| Campaigns | `/campaign`, `/v2/campaign` | legacy and v2 operations coexist |
| Evals | `/eval/...` | suites, tests, runs, results, and run items |

### Assistants and deployable configuration

An assistant configuration can contain model, voice, transcriber, messages, tools, server/webhook configuration, analysis plans, artifacts, and other behavior. Because schemas contain provider-specific unions, copy exact field names and discriminator values from `openapi.json` rather than inferring them from examples.

This project stores linked assistants as complete `agents/<agent>/vapi.config.json` documents. Follow `docs/VAPI_CONFIG.md` and use pull/validate/diff before applying. The separate official GitOps guide imports and manages assistants, squads, tools, structured outputs, simulations, and evals, but does not import phone numbers or credentials as files ([guide](guides/config-as-code.md)).

### Calls

Create an outbound call with `POST /call`. Depending on the schema branch, identify the assistant or squad and the outbound phone-number/customer details. Dynamic variables are passed at call time through `assistantOverrides.variableValues`; they cannot be assigned directly in the dashboard ([dynamic variables guide](guides/dynamic-variables.md)). See the [assistant quickstart](guides/assistants-quickstart.md) and [outbound calls guide](guides/outbound-calls.md).

Call records and artifacts are asynchronous. Use `GET /call/{id}` and the documented recording/log endpoints rather than assuming the create response contains final transcript, analysis, or recording data.

### Tools

Reusable tools are created at `POST /tool` and attached to assistants by ID. Function tools send tool-call webhook requests to your server; API Request tools call an HTTPS API directly. The [function tools guide](guides/function-tools.md) documents request and response shapes and local testing.

### Files, knowledge bases, and structured outputs

- Upload files using `POST /file`; the OpenAPI defines the exact multipart request.
- Use current knowledge-base schemas from the OpenAPI and the [knowledge-base guide](guides/knowledge-base.md); do not assume older file/query-tool examples match v2 endpoints.
- Structured outputs are independent resources created at `/structured-output`, linked to assistants, and surfaced in call artifacts and end-of-call webhook data ([guide](guides/structured-outputs.md)).

## Pagination and filtering

List endpoints do not share one universal pagination contract:

- Many collections accept `limit` plus `createdAt*` and `updatedAt*` filters.
- Some newer resources, including structured outputs, also expose `page`, `sortBy`, and `sortOrder`.
- Other endpoints use resource-specific filters.

Read each operation's parameters and response schema in `openapi.json`. Do not invent cursor handling or assume all lists return the same wrapper.

## Errors, retries, idempotency, and rate limits

Error schemas and status codes are operation-specific. Examples in the OpenAPI include `400`/`500` for call creation and `409` conflicts for some update/delete/create operations. The specification does not provide a single global error envelope for every operation.

- Retry network failures, `429`, and retryable `5xx` responses only with bounded exponential backoff and jitter.
- Do not blindly retry state-changing calls. In this snapshot, the OpenAPI documents `Idempotency-Key` for `POST /eval/simulation/run`, not as a universal API contract; check the target operation before sending it.
- No general numeric REST rate limit or universal `Retry-After` contract was found in the retained official sources. Treat limits as time-sensitive and preserve server headers/logs when throttled.

These retry recommendations are local integration guidance; where the API does not document behavior, they are not claims about guaranteed Vapi semantics.

## Webhooks and server messages

Vapi sends server messages to configured server URLs. Use the `ServerMessage` and `ServerMessageResponse` component schemas in [`openapi.json`](openapi.json) for the current payload unions, and configure only the message types the integration needs.

Webhook authentication is configured through Vapi custom credentials referenced by `credentialId`; supported patterns documented in the retained guide include bearer/header credentials, OAuth2, and HMAC. Important constraint: Vapi attaches an organization's stored credential only when the server URL comes from stored organization configuration (assistant, phone number, tool, or Server Configuration). A server URL supplied in the API request does not automatically receive that stored credential ([webhook authentication guide](guides/webhook-authentication.md)).

For HMAC, validate the exact configured signature header against the raw request bytes using constant-time comparison. The retained sources do not define a universal replay-window or webhook-redelivery contract, so add application-level event deduplication where side effects must be exactly-once and do not claim a provider guarantee.

## TypeScript server SDK

Official package: `@vapi-ai/server-sdk` ([repository](https://github.com/VapiAI/server-sdk-typescript)). At retrieval time, its `package.json` reports version `3.0.0` and Node `>=18.0.0`. Minimal setup shown by official docs:

```ts
import { VapiClient } from "@vapi-ai/server-sdk";

const vapi = new VapiClient({
  token: process.env.VAPI_API_KEY!,
});
```

The SDK defaults to `https://api.vapi.ai`. Consult its current generated types for method names and request unions. The SDK repository is referenced but not copied into this cache because no reusable license was found during retrieval.

## Project-specific integration decisions

- Use each agent's `agents/<agent>/vapi.config.json` as the complete deployable assistant configuration.
- Use `scripts/vapi-config.ps1` for pull, validation, diff, and apply; obtain user approval before mutations.
- Keep Vapi private keys outside the repository. Never include keys in this cache, agent configuration, commands committed to Git, or examples.
- The official remote MCP endpoint (`https://mcp.vapi.ai/mcp`) is a separate tool surface from the REST API. MCP tools may mutate production resources or create billable calls; review targets and arguments before invoking them.
- Prefer IDs from the project registry/config files over names when mutating resources.

## Unresolved or time-sensitive points

- The OpenAPI declares `info.version: 1.0`, but no dated product API version header is documented in the retained sources.
- No separate REST sandbox base URL was found.
- No global numeric rate-limit contract, universal idempotency policy, or universal webhook replay/redelivery policy was found.
- Legacy and v2 resource families coexist (notably campaigns and knowledge-base-related operations). Verify the exact current path and schema before implementation.
- Provider/model/voice availability and pricing change frequently; use current official model/provider documentation rather than this API snapshot for catalog decisions.

## Canonical sources

- Documentation: https://docs.vapi.ai/
- Machine-readable documentation index: https://docs.vapi.ai/llms.txt
- API reference: https://docs.vapi.ai/api-reference
- Official docs repository: https://github.com/VapiAI/docs
- Official TypeScript server SDK: https://github.com/VapiAI/server-sdk-typescript
