# Vapi vs LiveKit for Voice AI Agents

**Research date:** 2026-11-23

**Project context:** PR011 Tatravet, Polish telephone agent, Telnyx SIP, existing Railway hosting

**Status:** Research and decision support; not a production migration decision

## Executive overview

Vapi and LiveKit overlap, but they are not the same kind of product.

- **Vapi is a managed voice-agent platform.** It supplies the orchestration layer around telephony, models, tools, prompts, call lifecycle, logs, simulations, monitoring and deployment configuration. The developer mainly configures assistants and connects business tools.
- **LiveKit is a realtime media platform plus an agent application framework.** It supplies rooms, media transport, SIP, dispatch, agent SDKs, testing and observability, but the agent remains application code that the developer deploys and operates. LiveKit can host that code, or the developer can self-host it.

For our intended LiveKit architecture, the comparison is:

```text
Vapi:
Telnyx → Vapi managed runtime → AI providers → business tools

LiveKit:
Telnyx → LiveKit Cloud SIP/media → Railway-hosted LiveKit worker
       → AI providers → business tools
```

Telnyx and equivalent AI-provider usage are shared costs. The main economic comparison is therefore Vapi's `$0.05/min` hosting charge versus LiveKit's plan, SIP/media usage and the incremental Railway compute required by the self-hosted worker.

The larger strategic difference is control. Vapi minimizes engineering and operational work. LiveKit exposes the realtime session and orchestration in code, making it easier to implement custom retrieval, client-managed GPT-Live delegation, deterministic state transitions and detailed latency optimizations.

---

## 1. Scope and assumptions

This report focuses on telephone voice agents rather than browser-only WebRTC applications.

Assumptions for an apples-to-apples comparison:

- Telnyx remains the telephone-number and PSTN carrier provider.
- Telnyx connects through an external SIP trunk in both architectures.
- The same realtime model or equivalent STT/LLM/TTS providers are used where possible.
- Existing business systems, Upstash data and backend APIs remain available.
- The LiveKit agent worker runs on the existing Railway account.
- LiveKit Cloud continues to provide SIP, rooms, media transport and dispatch; this is not a fully self-hosted LiveKit media-server deployment.
- Prices are snapshots and must be checked again before a purchasing or migration decision.

---

## 2. Fundamental platform difference

### 2.1 Vapi: managed orchestration platform

A Vapi assistant is configured with a model, voice, transcriber, prompt and tools. Vapi manages the live call and connects the speech, model, telephony and tool layers. Multi-agent behavior can be represented with Squads. Configuration can be managed through the Dashboard, API or Vapi's config-as-code workflow. [V1] [V2] [V3]

The developer normally does **not** operate the realtime call worker. External code is needed mainly for tools, webhooks, custom providers and business integrations.

### 2.2 LiveKit: media infrastructure plus application framework

A LiveKit agent server registers with LiveKit and waits for dispatched jobs. For each accepted job, it starts an isolated process that joins a LiveKit room as an agent participant. The application controls the session through Python or Node.js code. [L1] [L2]

The worker can be:

1. deployed to LiveKit Cloud; or
2. self-hosted on Railway, Kubernetes or another container platform.

In the second case, LiveKit handles media, SIP and dispatch, while we handle worker availability, deployment, capacity and runtime failures. Self-hosted workers connect outward over WebSocket and do not require an exposed inbound media port. [L2]

### Practical consequence

| Question | Vapi | LiveKit with Railway worker |
|---|---|---|
| Who runs the realtime agent process? | Vapi | Us, on Railway |
| Who manages rooms and SIP media? | Vapi | LiveKit Cloud |
| Where is orchestration expressed? | Platform configuration and prompts | Application code, prompts and SDK objects |
| Who owns autoscaling and worker health? | Vapi | Primarily us |
| Can the full session logic be customized in code? | Partly | Yes |

---

## 3. Telephony and SIP

Both platforms can sit behind an external SIP provider such as Telnyx.

### Vapi

Vapi supports phone calls, imported numbers and external telephony. Its pricing calculator currently shows a `$0` Vapi transport fee for Vapi telephony/SIP, while the standard hosting fee and external carrier charges remain. [V4]

### LiveKit

