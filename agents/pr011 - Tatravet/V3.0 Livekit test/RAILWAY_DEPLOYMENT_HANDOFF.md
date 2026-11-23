# PR011 Tatravet LiveKit Agent — Railway Deployment Handoff

## Mission

Deploy the already-tested PR011 LiveKit GPT-Live worker from this repository to an existing Railway project. Keep behavior identical to the local `gpt-live-client` test unless a deployment requirement makes a code change necessary.

Target architecture:

```text
Caller
→ Telnyx Polish number / PSTN
→ Telnyx SIP trunk
→ LiveKit Cloud SIP and room
→ PR011 worker on Railway
→ LiveKit Inference: openai/gpt-live-1, Cedar
→ client-managed delegation
→ Upstash Vector pr011-faq namespace
→ LiveKit Cloud SIP
→ Telnyx
→ Caller
```

Railway hosts only the Python agent worker. LiveKit Cloud remains responsible for SIP, rooms, media, dispatch and GPT-Live inference. Upstash remains the knowledge store.

## Current status and boundaries

- Local GPT-Live client-delegation path has been tested.
- Current factual path removes the backend Responses reasoner:

  ```text
  GPT-Live delegation
  → Railway code
  → Upstash query
  → append_thinking with silent grounding rules
  → append_commentary with approved fact bodies
  → GPT-Live speech
  ```

- LiveKit cascaded STT–LLM–TTS variant exists in configuration but was **not tested**. Do not deploy it as default.
- Vapi remains a separate benchmark. Do not modify Vapi V2 files as part of this deployment.
- Do not copy local `.env` values into Git.
- Do not redesign retrieval, prompts, models or call flow during initial Railway deployment. First establish behavioral parity.

## Source files required at runtime

All paths are relative to repository root.

### Agent entrypoint

```text
agents/pr011 - Tatravet/V3.0 Livekit test/agent.py
```

Responsibilities:

- starts `AgentServer`;
- registers dispatch name `pr011-tatravet`;
- creates GPT-Live `DuplexModel` with `delegation="client"`;
- handles delegation events locally;
- queries Upstash;
- supplies silent grounding through `append_thinking()`;
- supplies only approved fact bodies through `append_commentary()`;
- drains farewell audio and closes the session;
- writes a session report on normal close.

### Prompt

```text
agents/pr011 - Tatravet/V3.0 Livekit test/prompt.md
```

`agent.py` loads these fenced sections:

```text
## System Prompt
## GPT-Live Client Addendum
## Cascaded RAG Addendum
## First Message
```

The deployed default uses `System Prompt`, `GPT-Live Client Addendum` and `First Message`.

### Runtime settings

```text
agents/pr011 - Tatravet/V3.0 Livekit test/settings.json
```

Required production variant:

```json
{
  "pipeline": "gpt-live-client",
  "model": "openai/gpt-live-1",
  "voice": "cedar",
  "delegation": "client",
  "knowledge": "upstash-pr011-faq"
}
```

Dispatch name is separate from display name:

```json
{
  "agent_name": "pr011-tatravet"
}
```

The LiveKit dispatch rule must target exactly:

```text
pr011-tatravet
```

### Shared Upstash client

```text
agents/pr011 - Tatravet/livekit_upstash_faq.py
```

Do not copy this into the V3 folder. `agent.py` intentionally imports the shared module from the PR011 project directory.

Current query contract:

```python
POST {PR011_UPSTASH_VECTOR_REST_URL}/query-data/pr011-faq
Authorization: Bearer {PR011_UPSTASH_VECTOR_REST_TOKEN}

{
    "data": "<complete caller question>",
    "topK": 3,
    "includeData": True,
    "includeMetadata": True,
}
```

The active index must return source metadata:

```text
KB_PR011_Tatravet_v2.md
```

### Dependencies

```text
agents/pr011 - Tatravet/V3.0 Livekit test/requirements.txt
```

Pinned versions:

