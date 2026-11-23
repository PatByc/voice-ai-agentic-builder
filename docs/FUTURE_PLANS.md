# Future Plans

## Vapi draft and published-version synchronization

### Problem

`vapi-config.ps1 -Action Apply` and `-Action Diff` verify the draft associated with the API key, but the Vapi Dashboard can display or publish a different per-user draft. This can produce a successful local/API comparison while the Dashboard publish preview still contains an older system prompt or configuration.

Observed with PR004: the API draft matched the new two-stage closing configuration, while the Dashboard publish preview still showed the previous single-turn `Step 4`.

### Current workaround

- Copy the required section directly from `agents/pr004 - Factolex/prompt.md` into the Vapi Dashboard.
- Review the complete publish preview before publishing.
- Test the published version with a real call.

### Planned fix

- Add explicit commands to inspect and compare all three states: local configuration, API-key draft, and current published version.
- Add a publish-aware verification step that checks the exact system prompt, first message, end-call settings, hooks, voice, model, and transcriber used by live calls.
- Calculate and display a stable prompt/configuration hash in CLI output and the publish checklist.
- Refuse to report deployment success when only the API draft matches but the published version differs.
- Investigate whether Vapi exposes a supported API operation for publishing a specific draft/version; if available, add an explicit, confirmation-protected publish command.
- Add regression tests for per-user draft divergence and stale Dashboard publish previews.

---

## Direct Telnyx + OpenAI Realtime migration to reduce per-call cost

### Idea

Evaluate bypassing Vapi for high-volume production calls by connecting the existing Polish Telnyx number to OpenAI Realtime through a custom orchestration layer. Keep Vapi during offer validation, then migrate only if a direct implementation preserves conversation quality and produces meaningful savings at real call volume.

### Observed cost baseline

A PRX02 test call produced this Vapi cost breakdown:

| Component | Cost | Share |
|---|---:|---:|
| LLM | $0.22 | 50.8% |
| Vapi Platform | $0.19 | 43.8% |
| Analysis: Structured Output | $0.02 | 5.3% |
| **Total** | **$0.43** | **99.9%** |

Removing only the Vapi platform charge would reduce this sample from $0.43 to approximately $0.24, a theoretical saving of about 44%. It would not automatically cut the price in half. Hosting, telephony, orchestration, monitoring and post-call extraction would still create costs.

At the same observed call profile, the removable Vapi platform portion is approximately:

| Calls | Vapi platform cost |
|---:|---:|
| 100 | $19 |
| 1,000 | $190 |
| 10,000 | $1,900 |

These figures are a single-call extrapolation, not a forecast. Actual savings depend on call duration, speaking ratio, prompt size, reasoner/tool usage, model selection and telephony costs.

### Candidate architectures

#### Option A: Telnyx SIP → OpenAI Realtime SIP

```text
Polish Telnyx number
→ Telnyx SIP trunk
→ OpenAI Realtime SIP
→ sideband backend WebSocket
→ private tools and Upstash FAQ retrieval
→ post-call extraction and email workflow
```

This removes an additional realtime media framework but requires a server to accept calls, verify webhooks, maintain sideband state, execute tools and handle call lifecycle events.

#### Option B: Telnyx Media Streaming → Pipecat → OpenAI Realtime

```text
Polish Telnyx number
→ bidirectional Telnyx media WebSocket
→ Pipecat service
→ OpenAI Realtime
→ Upstash and internal tools
```

Pipecat has documented Telnyx WebSocket support and gives more control over transport and orchestration.

#### Option C: Telnyx SIP → LiveKit Agents → OpenAI

```text
Polish Telnyx number
→ LiveKit SIP
→ LiveKit Agents
→ OpenAI Realtime or a chained STT/LLM/TTS pipeline
```

LiveKit provides production-oriented agent lifecycle, SIP, load balancing and observability, but introduces another infrastructure layer and its associated cost.

### Capabilities that must replace Vapi

A direct implementation must reproduce or intentionally replace:

- telephony and SIP/media orchestration;
- low-latency audio streaming;
- turn-taking, interruption and silence handling;
- speaker/reasoner or equivalent task orchestration;
- tool execution and idempotency;
- Upstash FAQ retrieval;
- call state and stale-result handling;
- end-of-call events;
- structured lead extraction;
- consent-based email capture and booking-link delivery;
- logs, cost reporting, retries and failure diagnostics;
- concurrency, deployment, scaling and secret management.