LiveKit Cloud supports third-party SIP trunks, including documented Telnyx inbound and outbound setups. Inbound trunks and dispatch rules route calls into rooms; outbound calls are created through an outbound trunk and SIP participant APIs. [L3] [L4]

LiveKit meters third-party SIP sessions separately. Its billing documentation states that SIP is measured by session duration, billed by the second, with a minimum session duration documented in the billing rules. Telnyx bills its own carrier and number charges independently. [L5]

### Comparison

| Area | Vapi | LiveKit |
|---|---|---|
| Telnyx external SIP | Supported | Supported |
| Inbound calls | Managed configuration | Trunk + dispatch rule |
| Outbound calls | Managed call API/campaign flow | Outbound trunk + SIP participant API |
| Call transfer | Platform tools/configuration | SIP and agent logic in code |
| Carrier bill | Separate Telnyx bill | Separate Telnyx bill |
| SIP platform charge | Included within Vapi platform economics | Separate LiveKit SIP allowance/overage |
| Debugging responsibility | Vapi plus carrier | Telnyx, LiveKit SIP, room and worker layers |

LiveKit adds a visible infrastructure boundary but gives us more direct control over room creation, dispatch metadata, SIP participants and failure handling.

---

## 4. Model and provider flexibility

### Vapi

Vapi offers a provider catalog for transcribers, intelligence models and voices. Supported provider keys can be supplied directly, and Vapi says model costs are passed through without markup on its usage plans. It also supports an OpenAI-compatible custom LLM endpoint and a custom transcriber over WebSocket. [V4] [V5]

Vapi therefore allows substantial model choice, but calls still run inside Vapi's orchestration model.

### LiveKit

LiveKit supports:

- cascaded STT → LLM → TTS pipelines;
- realtime speech-to-speech models;
- LiveKit Inference using one LiveKit credential and bill;
- direct provider plugins using our own API keys;
- custom model integrations implemented in application code. [L6] [L7]

With direct provider plugins, model usage is billed by the provider rather than LiveKit. With LiveKit Inference, model use is billed through LiveKit and draws from the plan's inference credit.

### Comparison

Both platforms provide broad model choice. LiveKit has an advantage when behavior must be implemented below the normal platform abstraction because the agent pipeline itself is code. Vapi has an advantage when broad provider choice is desired without operating the realtime worker.

---

## 5. GPT-Live and orchestration

This area is particularly important for PR011.

### Vapi GPT-Live

Vapi's GPT-Live architecture separates:

- a caller-facing **speaker**; and
- a **reasoner** that performs delegated tasks and tool calls.

The speaker decides when to delegate. The reasoner follows separate instructions and returns a result to the speaker. Vapi supports reasoner tools and skills, but its built-in Knowledge Base and Query tool are not available directly to the GPT-Live reasoner; custom retrieval must be connected through a function, API request or MCP tool. [V6] [V7]

Our measured PR011 retrieval path is:

```text
speaker delegation
→ reasoner pass 1
→ Upstash lookup
→ reasoner pass 2
→ speaker response
```

Observed FAQ turns spent roughly 3.3–3.5 seconds inside this delegated sequence in the best measured samples, while Upstash itself remained approximately 0.6 seconds. Slower examples reached 5–6 seconds even though retrieval remained stable. This makes model delegation, rather than vector search, the dominant observed latency source. [P1]

### LiveKit GPT-Live

LiveKit supports GPT-Live with client-managed delegation. With `delegation="client"`, application code receives the delegation event and handles reasoning or retrieval locally. LiveKit also provides explicit tools, workflows, handoffs, tasks and task groups. [L8] [L9]

This allows us to implement paths such as:

```text
GPT-Live delegation
→ local in-memory approved-facts lookup
→ direct response to the realtime session
```

or:

```text
user turn completed
→ retrieve relevant facts before generation
→ update the model context
→ generate response
```

The application can own state and side effects while the model owns language and interpretation.

### Consequence for PR011

LiveKit removes a platform restriction that matters to us: we can own the delegation handler and avoid an unnecessary second reasoning pass when the requested fact can be resolved deterministically. This creates a credible path to lower knowledge-answer latency, but it must be measured. Merely porting the existing prompts to LiveKit will not automatically make the agent faster.

---

## 6. Knowledge bases and retrieval

### Vapi