```text
livekit-agents==1.8.8
livekit-api==1.2.2
python-dotenv==1.2.1
```

Do not upgrade dependencies during first deployment. Version changes would add another benchmark variable.

### Existing retrieval check

```text
livekit/test_upstash_faq.py
```

This verifies that Upstash returns results and that source metadata is exactly `KB_PR011_Tatravet_v2.md`.

## Critical monorepo rule

Use repository root as Railway build context.

Do **not** set Railway Root Directory to:

```text
agents/pr011 - Tatravet/V3.0 Livekit test
```

That isolated folder does not contain the shared module:

```text
agents/pr011 - Tatravet/livekit_upstash_faq.py
```

`agent.py` also computes repository root from its existing path:

```python
ROOT = Path(__file__).resolve().parents[3]
PROJECT_ROOT = Path(__file__).resolve().parent.parent
```

Moving the file or changing build context can break prompt/settings discovery and shared-module imports.

## Railway configuration

### Build command

From repository root:

```bash
pip install --no-cache-dir -r "agents/pr011 - Tatravet/V3.0 Livekit test/requirements.txt"
```

### Start command

```bash
python "agents/pr011 - Tatravet/V3.0 Livekit test/agent.py" start --drain-timeout 600
```

Why `start`:

- production logging;
- no development reload process;
- graceful `SIGINT`/`SIGTERM` behavior;
- worker registers with LiveKit and waits for dispatched jobs.

Why `--drain-timeout 600`:

- deployment shutdown should stop accepting new jobs but give active voice calls up to ten minutes to finish;
- Railway must also grant sufficient process termination grace. Verify Railway's current shutdown policy rather than assuming the CLI flag alone controls platform termination.

Do not use:

```text
lk agent dev
python agent.py dev
```

in Railway production.

### Public networking

No public domain is required for normal agent operation. LiveKit agent servers register outbound over WebSocket and accept jobs from LiveKit through that connection.

LiveKit's agent server exposes an optional health server, normally on `0.0.0.0:8081`. Do not add a public HTTP application merely to satisfy Railway. If Railway requires a health check:

1. inspect installed `livekit-agents==1.8.8` `AgentServer` health-host, health-port and route behavior;
2. make the server listen on Railway's `PORT` only if required;
3. configure Railway's health path to the framework's real endpoint;
4. do not guess the route or add an unrelated web framework.

### Railway service behavior

Configure the service as a continuously running worker:

- no scale-to-zero or sleep during production tests;
- at least one replica;
- restart on failure;
- European region near LiveKit's selected region and Upstash where available;
- enough CPU and memory to avoid event-loop stalls;
- do not expose secrets in build logs or command arguments.

For first low-concurrency testing, one always-on replica is enough. Do not add autoscaling before measuring actual load.

## Required Railway variables

Set these in Railway Variables. Values come from the existing LiveKit Cloud project and Upstash index; never copy placeholders from `.env.example` as real values.

```text
LIVEKIT_URL=wss://<project>.livekit.cloud
LIVEKIT_API_KEY=<secret>
LIVEKIT_API_SECRET=<secret>
PR011_UPSTASH_VECTOR_REST_URL=https://<index>.upstash.io
PR011_UPSTASH_VECTOR_REST_TOKEN=<secret>
PR011_LIVEKIT_VARIANT=gpt-live-client
PYTHONUNBUFFERED=1
```

Optional:

```text
LIVEKIT_LOG_LEVEL=INFO
```

Not required for current GPT-Live Inference route:

```text
OPENAI_API_KEY
DEEPGRAM_API_KEY
GOOGLE_API_KEY
```

LiveKit Inference authenticates through `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET`.

`LIVEKIT_PROJECT_CODE` is not used by this V3 entrypoint.

The agent fails startup when any required LiveKit or PR011 Upstash variable is missing.

## Recommended deployment files

Prefer Railway commands first. Add repository files only when the existing Railway project requires config-as-code.

