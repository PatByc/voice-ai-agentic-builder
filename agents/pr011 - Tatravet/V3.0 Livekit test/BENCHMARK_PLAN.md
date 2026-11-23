# PR011 latency benchmark plan

## Goal

Compare knowledge-answer time to first response audio across Vapi and LiveKit while preserving the approved Tatravet facts and safety rules from `../V2.0/`.

Railway is not required for this test. Run the LiveKit worker locally while the computer remains online. The worker registers outbound with LiveKit Cloud and can receive Agent Console or SIP-dispatched calls.

## Compared variants

| ID | Runtime | Voice pipeline | Knowledge path | Purpose |
|---|---|---|---|---|
| VAPI-BASE | Vapi | GPT-Live | speaker → reasoner → Upstash → reasoner → speaker | Existing measured baseline |
| VAPI-PROMPT | Vapi | GPT-Live | exact `KB_PR011_Tatravet_v2.md` injected into speaker prompt | Measure Vapi without FAQ delegation |
| LK-CLIENT | LiveKit local | GPT-Live, `delegation=client` | delegation event → direct Upstash → commentary | Remove the backend reasoner model |
| LK-CASCADE | LiveKit local | Deepgram STT → text LLM → Gemini TTS | Upstash in `on_user_turn_completed` before LLM generation | Test traditional auditable pipeline without a tool-call round trip |
| VAPI-VOICE-HIST | Vapi | GPT-Live | Existing Cedar and Marin calls | Historical voice evidence only |

## Important comparison rule

The old Cedar/Marin calls changed the voice and captured useful behavior, but they are not a controlled comparison against LiveKit. Use them to understand voice quality, speaking speed and artifacts. Do not use them alone to attribute an architecture-level latency difference.

The controlled benchmark must use the same caller wording, call order, knowledge corpus and measurement boundaries for every current variant.

## LiveKit variants

Select the local variant with `PR011_LIVEKIT_VARIANT`.

PowerShell:

```powershell
$env:PR011_LIVEKIT_VARIANT = "gpt-live-client"
$env:PR011_LIVEKIT_VARIANT = "cascade-rag"
```

Git Bash:

```bash
export PR011_LIVEKIT_VARIANT=gpt-live-client
export PR011_LIVEKIT_VARIANT=cascade-rag
```

Default: `gpt-live-client`.

### LK-CLIENT

`openai/gpt-live-1` runs through LiveKit Inference with Cedar and `delegation="client"`. The runtime never reads a local KB document; it queries the existing Upstash index using `PR011_UPSTASH_VECTOR_REST_URL` and `PR011_UPSTASH_VECTOR_REST_TOKEN`.

When GPT-Live delegates a factual question:

1. no backend Responses/reasoner model runs;
2. local code queries the existing PR011 Upstash index directly;
3. the retrieved approved context is appended to the same duplex session as commentary;
4. GPT-Live speaks the answer.

This isolates the effect of removing Vapi's backend reasoner passes while retaining GPT-Live and the current Upstash retrieval service.

### LK-CASCADE

The initial comparison stack is:

```text
Deepgram Nova-3 (`pl`)
→ pre-generation Upstash lookup
→ OpenAI GPT-5.6 Luna
→ Gemini 3.8 Flash-Lite TTS, Aoede (`pl`)
```

The lookup runs in `on_user_turn_completed`, before the LLM reply. It queries the same Upstash index and credentials as `LK-CLIENT`; it does not read a local KB document. This avoids the extra LLM → tool → LLM round trip of ordinary tool calling.

This variant changes the voice pipeline and therefore is a candidate architecture test, not a one-variable comparison with GPT-Live.

## Local prerequisites

- `.venv` dependencies from this folder's `requirements.txt`;
- `LIVEKIT_URL`;
- `LIVEKIT_API_KEY`;
- `LIVEKIT_API_SECRET`;
- `PR011_UPSTASH_VECTOR_REST_URL`;
- `PR011_UPSTASH_VECTOR_REST_TOKEN`;
- a linked LiveKit Cloud project;
- for telephone tests, the Telnyx trunk, LiveKit inbound trunk and dispatch rule.

Browser/Agent Console testing does not require Telnyx. Telephone-path testing does.

## Running locally

Run the CLI from the LiveKit test folder so it detects the local `requirements.txt` project manifest:

```powershell
cd "agents/pr011 - Tatravet/V3.0 Livekit test"
```

Development mode registers a temporary development deployment:

```text
lk agent dev agent.py
```

For a persistent local process without hot reload:

```text
lk agent start agent.py
```

Use the Agent Console link printed by `lk agent dev` for an initial audio test. Configure SIP dispatch to the matching development/agent target before telephone tests.

## Fixed caller questions

Use identical wording and order:

1. `W jakich godzinach klinika jest otwarta w sobotę?`
2. `Czy wykonujecie USG?`
3. `Jak przygotować psa do badania krwi?`
4. `Ile kosztuje konsultacja?`
5. `Czy możecie sprawdzić wolny termin na jutro?`

These cover direct facts, services, safety-sensitive preparation, an unknown price and a known capability limitation.

## Run count

- Smoke test: 2 calls per new variant.
- Initial comparison: at least 5 successful calls per variant.
- Decision-quality comparison: at least 20 representative calls per finalist.

Alternate variant order to reduce provider-time and network-time bias.

## Primary timing boundary

Measure:

```text
end of caller speech
→ first audible byte of the agent's substantive answer
```

Do not stop timing at the retrieval result, text token or model completion. The caller experiences first response audio.

Also capture:

- end-of-turn detection delay;
- STT finalization time for the cascaded variant;
- Upstash duration;
- backend/model TTFT;
- TTS TTFB for the cascaded variant;
- delegation-to-commentary duration for GPT-Live client mode;
- total answer completion time.

Report p50 and p95, not only averages.

## Quality checks

For every answer record:

- factually correct;
- grounded in approved facts;
- unsupported fact or blending;
- correct refusal for unknown price;
- correct calendar limitation;
- preparation instructions unchanged;
- Polish pronunciation quality;
- interruption behavior;
- trailing audio artifacts;
- whether the model delegated when expected.

## Knowledge-corpus control

Verified on 2026-11-23: the active Upstash `pr011-faq` query results identify `KB_PR011_Tatravet_v2.md` as their source. `VAPI-PROMPT` injects that same local source document exactly; both LiveKit variants access it only through Upstash.

Keep this split fixed during the benchmark:

- `VAPI-PROMPT`: local document embedded in speaker instructions, no FAQ delegation;
- `LK-CLIENT`: Upstash query through client delegation;
- `LK-CASCADE`: Upstash query in `on_user_turn_completed`;
- no LiveKit runtime loads `KB_PR011_Tatravet_v2.md` directly.

Before every benchmark batch, run `livekit/test_upstash_faq.py` and confirm returned metadata still names `KB_PR011_Tatravet_v2.md`.

## Interpretation

- `VAPI-PROMPT` measures the lower-latency tactical Vapi option, not the long-term KB architecture.
- `LK-CLIENT` tests whether removing the backend reasoner makes GPT-Live knowledge responses faster and more stable.
- `LK-CASCADE` tests a more controllable long-term pipeline with explicit text and per-stage observability.
- Historical voice results remain useful for voice selection but cannot substitute for rerunning the selected voice under the final architecture.