For ordinary assistants, Vapi provides knowledge tools and managed knowledge-base functionality. For GPT-Live, the reasoner cannot use Vapi's built-in Knowledge Base/Query path directly, so PR011 currently uses a custom FAQ function backed by Upstash. [V7]

Advantages:

- managed integration for supported assistant architectures;
- less retrieval infrastructure for standard use cases;
- tool logs remain associated with the call.

Limitations for our GPT-Live design:

- delegation is model-decided;
- custom retrieval adds a network and tool boundary;
- speaker/reasoner behavior may require carefully synchronized prompts;
- the complete delegated path is less directly controllable.

### LiveKit

LiveKit does not force one hosted knowledge-base abstraction. Retrieval can be implemented using:

- in-memory approved facts;
- Upstash or another vector store;
- a database;
- a pre-generation hook;
- a tool;
- a task or handoff;
- client-managed GPT-Live delegation.

Advantages:

- arbitrary retrieval timing and caching;
- deterministic routing for known facts and known limitations;
- easier separation between read-only knowledge and side-effecting tools;
- direct control over cancellation, stale results and timeouts.

Disadvantages:

- we must implement and test grounding behavior;
- there is no platform-managed knowledge lifecycle unless we build or add one;
- observability and content-version tracking become our responsibility.

For Tatravet's small approved knowledge set, direct context or in-memory retrieval is technically plausible on either platform. The strongest LiveKit benefit appears when knowledge and tool paths need programmatic routing rather than only a larger prompt.

---

## 7. Turn-taking, interruptions and latency controls

### Vapi

Vapi exposes speech and voice-pipeline configuration and manages the underlying realtime pipeline. This reduces setup effort. However, platform defaults and hidden runtime behavior can make very fine-grained diagnosis harder. The developer primarily tunes configuration rather than changing the session loop itself.

### LiveKit

LiveKit exposes explicit controls for:

- VAD and endpointing;
- multimodal turn detection;
- minimum and maximum endpointing delays;
- adaptive interruption handling;
- minimum interruption duration or word count;
- preemptive response generation;
- optional preemptive TTS;
- noise suppression and voice isolation. [L10]

LiveKit documents the latency/quality trade-off: aggressive endpointing and preemptive generation can make an agent respond faster, but can waste compute or cause interruptions and premature replies.

### Assessment

- **Vapi:** faster to reach acceptable turn-taking because defaults are managed.
- **LiveKit:** stronger for systematic latency tuning and custom interruption behavior.
- **Neither:** guarantees lower latency without controlled tests using identical calls, prompts, models and regions.

---

## 8. Tools, state and business workflows

### Vapi

Vapi supports function tools, API requests, transfers, MCP, server events, structured outputs, Squads and reasoner skills. This covers many production business workflows with little runtime code. [V2] [V6]

Benefits:

- quick integration of HTTP tools;
- call lifecycle and tool events managed by the platform;
- easier setup for standard transfers and post-call extraction;
- less infrastructure code.

Risks:

- a model saying an action happened does not prove the tool succeeded;
- stateful or approval-sensitive actions still require server-side validation;
- complex workflows can become distributed across prompts, tools, dashboard objects and external services.

### LiveKit

LiveKit supplies tools, agents, handoffs, tasks, task groups and workflows as SDK concepts. Tasks can temporarily take control, return typed results and then return control to the main conversation. [L9]

Benefits:

- state can live in normal application objects;
- approvals and side effects can be enforced in code;
- deterministic transitions can be tested using the normal test framework;
- business logic can be versioned in the same repository as the agent.

Costs:

- more application code;
- more failure paths to own;
- stronger need for idempotency, persistence and deployment discipline.

LiveKit is the deeper framework; Vapi is the faster product abstraction.

---

## 9. Deployment and change management

### Vapi

Vapi supports Dashboard, API and config-as-code management. [V3]

This is convenient, but this repository has documented an operational issue where the API-key draft matched local configuration while the Dashboard publish preview represented a different user draft. Successful local/API diffing did not prove that the published live version matched. [P2]

Vapi therefore requires explicit verification of:

- local configuration;
- API draft;
- Dashboard/publish draft;
- published live version.

### LiveKit with Railway

The worker is ordinary application code deployed from GitHub to Railway. LiveKit dispatches jobs to the registered worker; GitHub/Railway deployment does not itself dispatch calls. [P3]

Advantages:

- standard source-control and deployment model;
- code review covers prompts, tools and orchestration together;
- normal environment-based secrets and releases;
- no separate assistant-publish state.

Responsibilities:

- use `python ... start` rather than development mode;
- ensure graceful shutdown long enough for active calls;
- avoid dropping sessions during Railway deployments;
- operate health checks and worker capacity;
- provide rollback procedures.

LiveKit Cloud-hosted deployments offer managed rolling releases and instant rollback on paid plans, but those benefits do not automatically apply to a Railway-hosted worker. [L11]

---

## 10. Testing, simulations and observability

### Vapi

Vapi provides:

- call transcripts and recordings;
- pipeline logs;
- latency and cost data;
- structured outputs and analysis;
- simulations for complete mock conversations;
- evals for focused model/tool behavior;
- monitors that evaluate retained calls and notify by email, Slack or webhook. [V8] [V9]

This is a strong integrated experience, especially for a team that does not want to assemble an observability stack.

### LiveKit

LiveKit provides:

- turn-level tests for messages, tools and handoffs;
- local interactive agent debugging;
- text simulations;
- audio simulations that exercise the speech pipeline;
- final-state checks;
- session transcripts, traces, logs, metrics and recordings;
- OpenTelemetry export for traces. [L12] [L13]

Agent Insights can work with a self-hosted agent when it connects to LiveKit Cloud media servers. It does not require the worker itself to be hosted by LiveKit. [L13]

### Comparison

| Capability | Vapi | LiveKit |
|---|---|---|
| Integrated call dashboard | Strong | Strong with Agent Insights |
| Raw operation timing | Strong call logs | Strong traces/metrics |
| Turn-level code tests | More platform-oriented evals | Native SDK test sessions |
| Whole-call simulations | Yes | Yes, text and audio |
| Production monitoring | Built-in monitors | Insights plus external telemetry |
| OpenTelemetry control | Less central to product | Explicitly supported |
| Setup effort | Lower | Higher |

Vapi's advantage is turnkey observability. LiveKit's advantage is that tests and traces are closer to the application code and can be integrated into CI and external observability systems.

---

## 11. Concurrency and scaling

### Vapi

Current published Vapi concurrency includes:

- Usage only: 4 concurrent calls;
- Core: 10;
- Pro: 30;
- Premier/Enterprise: custom.

Additional lines are listed at `$10/line/month`. If all lines are occupied, new calls cannot be accepted or started. [V4] [V10]

Vapi operates the underlying voice runtime, so scaling within purchased limits is mostly a commercial/configuration decision.

### LiveKit with a self-hosted worker

There are several independent limits:

1. LiveKit room/participant and SIP plan limits;
2. Railway worker CPU and memory;
3. number of job processes the worker can sustain;
4. AI-provider concurrency and rate limits;
5. LiveKit Inference concurrency, only when using LiveKit Inference;
6. turn-detector request limits if using hosted turn models from a self-hosted worker.

LiveKit Ship lists 1,000 concurrent participant connections and 20 LiveKit Inference concurrent requests. These are not equivalent to guaranteed end-to-end call capacity for a Railway worker. We must load-test the complete stack. [L5] [L14]

### Assessment

- Vapi makes low-to-medium concurrency operationally simpler.
- LiveKit can scale much further under our control, but capacity planning becomes our responsibility.
- At meaningful volume, Railway should run multiple worker replicas and deployments should drain active calls safely.

---

## 12. Reliability and operational ownership

### Vapi

Vapi is responsible for the managed call runtime. Published package terms currently list no uptime SLA for Usage-only or Core, 99% for Pro and 99.9% for Premier. [V4]

A Vapi deployment still depends on:

- Telnyx;
- selected model providers;
- our webhook/tool services;
- our databases and integrations.

### LiveKit

LiveKit's pricing matrix lists 99.99% uptime for media transport across its public plans, but a support SLA is listed only for Enterprise. [L14]

Our architecture adds Railway worker availability as a critical dependency. A LiveKit media service can be healthy while the self-hosted worker is unavailable, overloaded or restarting.

Operational requirements include:

- at least one continuously registered worker;
- safe process limits;
- graceful shutdown and draining;
- restart policies;
- monitoring for worker registration and dispatch failures;
- provider timeouts and fallbacks;
- deployment health checks;
- correlation IDs across Telnyx, LiveKit, Railway and providers.