OpenAI Realtime does not directly reproduce Vapi's GPT Live speaker/reasoner architecture. A direct build must either simplify to one realtime model or implement an equivalent orchestration layer.

### Reverse-engineering workstream

Use the `reverse-engineer-anything` skill and REA to study Vapi's shipped browser/JavaScript artifacts and observable runtime behavior from our own authorized Vapi account. The goal is to understand the behavior that a direct implementation must reproduce, not to copy proprietary source code or bypass authentication, licensing, access controls or security boundaries.

Start with official Vapi documentation and exported configurations. Use reverse engineering only to resolve concrete gaps that documentation and normal API observation do not answer.

Potential targets and evidence:

- Vapi Dashboard JavaScript bundles and browser runtime behavior;
- network requests and responses generated by our own dashboard actions;
- public Vapi SDK/npm packages and their serialized configuration shapes;
- call logs, webhook payloads, tool-call events and timing from our own test calls;
- speaker/reasoner delegation traces and stale-result behavior;
- prompt packaging and configuration normalization;
- retry, idempotency and end-of-call behavior;
- turn-taking, interruption, silence and endpointing behavior;
- cost and usage telemetry exposed to our account.

Questions to answer:

- How are speaker and reasoner requests coordinated and correlated?
- Which state is held by Vapi versus the underlying model provider?
- How are concurrent reasoner results queued, cancelled or discarded?
- How are tool calls, retries and duplicate actions handled?
- Which default prompts or hidden configuration materially affect behavior?
- How are server messages, structured outputs and call artifacts sequenced?
- Which parts can be reconstructed cleanly with OpenAI, Telnyx and our own backend?

Produce an evidence-backed compatibility report separating observed behavior, inference and unknowns. Preserve artifact identities, versions and limitations. Any replacement implementation should be clean-room: reproduce documented or observed interfaces and outcomes without copying Vapi's proprietary code, secrets or protected assets.

### Pricing research snapshot — 2026-10-16

- Vapi's Usage-only plan lists a $0.05 per-minute platform fee in addition to provider costs.
- OpenAI lists `gpt-realtime-2.1` audio at $32 per million input audio tokens and $64 per million output audio tokens.
- OpenAI lists `gpt-realtime-2.1-mini` audio at $10 per million input audio tokens and $20 per million output audio tokens.
- OpenAI estimates approximately one input audio token per 100 ms of user speech and one output audio token per 50 ms of assistant speech.
- Direct cost therefore depends on actual speaking time and accumulated context, not only wall-clock call duration.

Pricing changes over time. Recheck official pages before making a migration decision.

### Validation required before migration

Do not migrate based on the single observed call. Build a narrow prototype and compare at least 20 representative Polish calls against Vapi using the same scenarios.

Measure:

- total cost per completed call and per minute;
- median and p95 response latency;
- Polish voice quality and pronunciation;
- interruption and turn-taking quality;
- objection-handling accuracy;
- `search_faq` retrieval accuracy;
- email-address capture and confirmation accuracy;
- tool success and duplicate-action rate;
- call completion and qualified-lead conversion;
- operational time spent maintaining the system.

Record the benchmark under `docs/evals/` and obtain explicit product-owner approval before changing production traffic.

### Decision rule

Keep Vapi while call volume is low and the acquisition system is still being validated. Consider migration when measured Vapi platform spend is materially larger than the amortized engineering and operating cost of the direct stack, and only if the prototype meets or exceeds Vapi's conversation quality and reliability.

### Sources

- OpenAI Realtime pricing: https://developers.openai.com/api/docs/pricing
- OpenAI voice-agent architecture: https://developers.openai.com/api/docs/guides/voice-agents
- OpenAI Realtime SIP: https://developers.openai.com/api/docs/guides/voice-sip
- OpenAI server-side controls: https://developers.openai.com/api/docs/guides/voice-server-controls
- Vapi pricing: https://vapi.ai/pricing
- Vapi GPT Live testing: https://docs.vapi.ai/gpt-live/testing
- LiveKit Agents: https://docs.livekit.io/agents/
- LiveKit OpenAI Realtime: https://docs.livekit.io/agents/models/realtime/openai/
- Pipecat Telnyx WebSockets: https://docs.pipecat.ai/pipecat/telephony/telnyx-websockets