If a Dockerfile is necessary, keep repository root as build context. Example location:

```text
agents/pr011 - Tatravet/V3.0 Livekit test/Dockerfile.railway
```

Example content:

```dockerfile
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY ["agents/pr011 - Tatravet/V3.0 Livekit test/requirements.txt", "/tmp/requirements.txt"]
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY . /app

CMD ["python", "agents/pr011 - Tatravet/V3.0 Livekit test/agent.py", "start", "--drain-timeout", "600"]
```

Before adding it, verify Railway supports selecting that Dockerfile while retaining repository-root build context. Do not create a Dockerfile if build/start commands already work.

## LiveKit Cloud configuration

### Project

Use the intended LiveKit Cloud project, not an unrelated development project. Recommended separation:

```text
PR011 staging project
PR011 production project
```

Each project has its own:

```text
LIVEKIT_URL
LIVEKIT_API_KEY
LIVEKIT_API_SECRET
```

### Agent registration

Successful Railway startup must log a registered worker with:

```text
agent_name: pr011-tatravet
```

Expected conceptually:

```text
starting worker
HTTP server listening
registered worker
```

Do not consider a successful Railway build sufficient. Worker registration is the deployment success condition.

### Dispatch

Create or update the inbound SIP dispatch rule so calls are sent to:

```text
pr011-tatravet
```

GitHub/Railway deployment does not create dispatch rules automatically.

### Telnyx SIP

Existing telephone path must provide:

1. Telnyx number;
2. Telnyx SIP trunk or connection;
3. LiveKit inbound trunk matching Telnyx authentication/routing;
4. LiveKit dispatch rule targeting `pr011-tatravet`;
5. permitted caller/destination configuration as required by Telnyx.

Do not change the production Telnyx route before the Railway worker is registered and a staging/browser room test succeeds.

## Session behavior that must remain unchanged

### GPT-Live model

```python
inference.DuplexModel(
    model="openai/gpt-live-1",
    voice="cedar",
    extra_kwargs={"delegation": "client"},
)
```

Do not replace this with `RealtimeModel`; GPT-Live is a full-duplex `DuplexModel`.

### Client delegation

GPT-Live client delegation has no normal tool channel. Retrieval is handled by event code:

```python
async def on_enter(self) -> None:
    self.duplex_session.on("delegation_created", self._on_delegation)
```

The current handler:

1. uses `delegation.pending_transcript` as query;
2. calls `query_pr011_faq()`;
3. logs `knowledge_duration_ms`;
4. sends grounding rules through `append_thinking()`;
5. sends fact bodies through `append_commentary()`.

Preserve the split:

```python
self.duplex_session.append_thinking(
    "Answer the caller's factual question directly from the approved facts...",
    delegation_id=delegation.id,
)
self.duplex_session.append_commentary(
    commentary,
    delegation_id=delegation.id,
)
```

Do not put source labels, status narration or prompt instructions into commentary. Commentary is speech-oriented and GPT-Live may verbalize or paraphrase it.

### Knowledge formatting

Upstash records contain internal labels:

```text
Category: ...
Question: ...

<approved answer body>
```

`_format_knowledge()` strips the labels and returns only approved answer bodies. Preserve this behavior.

### Closing

Current code watches for committed assistant farewell and executes:

```python
session.shutdown(drain=True)
```

Session starts with:

```python
room_io.RoomOptions(delete_room_on_close=True)
```

This should let farewell audio finish, close the session and delete the temporary room. Verify over real SIP; do not assume local-console behavior proves telephone hangup behavior.

### Session reports

Current code writes reports to:

```text
.tmp/livekit-session-reports/
```

Railway filesystem is ephemeral. Treat these files as temporary diagnostics only. Production observability should use LiveKit Agent Insights and Railway logs, or later upload reports to durable storage. Do not add durable storage during initial parity deployment unless explicitly requested.

## Deployment procedure

### 1. Verify source before deployment