### Assessment

Vapi concentrates operational responsibility in one managed platform. LiveKit separates responsibilities cleanly but increases the number of components we must operate.

---

## 13. Security, privacy and compliance

### Vapi

Vapi states that it is SOC 2 Type II attested. HIPAA support is a paid organization-level feature requiring a BAA and compatible providers. Vapi documentation states that HIPAA mode and Zero Data Retention cannot be enabled together. Current pricing lists HIPAA eligibility as a `$2,000/month` add-on. [V4] [V11]

Retention currently varies by package:

- Usage only: 14 days raw-data retention;
- Core: 30 days;
- Pro: 180 days;
- Premier: custom.

ZDR and other controls depend on package and configuration.

### LiveKit

LiveKit lists SOC 2 Type II materials in its Trust Center. HIPAA is available on Scale and Enterprise according to the pricing matrix and requires a BAA for approved LiveKit Cloud projects/services. The BAA does not automatically cover self-hosted infrastructure or third-party providers. [L14] [L15]

LiveKit Inference is zero-data-retention by default, while Agent Observability can retain transcripts, logs, traces, metrics and audio. LiveKit documents a default 30-day observability retention window. [L7] [L16]

For our design, compliance must cover the full chain:

```text
Telnyx
+ LiveKit Cloud
+ Railway
+ AI providers
+ Upstash
+ business tools
```

### Assessment

Neither platform makes the entire system compliant automatically. Vapi can reduce the number of directly operated components, while LiveKit gives more control over where application data is processed. LiveKit HIPAA access starts on a substantially more expensive plan than Ship, and Railway plus every provider would still need separate review.

---

## 14. Vendor lock-in and portability

### Vapi lock-in

Vapi configurations use platform-specific assistants, Squads, tools, hooks, server events and GPT-Live reasoner concepts. Provider keys and custom endpoints reduce model lock-in, but orchestration behavior remains platform-specific.

Migration requires recreating:

- call lifecycle behavior;
- speech and interruption tuning;
- tool events;
- transfers;
- structured extraction;
- observability;
- retries and failure handling;
- speaker/reasoner coordination.

### LiveKit lock-in

The LiveKit Agents SDK and core media server are open source, and the agent is normal Python or Node.js code. The worker can connect to LiveKit Cloud or a self-hosted LiveKit server. This improves portability.

However, use of LiveKit Cloud SIP, Agent Insights, Inference, simulations and managed deployment features creates platform dependencies of its own.

### Assessment

LiveKit provides a materially better exit path because both application logic and core server technology are available as code. Vapi offers provider portability but stronger orchestration lock-in.

---

## 15. Developer experience and maintenance burden

### Vapi strengths

- fastest route from prompt to working telephone agent;
- managed telephony and runtime;
- broad provider catalog;
- integrated logs, recordings, costs and simulations;
- standard tools and transfers require little code;
- no worker deployment or scaling work;
- lower initial engineering cost.

### Vapi weaknesses

- `$0.05/min` platform charge;
- lower-level behavior can be hard to inspect or override;
- GPT-Live speaker/reasoner delegation can add latency;
- built-in knowledge base is unavailable to GPT-Live reasoner;
- platform-specific configuration and publish lifecycle;
- low included concurrency on Usage-only;
- meaningful SLA and enterprise controls require expensive packages.

### LiveKit strengths

- full orchestration in Python/Node.js;
- self-hosted worker on existing Railway infrastructure;
- direct access to room, participants, events and state;
- client-managed GPT-Live delegation;
- flexible RAG, caching and context injection;
- explicit tasks, handoffs, workflows and tools;
- strong testing and OpenTelemetry story;
- open-source SDK/server and better portability;
- lower platform cost at sufficient call volume.

### LiveKit weaknesses

- greater implementation and maintenance effort;
- worker health, deployment and scaling become our responsibility;
- pricing is layered and harder to forecast;
- more infrastructure boundaries to debug;
- advanced compliance and administration require Scale/Enterprise;
- self-hosted turn-detection services may incur per-request charges;
- direct control creates more opportunities for implementation bugs.

---

## 16. Cost comparison for our architecture

### 16.1 Shared costs

When both use the same providers, these costs largely cancel out in the platform comparison:

- Telnyx number rental;
- Telnyx PSTN minutes;
- realtime-model or STT/LLM/TTS usage;
- Upstash/database usage;
- business APIs;
- reasoner model usage, if implemented equivalently.

They still matter to total cost, but not to the incremental Vapi-versus-LiveKit decision.

### 16.2 Vapi platform cost

Vapi Usage-only currently lists:

```text
$0.05 per call minute
no fixed monthly minimum
4 concurrent calls
```

Model costs are additional and passed through. [V4]

Formula:

```text
Vapi platform cost = monthly call minutes × $0.05
```

### 16.3 LiveKit Build for a pilot

Relevant Build allowances:

- `$0/month`;
- 1,000 third-party SIP minutes;
- 5,000 WebRTC participant minutes;
- `$2.50` inference credit;
- 100 concurrent participant connections;
- development allowances for hosted turn handling. [L14]

Build does not list third-party SIP overage pricing. Treat the allowance as a pilot/development ceiling rather than assuming production pay-as-you-go.

### 16.4 LiveKit Ship with Railway worker

Relevant Ship pricing:

- `$50/month` starting price;
- 5,000 third-party SIP minutes included;
- third-party SIP overage: `$0.004/min`;
- 150,000 WebRTC participant minutes included;
- WebRTC overage: `$0.0005/min`;
- `$5` LiveKit Inference credit;
- 500,000 observability events included;
- 5,000 session-recording minutes included. [L14]

Because the worker is hosted on Railway, LiveKit Cloud agent-session hosting minutes should not be charged as hosted-agent minutes. The pricing matrix says self-hosted agents count against WebRTC participant minutes, while the pricing calculator says phone connections use telephony rather than WebRTC. This is an official-documentation ambiguity worth confirming with LiveKit before production. It has no practical effect on the scenarios below because 150,000 WebRTC minutes are included in Ship.

For the relevant range:

```text
LiveKit platform cost ≈ $50
  + max(0, monthly SIP minutes - 5,000) × $0.004
  + incremental Railway compute
```

### 16.5 Platform-only comparison

This excludes shared Telnyx and AI-provider costs.

| Monthly call minutes | Vapi Usage | LiveKit Build | LiveKit Ship before Railway |
|---:|---:|---:|---:|
| 100 | $5 | $0 | $50 |
| 500 | $25 | $0 | $50 |
| 1,000 | $50 | $0 allowance limit | $50 |
| 2,000 | $100 | No documented overage | $50 |
| 5,000 | $250 | No documented overage | $50 |
| 10,000 | $500 | No documented overage | $70 |
| 20,000 | $1,000 | No documented overage | $110 |

### 16.6 Break-even

Ignoring incremental Railway cost:

```text
$50 ÷ $0.05/min = 1,000 minutes/month
```

If the LiveKit worker adds Railway cost:

| Incremental Railway cost | Approximate break-even |
|---:|---:|
| $0/month | 1,000 min/month |
| $5/month | 1,100 min/month |
| $10/month | 1,200 min/month |
| $20/month | 1,400 min/month |
| $50/month | 2,000 min/month |

Because we already use Railway, the correct number is the **incremental** compute cost, not the whole Railway account bill.

### 16.7 Illustrative total with common usage costs

Assume only for illustration:

```text
Realtime model: $0.05/min
Telnyx:          $0.008/min
```

Exclude additional reasoner/tool-model tokens.

| Minutes | Vapi total | LiveKit Ship total before Railway | Difference |
|---:|---:|---:|---:|
| 1,000 | $108 | $108 | $0 |
| 5,000 | $540 | $340 | LiveKit saves $200 |
| 10,000 | $1,080 | $650 | LiveKit saves $430 |

These are planning examples, not forecasts. Realtime token usage, speaking ratio, prompt length, post-call analysis, carrier destination and reasoner behavior can materially change total cost.

---

## 17. Decision matrix