---

## Shared Railway knowledge-base and semantic-search service

### Idea

When the current Upstash free-tier limits become restrictive, build a shared Railway-hosted knowledge service for all voice agents. Reproduce the existing Upstash vector semantic-search path and its surrounding behavior as closely as practical, including retrieval, result ranking, the reasoning/grounding LLM step and the existing response contract.

The first migration target should be 1:1 behavioral compatibility with the current agent integrations rather than a redesign. Existing callers should require only an endpoint and credential change.

### Current Upstash usage snapshot — 2026-11-23

| Resource | Current usage | Free limit |
|---|---:|---:|
| Records | 249 | 140,000 |
| Requests | 2 | 20,000/day |
| Storage | 2 MB | 1 GB |
| Bandwidth | 1 MB | 50 GB |
| Cost | $0.00 | — |

There is no immediate capacity pressure. Treat this as a planned migration project to begin when usage approaches a free-tier limit, Upstash pricing becomes material, or centralized control becomes operationally valuable.

### Proposed architecture

```text
Vapi, LiveKit and future agent runtimes
→ one Railway HTTP knowledge-service URL
→ API gateway authentication and project authorization
→ agent/project-specific knowledge namespace
→ embedding and semantic search
→ optional reasoning/grounding LLM
→ normalized evidence-backed response
```

The initial external contract should use one rotatable service API key shared by our agent runtimes. The Railway gateway must validate the key before processing a request and internally restrict every request by trusted `project_code`, agent identity and allowed knowledge-base namespace. Do not allow callers to select arbitrary databases or namespaces without server-side authorization. Per-agent credentials can be introduced later if the shared credential's blast radius becomes unacceptable.

### Knowledge organization

Use one shared service while keeping each agent's knowledge logically isolated and versioned. Every stored item should identify at least:

- `project_code`;
- agent or knowledge-base identifier;
- source document and source section;
- content version;
- approved/published status;
- embedding version;
- searchable text and metadata.

Queries must always be scoped to the authorized project and knowledge base. Cross-agent retrieval must be impossible unless explicitly configured.

The storage engine and vector database are still to be selected. Preserve a clean service boundary so the HTTP contract does not depend on a specific database implementation.

### Compatibility requirements

Replicate the current Upstash-backed behavior before adding new capabilities:

- the same query input expected by existing `search_faq` integrations;
- equivalent embedding and semantic ranking behavior;
- configurable `topK`, retaining `topK: 3` as the current default;
- scores and source metadata sufficient for grounding and diagnostics;
- the same approved-facts and no-invention rules;
- equivalent reasoning/grounding LLM behavior where the current flow uses it;
- deterministic handling of empty, low-confidence and unauthorized results;
- bounded timeouts and normalized error responses;
- request IDs, latency measurements and structured logs;
- no cross-project data leakage.

### Suggested API shape

```text
POST /v1/knowledge/search
Authorization: Bearer <shared-service-key>
Content-Type: application/json

{
  "projectCode": "PR011",
  "knowledgeBase": "tatravet",
  "query": "Czy klinika jest otwarta w sobotę?",
  "topK": 3
}
```

The response should return retrieved facts, scores, source/version metadata and an explicit result status. If the service includes a reasoning answer, keep the retrieved evidence separate from the generated answer so callers can verify grounding.

### Migration and validation

1. Freeze representative queries and raw Upstash results for every active knowledge base.
2. Import the same approved content into the Railway service without modifying source text.
3. Run both services in parallel against identical queries.
4. Compare top results, ranking, scores, answer grounding and p50/p95 latency.
5. Test unauthorized project and namespace access.
6. Switch one draft agent by changing only its endpoint and credential.
7. Keep a rollback path to Upstash until production parity is demonstrated.
8. Migrate the remaining agents only after retrieval quality and reliability meet or exceed the existing implementation.

### Success criteria

- Existing agent integrations work with minimal endpoint-level changes.
- Retrieval accuracy does not regress on the frozen evaluation set.
- No agent can access another agent's private knowledge base.
- The service supports all current knowledge bases through one maintained deployment.
- Search and reasoning latency are visible separately.
- Knowledge imports are repeatable, versioned and reversible.
- The Railway operating cost is lower than or operationally preferable to the Upstash tier it replaces.