From repository root:

```bash
python -m py_compile "agents/pr011 - Tatravet/V3.0 Livekit test/agent.py"
```

Run Upstash check in an environment containing the real secrets:

```bash
python livekit/test_upstash_faq.py
```

Expected:

```text
OK: received 3 result(s) from KB_PR011_Tatravet_v2.md
```

Confirm default variant:

```bash
python - <<'PY'
import json
from pathlib import Path
p = Path("agents/pr011 - Tatravet/V3.0 Livekit test/settings.json")
settings = json.loads(p.read_text(encoding="utf-8"))
assert settings["livekit"]["default_variant"] == "gpt-live-client"
print("OK: gpt-live-client")
PY
```

### 2. Configure Railway

- Connect existing Railway service to this GitHub repository and intended branch.
- Keep build context at repository root.
- Set build command and start command from this document.
- Add required variables.
- Choose European region.
- Disable sleep/scale-to-zero for benchmark period.
- Deploy one replica.

### 3. Verify worker registration

Railway logs must show registration, not only process start.

Check:

- no missing-environment-variable error;
- no import error for `livekit_upstash_faq`;
- no prompt/settings file-not-found error;
- no authentication error;
- registered worker name is `pr011-tatravet`;
- worker remains running after startup.

### 4. Browser or Agent Console smoke test

Before SIP routing, dispatch one test room to Railway worker and verify:

- greeting plays once;
- Cedar voice is active;
- Saturday-hours question delegates once;
- Railway log shows `knowledge_status: ok`;
- Upstash duration is logged;
- answer begins with fact, not `Już sprawdzam`, `Sprawdziłem`, source labels or retrieval narration;
- unknown price is not invented;
- session closes after exact farewell.

Use these exact questions:

```text
W jakich godzinach klinika jest otwarta w sobotę?
Czy wykonujecie USG?
Jak przygotować psa do badania krwi?
Ile kosztuje konsultacja?
Czy możecie sprawdzić wolny termin na jutro?
Dziękuję, to wszystko. Do widzenia.
```

Expected knowledge behavior:

1. Saturday: 10:00–15:00.
2. USG: confirmed service.
3. Blood test: 12 hours fasting; small amount of water two hours before; individual instructions take priority.
4. Consultation price: unknown; no invented amount.
5. Tomorrow availability: no calendar access; callback capture may be offered.

### 5. SIP staging test

After browser smoke test passes:

- route a staging Telnyx/LiveKit number or restricted dispatch rule to `pr011-tatravet`;
- place calls from the target Polish caller location;
- verify inbound audio, greeting, retrieval, interruption and hangup;
- inspect Telnyx, LiveKit and Railway logs using room/session/call identifiers;
- preserve call recordings and timestamps for comparison.

### 6. Production latency comparison

Compare Railway LiveKit telephone calls against Vapi embedded-KB call:

```text
Vapi call: 01a209e2-37a7-7dde-88ca-233836527e40
Assistant: 7aea1b2d-bb74-440d-9836-76fe2eb3076e
Voice/model: Cedar / gpt-live-1
```

Primary boundary:

```text
end of caller speech
→ first audible substantive answer
```

Record separately:

- Telnyx/PSTN transport;
- end-of-turn delay;
- `knowledge_duration_ms`;
- delegation-to-commentary timing if available;
- first agent audio;
- answer duration;
- factual correctness;
- unsupported facts;
- preamble/status narration;
- interruptions;
- call completion;
- total cost.

Use at least five identical calls per variant for an initial p50/p95 comparison. Alternate Vapi and LiveKit call order within the same time window.

Do not combine local Console numbers with telephone/SIP numbers in one latency distribution.

## Rollback

Before changing production routing, preserve current Vapi route and existing Telnyx configuration.

Rollback must be possible by restoring the prior Telnyx/Vapi destination or LiveKit dispatch rule without a code deployment.

If Railway worker is unhealthy:

1. stop sending new dispatches to `pr011-tatravet`;
2. leave existing calls to finish where possible;
3. restore previous route;
4. keep Railway logs and LiveKit session IDs;
5. fix in staging before retrying.

Do not delete Vapi assistant, LiveKit project, SIP trunk or Upstash index during migration testing.

## Failure checklist

### Worker exits immediately

Check required variables:

```text
LIVEKIT_URL
LIVEKIT_API_KEY
LIVEKIT_API_SECRET
PR011_UPSTASH_VECTOR_REST_URL
PR011_UPSTASH_VECTOR_REST_TOKEN
```

### `ModuleNotFoundError: livekit_upstash_faq`

Build context or repository layout is wrong. Use repository root and preserve:

```text
agents/pr011 - Tatravet/livekit_upstash_faq.py
```

### Worker starts but receives no calls

Check:

- registered agent name;
- dispatch rule target;
- LiveKit project credentials;
- inbound trunk and dispatch rule belong to same project;
- Railway worker is continuously connected;
- development and production deployments are not mixed.

### Retrieval fails

Check:

- Upstash URL/token;
- namespace path `pr011-faq`;
- HTTP response status;
- source metadata;
- Railway egress/DNS;
- `knowledge_status` and traceback in logs.

Agent should use safe no-confirmed-information fallback rather than invent facts.

### Agent says strange retrieval wording

Verify current code still:

- strips `Category` and `Question` labels;
- puts instructions in `append_thinking()`;
- puts only fact bodies in `append_commentary()`;
- contains no `Już sprawdzam` instruction;
- runs a fresh process after prompt/code changes.

### Active calls drop during deploy

Railway termination grace is too short, process receives forced termination, or deployment strategy does not allow draining. Increase grace where Railway supports it and keep `--drain-timeout 600`.

### Reports disappear

Expected on Railway ephemeral storage. Use LiveKit Agent Insights/Railway logs or add explicit durable upload as a later task.

## Definition of done

Deployment is complete only when all are true:

- Railway build succeeds from repository root.
- Production process stays alive.
- Worker registers with LiveKit as `pr011-tatravet`.
- `PR011_LIVEKIT_VARIANT=gpt-live-client` is active.
- Upstash check returns `KB_PR011_Tatravet_v2.md` results.
- Browser/room smoke test passes all five factual/safety cases.
- Railway logs show successful client delegation and Upstash timing.
- No retrieval preamble or internal metadata is spoken.
- SIP test call reaches Railway worker.
- Greeting, factual answers, callback limitation and closing work over telephone.
- Existing Vapi route remains available for rollback.
- Deployment details and measured call IDs are recorded in project documentation.

## References

Repository:

- `agents/pr011 - Tatravet/V3.0 Livekit test/agent.py`
- `agents/pr011 - Tatravet/V3.0 Livekit test/prompt.md`
- `agents/pr011 - Tatravet/V3.0 Livekit test/settings.json`
- `agents/pr011 - Tatravet/V3.0 Livekit test/requirements.txt`
- `agents/pr011 - Tatravet/livekit_upstash_faq.py`
- `livekit/test_upstash_faq.py`
- `agents/pr011 - Tatravet/V3.0 Livekit test/BENCHMARK_PLAN.md`
- `knowledge/learnings.md`
- `.env.example`

Official documentation:

- LiveKit self-hosted agents: https://docs.livekit.io/deploy/custom/deployments/
- LiveKit job lifecycle and shutdown: https://docs.livekit.io/agents/server/job/
- LiveKit GPT-Live client delegation: https://docs.livekit.io/agents/models/realtime/gpt-live/
- LiveKit Telnyx SIP setup: https://docs.livekit.io/telephony/start/providers/telnyx/
- Railway monorepos: https://docs.railway.com/guides/monorepo
- Railway start commands: https://docs.railway.com/guides/start-command
- Railway health checks: https://docs.railway.com/guides/healthchecks