| Criterion | Vapi | LiveKit + Railway | Advantage |
|---|---|---|---|
| Fastest implementation | Managed configuration | Application build | Vapi |
| Lowest operational burden | Platform operated | Worker operated by us | Vapi |
| Fine-grained orchestration | Limited by platform abstractions | Full code control | LiveKit |
| GPT-Live client delegation | Not exposed in our tested path | Supported | LiveKit |
| Custom low-latency RAG | Possible through tools | Native code/in-memory options | LiveKit |
| Turn-taking controls | Managed configuration | Deep controls | LiveKit |
| Integrated logs and cost reporting | Excellent | Strong, more configurable | Tie/Vapi |
| Unit and CI testing | Platform eval focus | SDK-native test sessions | LiveKit |
| Provider choice | Broad | Broad | Tie |
| Low-volume production economics | No fixed plan, pay per minute | Ship starts at $50 | Vapi |
| Development pilot economics | Usage fee after credits | Build allowances | LiveKit |
| High-volume platform economics | `$0.05/min` | Low SIP overage after fixed plan | LiveKit |
| Concurrency simplicity | Buy call lines | Engineer worker/provider capacity | Vapi |
| Open-source portability | Proprietary orchestration | Open SDK/server | LiveKit |
| Compliance simplicity | Fewer directly operated runtime components | More vendors and owned runtime | Vapi |
| Maximum architectural control | Moderate | High | LiveKit |

---

## 18. Recommendation for PR011

### Near term

Keep the current Vapi implementation as the production-quality baseline while improving the direct-context/hybrid knowledge strategy. Vapi remains the safer option while traffic is low and the product flow is still being validated.

At the same time, continue the LiveKit prototype using:

```text
Telnyx external SIP
→ LiveKit Cloud Build
→ Railway-hosted worker
→ same or equivalent GPT-Live model
→ approved Tatravet facts in memory
→ Upstash only as fallback
```

### Why a prototype is justified

LiveKit addresses two concrete PR011 concerns:

1. It may reduce knowledge-answer latency through client-managed delegation and local retrieval.
2. It may remove a large recurring platform fee once call volume exceeds approximately 1,000–1,400 minutes/month.

These are stronger reasons than a generic desire to self-host.

### Why an immediate migration is not justified

We have not yet shown that the LiveKit implementation matches Vapi on:

- Polish voice quality;
- interruption handling;
- call completion;
- transfers and tools;
- observability;
- worker reliability;
- deployment safety;
- total engineering/operations time.

### Required benchmark

Run at least 20 representative calls per platform using identical scenarios. Measure:

- platform and provider cost per completed call;
- cost per wall-clock minute;
- median and p95 response latency;
- first-response latency;
- knowledge-answer latency;
- factual accuracy and unsupported claims;
- delegation frequency;
- tool success and duplicate-action rate;
- interruption and false-interruption rate;
- Polish pronunciation and speech naturalness;
- call completion rate;
- worker errors and reconnects;
- operator time spent debugging and maintaining each stack.

### Suggested migration threshold

Consider routing production traffic to LiveKit only when all are true:

1. LiveKit meets or beats Vapi's measured conversation quality.
2. No critical reliability or tool-state regressions remain.
3. Deployment and worker draining have been tested under live calls.
4. Estimated monthly savings exceed the amortized engineering and operating burden.
5. Expected traffic is consistently above the economic break-even or LiveKit provides a separately valuable latency/control improvement.

---

## 19. Final summary

Vapi is the better product when the priority is to launch and operate a capable telephone agent with minimal infrastructure work. It bundles orchestration, provider integration, telephony control, logs, testing and monitoring into one managed service. Its main trade-offs are the recurring `$0.05/min` platform charge, platform-specific orchestration and reduced control over low-level realtime behavior.

LiveKit is the better framework when the priority is architectural control, custom latency optimization, deterministic workflows, code-level testing and long-term cost efficiency at scale. In our proposed design, LiveKit Cloud handles SIP/media/dispatch while Railway hosts the worker. This avoids LiveKit hosted-agent session charges and makes the economic break-even roughly 1,000–1,400 monthly minutes, depending on incremental Railway compute.

For PR011, the most important LiveKit benefit is not only price. It is the ability to handle GPT-Live delegation and knowledge retrieval directly in code. That could remove unnecessary reasoner passes and make factual answers faster and more predictable. The cost is that we become responsible for the realtime worker, scaling, deployment safety and a larger portion of production reliability.

The recommended strategy is therefore staged rather than ideological:

1. keep Vapi as the working baseline;
2. build the narrow LiveKit version on Build using existing Railway and Telnyx;
3. compare identical Polish calls with measured latency, quality, reliability and cost;
4. migrate only when the LiveKit evidence is better, not merely because its theoretical per-minute platform cost is lower.

---

## Sources

### Vapi official sources

- **[V1]** Introduction and architecture: https://docs.vapi.ai/quickstart/introduction
- **[V2]** Assistants, Squads and tools: https://docs.vapi.ai/assistants/quickstart · https://docs.vapi.ai/squads · https://docs.vapi.ai/tools/
- **[V3]** Config as code: https://docs.vapi.ai/config-as-code
- **[V4]** Pricing and packages: https://vapi.ai/pricing · https://docs.vapi.ai/billing/pricing-and-success-packages
- **[V5]** Provider keys and custom providers: https://docs.vapi.ai/customization/provider-keys · https://docs.vapi.ai/customization/custom-llm/using-your-server/ · https://docs.vapi.ai/customization/custom-transcriber
- **[V6]** GPT-Live overview and tools: https://docs.vapi.ai/gpt-live/overview · https://docs.vapi.ai/gpt-live/tools
- **[V7]** GPT-Live settings and knowledge limitations: https://docs.vapi.ai/gpt-live/configuration
- **[V8]** Logs and call observability: https://docs.vapi.ai/observability/logs/call-logs · https://docs.vapi.ai/observability/logs/overview
- **[V9]** Simulations, evals and monitoring: https://docs.vapi.ai/observability/simulations-quickstart · https://docs.vapi.ai/observability/evals-quickstart · https://docs.vapi.ai/observability/monitoring-quickstart
- **[V10]** Call concurrency: https://docs.vapi.ai/calls/call-concurrency
- **[V11]** Security and HIPAA: https://docs.vapi.ai/security-and-privacy/soc · https://docs.vapi.ai/security-and-privacy/hipaa

### LiveKit official sources

- **[L1]** Agent server architecture: https://docs.livekit.io/agents/server/ · https://docs.livekit.io/agents/server/lifecycle/
- **[L2]** Self-hosted agent deployment: https://docs.livekit.io/deploy/custom/deployments/
- **[L3]** Telnyx SIP setup: https://docs.livekit.io/telephony/start/providers/telnyx/
- **[L4]** Inbound and outbound trunks: https://docs.livekit.io/telephony/accepting-calls/inbound-trunk/ · https://docs.livekit.io/telephony/making-calls/outbound-trunk/
- **[L5]** Billing, quotas and limits: https://docs.livekit.io/deploy/admin/billing/ · https://docs.livekit.io/deploy/admin/quotas-and-limits/
- **[L6]** Model options: https://docs.livekit.io/agents/models/ · https://docs.livekit.io/agents/integrations/openai/
- **[L7]** LiveKit Inference: https://docs.livekit.io/agents/models/inference/
- **[L8]** GPT-Live and client delegation: https://docs.livekit.io/agents/models/realtime/gpt-live/
- **[L9]** Workflows, tasks, tools and handoffs: https://docs.livekit.io/agents/logic/workflows/ · https://docs.livekit.io/agents/logic/tasks/ · https://docs.livekit.io/agents/logic/tools/ · https://docs.livekit.io/agents/logic/agents-handoffs/
- **[L10]** Turn-taking and latency tuning: https://docs.livekit.io/agents/logic/turns/tuning/ · https://docs.livekit.io/reference/agents/turn-handling-options/
- **[L11]** LiveKit Cloud agent deployments: https://docs.livekit.io/deploy/agents/
- **[L12]** Testing and simulations: https://docs.livekit.io/testing/overview/ · https://docs.livekit.io/testing/simulations/
- **[L13]** Agent Insights and tracing: https://docs.livekit.io/testing/observability/insights/ · https://docs.livekit.io/testing/observability/tracing/
- **[L14]** Current pricing matrix: https://livekit.io/pricing.md
- **[L15]** HIPAA: https://docs.livekit.io/deploy/admin/hipaa/
- **[L16]** Observability data residency and retention: https://docs.livekit.io/testing/observability/data-residency/

### Internal project evidence

- **[P1]** PR011 latency and prompt-size findings: `knowledge/learnings.md`
- **[P2]** Vapi draft/published synchronization and direct-stack plans: `docs/FUTURE_PLANS.md`
- **[P3]** Proposed Railway + Telnyx + LiveKit architecture: `agents/pr011 - Tatravet/V3.0 Livekit test/Livekit-infrastructure-handoff.md`
