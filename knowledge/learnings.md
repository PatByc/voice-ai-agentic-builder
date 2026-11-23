# Learnings

Practical findings from building and testing voice AI agents. Facts we've confirmed through real use — not theory.

---

## STT / Transcribers

### Deepgram nova-3 still drops digits in Polish phone number dictation
- **Discovered:** 2026-08-27
- **Agent:** JETSET CLINIC Recepcja (VAPI)
- **Config:** Deepgram nova-3, language: pl
- **What happened:** Caller dictated a full 9-digit Polish phone number. STT transcribed only partial digits ("7 6, 9, 1" from a 9-digit number). On second attempt with country code, agent heard "plus T4870091" — completely garbled. Multiple retries never produced a usable number.
- **Root cause:** Combination of (1) missing endpointing config — no `transcriptionEndpointingPlan` set, so no `onNumberSeconds` delay, and (2) STT struggling with digit-by-digit Polish dictation even on nova-3.
- **Fix:** Add `transcriptionEndpointingPlan` with `onNumberSeconds: 1.5` to give the STT time to accumulate digits. If still failing, test Deepgram Flux model which has built-in end-of-turn detection.
- **Status:** Not yet retested with endpointing config

### General: avoid collecting phone numbers and emails over voice
- Phone numbers and email addresses are high-error-rate data over voice AI — STT struggles with digit sequences and spelled-out characters.
- For inbound calls, caller ID is already captured by the phone system via `{{customer.number}}` — no need to re-collect.
- For emails, same problem: spelling out characters is unreliable. Better to say "Pan Mecenas skontaktuje sie telefonicznie."
- Do NOT ask for country code prefix — Polish callers assume 9-digit local format. Asking for "kierunkowy" confuses both the caller and the STT.

### Workarounds for phone number collection (if absolutely needed)
1. **DTMF / Keypad** (phone calls only) — `keypadInputPlan: { enabled: true, timeoutSeconds: 3, delimiters: ['#'] }`. Bypasses STT entirely. Agent says "Prosze wpisac numer na klawiaturze i potwierdzic kratka." Only works on telephony, not web widgets.
2. **SMS follow-up** — Use `{{customer.number}}` to send an SMS with a link to a form after the call. Requires Twilio integration.
3. **Deepgram Keyterm Prompting** — Boost Polish digit words ("jeden", "dwa", "trzy"...) via `keyterms` config. Claims up to 90% keyword recall improvement. Available for nova-3 and Flux.
4. **Skip it** — Use caller ID for inbound. Best option.

---

## LLMs

### Gender detection in Polish — LLM misses verb-form cues
- **Discovered:** 2026-08-27
- **Agent:** JETSET CLINIC Recepcja (VAPI, gpt-4o-mini)
- **What happened:** Caller said "chcialbym" (masculine verb form) in the first sentence. Agent defaulted to Pani/Pania forms anyway, mixing Pan and Pani in the same sentence ("Czy ma pani pan na myśli").
- **Root cause:** The prompt said "use appropriate Pan/Pani based on context" — too vague. The LLM needs explicit instruction to detect gender from Polish verb endings.
- **Fix:** Add explicit prompt instruction: "Detect the caller's gender from Polish verb forms in their FIRST utterance (chcialbym = male, chcialabym = female). Once detected, use Pan/Pani consistently for the entire call."

### gpt-4o-mini has poor Polish grammar — use gpt-4o for Polish agents
- **Discovered:** 2026-08-28
- **Agent:** JETSET CLINIC Recepcja (VAPI, gpt-4o-mini)
- **What happened:** Agent said "Dzień dobry Panie" (vocative) instead of correct "Dzień dobry Panu" (dative). Polish grammatical cases were wrong.
- **Root cause:** gpt-4o-mini doesn't handle Polish declension/cases well enough for professional voice agents. Vocative vs dative, accusative vs instrumental — these matter in Polish and the mini model gets them wrong.
- **Fix:** Switch to **gpt-4o** — noticeably better Polish grammar. The cost increase is worth it for agents that speak Polish professionally.
- **Tradeoff:** gpt-4o is more expensive per token, but for short voice responses (1-2 sentences) the cost difference is small.

### GPT-Live PR011: FAQ latency comes from two reasoner passes, not Upstash
- **Discovered:** 2026-11-21
- **Agent:** PR011 Tatravet V2.0 (Vapi, `gpt-live-1` speaker + `gpt-5.6-sol` reasoner)
- **Architecture:** A factual question is delegated by the speaker. The reasoner runs once to select/build the tool call, Upstash Vector embeds and searches, then the reasoner runs again to synthesize the answer.
- **Direct Upstash benchmark:** `topK: 1` median was 491 ms; `topK: 3` median was 504 ms. Returning three matches added no meaningful search latency. Keep `topK: 3` for retrieval quality unless answer-quality testing supports reducing it.
- **Production tool timing:** Upstash stayed stable at approximately 603–670 ms across calls. Search delegations varied from approximately 3.3 to 6.0 seconds because the pre-tool and post-tool reasoner passes varied.
- **Observed `xhigh` fast calls:** FAQ delegation completed in 3.30–3.49 seconds, with approximately 0.6 seconds spent in Upstash.
- **Observed slow calls:** FAQ delegation completed in 5.06–6.01 seconds while Upstash still took only 0.64–0.67 seconds. One unclear request took 9.58 seconds in the reasoner without calling Upstash at all.
- **Reasoning-effort test:** In the tested calls, `xhigh` produced the best combination of response quality and observed speed. `high` averaged approximately 4.08 seconds across three FAQ searches; `medium` averaged approximately 4.87 seconds. This is a small, nondeterministic sample, not proof that `xhigh` is intrinsically faster.
- **Quality finding:** `high` added an unsupported explanation that the USG price “depends on scope.” `medium` used the safer confirmed-information fallback but offered no latency benefit.
- **Context reuse:** Follow-up “A we wtorki?” reused already retrieved opening-hours information without another Upstash call. Avoid unnecessary retrieval for facts established in the same call.
- **Optimization priority:** Keep `xhigh` and `topK: 3` for now. First remove unnecessary delegations, especially calendar limitations and callback policy that the speaker can answer directly.
- **Testing rule:** Change one variable at a time and repeat identical questions over several calls. Model latency has substantial run-to-run variance.

### GPT-Live knowledge strategy: choose direct context, hybrid or retrieval by measured token budget
- **Researched:** 2026-11-23
- **Context:** PR011 Tatravet latency optimization across Vapi, OpenAI and LiveKit documentation.

#### Use tokens as the primary measurement
- Character count is useful as a build-time warning, but it is not the model constraint. Tokenization varies by language, model and encoding.
- OpenAI's rough “four characters per token” estimate applies to common English text only. Do not treat it as a Polish conversion rule. Use the provider's tokenizer on representative Polish text when making a final decision.
- Until exact tokenization is automated, use a conservative planning range of **3–4 characters per token** for PR011 and label it an estimate.
- Source: [OpenAI — Understanding and counting tokens](https://help.openai.com/en/articles/4936856-understanding-and-counting-tokens).

#### Documented GPT-Live limits
- GPT-Live's complete context window is **128,000 tokens**, including instructions, conversation text and audio tokens that may not appear in transcripts.
- Session instructions support up to **16,384 tokens**.
- Startup history supports up to **128 messages and 8,192 combined tokens**.
- LiveKit's GPT-Live integration exposes the same startup-history limit and drops the oldest messages first when it is exceeded.
- The 16,384-token instruction limit is a technical ceiling, not a sensible production target. A prompt can fit and still become slower, less precise or more likely to blend similar facts.
- Sources: [OpenAI — Managing GPT-Live sessions](https://developers.openai.com/api/docs/guides/live-conversations), [LiveKit — OpenAI GPT-Live](https://docs.livekit.io/agents/models/realtime/gpt-live/).

#### Vapi does not publish a numeric routing threshold
- Vapi documents no hard character/token cap for `model.speaker.instructions` or `model.reasoner.instructions`, and no official number at which static facts should move to retrieval.
- Vapi's directional guidance is: every prompt token can add latency; put a few stable facts directly in the speaker prompt; use retrieval for a larger or changing body of content.
- Vapi native Knowledge Bases and the Query Tool are not available to GPT-Live. GPT-Live retrieval must use a function, API request or MCP tool, and the tool result always flows back through the reasoner before the speaker can use it.
- Sources: [Vapi — GPT-Live configuration](https://docs.vapi.ai/gpt-live/configuration), [Vapi — Migrate to GPT-Live](https://docs.vapi.ai/gpt-live/migrate), [Vapi — GPT-Live tools](https://docs.vapi.ai/gpt-live/tools), [Vapi — Prompting guide](https://docs.vapi.ai/prompting-guide).

#### PR011 measured size

| Content | Characters | Words |
| --- | ---: | ---: |
| Current speaker prompt | 8,097 | 1,250 |
| Current reasoner prompt | 3,941 | 606 |
| Tatravet KB | 5,307 | 702 |
| Speaker prompt + raw KB | 13,405 | 1,952 |

- A conservative 3–4 characters/token estimate puts the combined speaker prompt and raw KB at approximately **3,350–4,470 tokens**, around 20–27% of the documented instruction ceiling.
- PR011 therefore fits technically, but the raw Markdown should not be pasted unchanged. Convert it into compact, non-duplicated, approved facts and target roughly **10,000–12,000 total characters** where possible.
- Do not repeat the same facts in speaker instructions, reasoner instructions, examples and tool descriptions. Duplication consumes context and creates contradiction risk.

#### Internal routing thresholds
- These are OptimizeLabs starting thresholds for testing, **not OpenAI or Vapi guarantees**.

**Path A — direct speaker context**
- Static KB at or below approximately **8,000 characters**.
- Total speaker prompt at or below approximately **15,000 characters** or **4,500 estimated tokens**.
- Facts are short, stable, non-overlapping and safe to expose to every call.
- Missing facts have a safe fallback such as “Nie mam potwierdzonej informacji.”
- Typical content: opening hours, address, phone number, confirmed services and stable organizational policies.
- PR011 currently belongs in this path.

**Path B — hybrid context plus retrieval fallback**
- KB approximately **8,000–25,000 characters**, or total possible speaker prompt approximately **15,000–30,000 characters**.
- Put the highest-frequency stable facts directly in the speaker prompt.
- Retrieve uncommon procedures, detailed preparation instructions, long price lists and frequently changing details.
- The goal is to make the majority of calls direct while preserving long-tail coverage.

**Path C — retrieval/client-managed data**
- KB above approximately **25,000 characters**, knowledge above roughly **6,000–8,000 estimated tokens**, or measured prompt degradation before those thresholds.
- Use this path regardless of size for calendars, patient records, customer-specific information, inventory, permissions, authorization, frequently changing data or many semantically similar entries.
- Exact model-token counts and benchmark results override character-based thresholds.

#### Recommended PR011 direct-context design
- Add a compact `Approved Tatravet facts` section to the speaker prompt.
- Instruct the speaker to answer directly only when the requested fact is explicitly present.
- Keep calendar access, records, results, medical safety and callback limitations as direct behavioral rules, not FAQ searches.
- If a price or other fact is absent, do not search when the KB is already known not to contain it; return the confirmed-information fallback.
- Keep Upstash only as a fallback for uncommon facts during the first migration test.
- A suitable structure is:
  ```text
  # Approved Tatravet facts
  ## Opening hours
  - Monday–Friday: 08:00–20:00.
  - Saturday: 10:00–15:00.

  ## Confirmed services
  - Tatravet performs animal ultrasound examinations.

  ## Usage rules
  - Answer directly only from facts explicitly listed here.
  - Do not infer prices, availability or medical suitability.
  - If a fact is absent, say it is not confirmed or use the FAQ fallback.
  ```

#### Lower-latency dynamic alternatives

**OpenAI/LiveKit GPT-Live client delegation**
- OpenAI and LiveKit support `delegation="client"`. The application receives the delegation, performs its own lookup and sends verified content back through commentary.
- In this mode **no backend Responses reasoner runs**. A concise lookup result can be returned directly to GPT-Live without another backend model call rewriting it.
- This can reduce the path to: speaker delegation → local/Upstash lookup → commentary → speech.
- Vapi does not currently expose OpenAI client delegation, so this requires LiveKit or a direct OpenAI integration.
- Sources: [OpenAI — GPT-Live client delegation](https://developers.openai.com/api/docs/guides/live-delegation?delegation-mode=client), [LiveKit — GPT-Live delegation](https://docs.livekit.io/agents/models/realtime/gpt-live/).

**Local in-memory FAQ lookup**
- PR011 contains only 58 lines and about 700 words. A structured dictionary, keyword/fuzzy matcher, BM25 index or small local embedding index may be sufficient.
- Loading static knowledge during worker prewarm removes the approximately 600 ms Upstash network/embedding step.
- Combined with client delegation, the lookup itself can be near-instant and deterministic.

**LiveKit STT–LLM–TTS pre-generation RAG**
- LiveKit's `on_user_turn_completed` hook can retrieve context after transcription but before LLM generation.
- This avoids the extra model/tool/model round trips: STT → lookup → one LLM response → TTS.
- It is available for STT–LLM–TTS pipelines with a text user turn, not GPT-Live's native duplex pipeline.
- Source: [LiveKit — External data and RAG](https://docs.livekit.io/agents/logic/external-data/).

**Vapi `append-context` workaround**
- GPT-Live live-call control can POST `append-context` to `monitor.controlUrl` with `commentary`, `thinking` or `instructions`.
- A custom backend could receive transcript events, retrieve an answer and append commentary directly to the speaker.
- This is not equivalent to native client delegation: Vapi GPT-Live does not support HTTP `say` or `add-message`, and a successful context append does not guarantee exact wording, immediate speech or completed playback.
- Treat this as a prototype path, not the default architecture.
- Source: [Vapi — GPT-Live configuration](https://docs.vapi.ai/gpt-live/configuration).

#### Approaches that do not solve the main bottleneck
- Reducing `topK` from 3 to 1 did not improve measured Upstash latency.
- Semantic caching can save approximately 600 ms of retrieval but leaves both reasoner passes in place.
- OpenAI File Search or another hosted retrieval tool can simplify infrastructure, but under Responses delegation it still retains backend reasoning and tool continuation. It does not remove the two-stage architecture.
- Prompt caching can reduce repeated-prefix processing where supported, but it does not remove sequential model and tool requests.
- Switching vector databases is unlikely to fix a latency path dominated by reasoner inference.

#### Required prompt-size benchmark
- Documentation provides hard limits but no universal performance cutoff. Establish the real threshold experimentally with controlled prompt-size variants:
  1. Current prompt with no embedded KB.
  2. Current prompt plus compact PR011 KB, approximately 5,000 characters.
  3. Prompt with approximately 15,000 characters of approved facts.
  4. Prompt with approximately 25,000 characters of approved facts.
- Run at least five identical calls per variant and compare p50 and p95, not the fastest call.
- Measure:
  - greeting startup time;
  - end-of-user-speech to direct answer start;
  - latency of unrelated conversational turns;
  - factual accuracy;
  - unsupported-fact rate;
  - blending of similar facts;
  - delegation rate for facts already present in context;
  - interruption and turn-boundary quality.
- Initial acceptance criteria:
  - FAQ factual accuracy at least **95%**;
  - **zero unsupported facts**;
  - common-FAQ delegation rate **0%**;
  - unrelated-turn p50 regression no more than **300 ms**;
  - unrelated-turn p95 regression no more than **500 ms**.
- If direct context fails these criteria, move to hybrid before defaulting to full retrieval.

### PR011 experiment: embedded Vapi knowledge removed the reasoner pause; LiveKit client delegation also removed the multi-second pause
- **Tested:** 2026-11-23
- **Scope:** One Vapi embedded-KB call and two local LiveKit GPT-Live recordings. This is directional evidence, not a p50/p95 benchmark. The planned LiveKit STT–LLM–TTS variant was configured but **not tested**.

#### Controlled knowledge corpus
- The Vapi in-prompt variant embedded the exact contents of `agents/pr011 - Tatravet/V2.0/KB_PR011_Tatravet_v2.md` in the speaker instructions and removed FAQ-tool references from both speaker and reasoner instructions.
- The LiveKit variant did not read the Markdown file. It queried the existing Upstash `pr011-faq` index with `topK: 3` through `PR011_UPSTASH_VECTOR_REST_URL` and `PR011_UPSTASH_VECTOR_REST_TOKEN`.
- A live Upstash check returned three results whose source metadata was `KB_PR011_Tatravet_v2.md`, confirming both variants used the same source corpus through different delivery paths.

#### Vapi embedded-KB result
- **Assistant:** `7aea1b2d-bb74-440d-9836-76fe2eb3076e`.
- **Call:** `01a209e2-37a7-7dde-88ca-233836527e40`.
- **Configuration:** Cedar, `gpt-live-1`, full approved KB in speaker prompt, no FAQ retrieval for factual questions.
- **Call result:** 73.03 seconds, `$0.1376`, caller-ended.
- **Response onset:** Four tested answers began within the final approximately 200 ms transcript chunk; the fifth began at approximately the detected speech-end boundary. Report this as **approximately 0–0.2 seconds within measurement resolution**, not as negative latency.
- **Answer durations:** Saturday hours 4.0 s; USG 2.4 s; blood-test preparation 11.6 s; unknown consultation price 4.4 s; calendar limitation 8.2 s.
- **Speaking rate:** 164–250 WPM; median 191 WPM.
- **Quality:** All five answers were correct. The model gave Saturday hours, confirmed USG, preserved the 12-hour fasting and water instructions, declined to invent a consultation price, and stated that it had no calendar access while offering callback capture.
- **Behavior:** No visible retrieval pause, trailing breath artifact, interruption problem or turn-boundary problem was observed.
- **Voice comparison:** Latest Cedar greeting was 12.2 s versus previous Cedar 13.2 s and Marin 15.4 s. Latest Saturday answer was 4.0 s versus previous Cedar 3.6 s and Marin 4.2 s. Cedar remains the preferred tested voice, but these are single samples.

#### LiveKit GPT-Live client-delegation result
- **Architecture:** Local LiveKit worker, `openai/gpt-live-1`, Cedar, `delegation="client"`, direct Upstash query, retrieved facts returned to the same duplex session as commentary. No backend Responses reasoner ran.
- **Artifacts:** `agents/pr011 - Tatravet/V3.0 Livekit test/console-recordings/session-11-23-203240/audio.ogg` and `session-11-23-204040/audio.ogg`.
- **Observed behavior:** Answers felt immediate and direct, with no acknowledgement followed by the old 3–4 second reasoner pause. This is the reliable qualitative result.
- **Waveform estimate:** On the second stereo recording, a raw last-audible-caller-phoneme to first-audible-agent-phoneme analysis produced gaps of approximately 1.4–1.8 s, median 1.52 s. Do not compare this number directly with Vapi's approximately 0–0.2 s platform timestamp because the boundaries and methods differ. The waveform method includes endpointing, local console transport, Upstash, commentary injection and response generation.
- **Measurement limitation:** The first implementation did not close the LiveKit session after speaking the farewell. The recording was preserved, but `on_session_end` did not produce a structured session report, so finalized per-turn SDK metrics and complete usage data were not captured. This does not invalidate caller-observed audio timing, but it prevents a clean internal stage breakdown.
- **Closing finding:** Saying a farewell does not close a LiveKit session. The benchmark agent now detects the committed farewell, calls `session.shutdown(drain=True)` and sets `delete_room_on_close=True`. Closing was not part of the FAQ latency hypothesis.

#### Interpretation
- The experiment confirms the original diagnosis: Vapi's multi-second FAQ delay came primarily from the speaker → reasoner → tool → reasoner → speaker architecture, not from Upstash alone.
- Embedding this small static KB in the Vapi speaker prompt produced the fastest observed response and preserved correctness in this single call.
- LiveKit client delegation preserved sustainable semantic retrieval while removing both backend reasoner passes and the obvious multi-second retrieval pause.
- These results do not establish production superiority. Vapi and LiveKit timing used different transports and timestamp methods, and neither new variant was repeated enough for p50/p95.
- **Untested path:** The configured LiveKit cascade—Deepgram Nova-3 Polish STT → Upstash in `on_user_turn_completed` → GPT-5.6 Luna → Gemini 3.8 Flash-Lite TTS/Aoede—was deliberately not run. Make no claims about its latency, quality or cost.
- **Current practical decision:** For the small PR011 static KB, embedded Vapi context is a valid low-latency option. For larger or changing KBs, LiveKit GPT-Live client delegation remains the tested long-term candidate. Repeat identical calls and use one timing method before making a migration decision.

### Voice-agent service regions: placement changes latency, but architecture usually matters more
- **Documented:** 2026-11-23
- **Services in scope:** Telnyx, Vapi, LiveKit Cloud, Railway and Upstash Vector.
- **Core rule:** Every synchronous network boundary on the response path adds round-trip time and jitter. Sequential calls add their delays; parallel or off-critical-path work does not add in the same way. Region placement cannot be reduced to one universal millisecond figure because caller location, Internet routing, provider load, cold starts and model queueing vary.

#### Actual request paths

**Vapi with embedded KB**
```text
caller → Telnyx/PSTN → Vapi/media edge → GPT-Live → caller
```
- Upstash and Railway are not on the factual-answer critical path.
- This path produced the fastest observed PR011 answer onset because the model already had the facts and made no retrieval or reasoner request.
- Vapi controls most runtime placement. Unless a contract or product setting exposes region pinning, treat its internal media/model route as managed and verify it by calls from the target market rather than assuming a region.

**Vapi with reasoner and Upstash**
```text
caller → Telnyx/PSTN → Vapi → GPT-Live speaker
       → backend reasoner → Upstash → backend reasoner → speaker → caller
```
- Upstash added approximately 0.6 s in measured calls, but two variable reasoner passes raised the complete delegated path to approximately 3.3–6.0 s.
- Moving only Upstash closer could save part of its approximately 0.6 s, not remove model queueing or either reasoner pass.

**Local LiveKit GPT-Live test**
```text
local microphone → local worker → LiveKit Cloud/Inference
                 → local worker → Upstash → LiveKit GPT-Live → local speaker
```
- A local worker does **not** mean zero cloud latency. GPT-Live inference and Upstash remain cloud services, and audio/control traffic still crosses the local Internet connection.
- The tested worker registered with LiveKit in `Germany 2`. Upstash queries took approximately 435–520 ms in observed local logs.
- Local Console removes PSTN, Telnyx SIP and a remote worker deployment, so it approximates model/retrieval behavior but is not a production telephone benchmark.

**Production LiveKit with Railway**
```text
caller → Telnyx/PSTN → LiveKit Cloud SIP/media
       ↔ Railway worker → Upstash and LiveKit Inference → caller
```
- Railway region affects worker-to-LiveKit and worker-to-Upstash round trips. Place the worker near the LiveKit media/inference region and the primary Upstash region, with caller geography as the final constraint.
- An always-running worker should add ordinary network-hop latency, not seconds. A sleeping service, cold start, overloaded CPU, blocked event loop or distant region can add much more and must be measured.
- Existing Railway account cost is irrelevant to latency; service region, sleep behavior, CPU/memory pressure and network path are relevant.

**Production LiveKit with LiveKit-hosted worker**
```text
caller → Telnyx/PSTN → LiveKit Cloud SIP/media and hosted worker
       → Upstash and LiveKit Inference → caller
```
- Hosting the worker with LiveKit may reduce or stabilize worker-to-media/inference networking and removes Railway cold-start/runtime variables.
- Upstash remains an external hop. LiveKit hosting does not make retrieval local unless the knowledge service is also colocated or replaced.
- Treat this as a separate deployment variant with different cost and operations, not as automatically faster without measurements.

#### Service-by-service latency role

| Service | What its location affects | When it is on the critical path |
| --- | --- | --- |
| **Telnyx** | PSTN ingress/egress, SIP routing and caller-to-platform media path | Every telephone call; absent from local Agent Console |
| **Vapi** | Managed media orchestration and connections to model/tool providers | Every Vapi call; exact internal placement is mostly platform-managed |
| **LiveKit Cloud** | SIP ingress, room/media edge, agent dispatch and LiveKit Inference path | Every LiveKit Cloud call |
| **Railway** | Worker-to-LiveKit, worker-to-Upstash and business-tool round trips; cold starts and compute contention | Only when agent worker or tools run there |
| **Upstash** | Query request, embedding/search service and result return | Retrieval variants only; absent from embedded-KB answers |

#### Expected scale of region effects
- Do not assign a fixed “Europe adds X ms” value without a controlled measurement. Healthy nearby-region network hops are generally a sub-second concern; cold starts, provider queueing and sequential model calls can be much larger.
- Region mismatch becomes more expensive when the same turn crosses regions repeatedly. A single extra round trip may be modest; speaker → reasoner → database → reasoner chains compound network and inference delays.
- Telephone latency has a caller-side component that worker deployment cannot remove: handset network, PSTN route, carrier transcoding and Telnyx SIP ingress.
- Model inference often has more variance than pure network travel. PR011 demonstrated this directly: Upstash remained around 0.6 s while complete Vapi delegations ranged from roughly 3.3 to 6.0 s.

#### Placement and benchmark policy
1. Record caller location, carrier, Telnyx route, LiveKit region, worker region and Upstash region for every production benchmark.
2. Keep services in the same broad geography where possible; for Polish callers, start with European placement.
3. Keep workers warm and monitor CPU, event-loop stalls, reconnects and cold starts.
4. Measure each boundary separately where telemetry permits: speech end, endpointing, retrieval, model first token/audio and caller playback.
5. Report local WebRTC/Console and telephone/SIP results separately.
6. Compare deployed variants with the same caller, questions, time window and transport; alternate call order to reduce provider-load bias.
7. Report p50 and p95 from repeated calls. One fast call proves feasibility, not stable latency.
8. Optimize architecture before chasing regions: removing an entire reasoner pass or retrieval call usually has a larger and more reliable effect than moving an already-nearby service.

#### Current PR011 conclusion
- Current local LiveKit results are reasonably representative of the **cloud inference plus Upstash knowledge path**, not of full telephone transport.
- Deploying the same worker to a healthy European Railway or LiveKit Cloud region should mainly change network stability and smaller transport components. It should not recreate Vapi's old 3–6 s delay because LiveKit client delegation still has no backend reasoner passes.
- A final Telnyx/SIP benchmark remains required before claiming production parity with Vapi embedded-KB calls.

---

## TTS / Voice

### Cartesia Sonic 3.5 (Kacper) — excellent Polish pronunciation and interruption handling
- **Discovered:** 2026-09-03
- **Agent:** Factolex Receptionist PL (PR004, VAPI)
- **Config:** Cartesia Sonic 3.5, voice: Kacper (43e52207-96fc-4e01-aaf8-cae317e43fdb)
- **What happened:** Agent read a 9-digit Polish phone number perfectly naturally, spoke addresses clearly, and stopped talking immediately when interrupted mid-sentence. Previous agents (PR005) had significant struggles with interruption and number pronunciation.
- **Takeaway:** Cartesia Sonic 3.5 with the Kacper voice is currently the best TTS option for Polish voice agents. Interruption handling and number dictation work out of the box without special config.

### GPT-Live PR011: Cedar was faster and cleaner than Marin
- **Discovered:** 2026-11-21
- **Agent:** PR011 Tatravet V2.0
- **Controlled comparison:** Same `gpt-live-1` speaker, `gpt-5.6-sol` reasoner, `xhigh` effort, prompt and FAQ tool; only the OpenAI voice changed.
- **Cedar call:** `01a1fe18-9144-7002-9a7d-1d90db92c23a`.
- **Marin call:** `01a1fe2a-2954-7001-b992-ba85715fec38`.
- **Delegation timing:** Cedar completed Saturday-hours, Tuesday-follow-up and USG turns in 3.49 s, 1.35 s and 3.30 s. Marin took 3.99 s, 1.83 s and 4.09 s. Most of this difference was reasoner variance, so it cannot all be attributed to the voice.
- **Speaking speed:** For identical text, Cedar's greeting took 13.2 seconds versus Marin's 15.4 seconds. The Saturday answer took 3.6 seconds with Cedar versus 4.2 seconds with Marin — Marin was about 17% slower in these samples.
- **Perceived retrieval pause:** After the short acknowledgement finished, Cedar began the final answer after approximately 3.0–3.2 seconds; Marin took approximately 3.8 seconds.
- **Turn-boundary issue:** Marin emitted a trailing `[breath]` artifact during the Tuesday response. The caller began the next question while it was still completing, producing a split/interleaved transcript. Cedar did not show this issue.
- **Behavior:** Both voices answered the tested facts correctly. Marin also handled the appointment request directly without unnecessary FAQ retrieval.
- **Current decision:** Prefer Cedar for PR011 based on responsiveness, speaking pace and cleaner turn boundaries. Choose Marin only if subjective voice quality clearly outweighs those disadvantages, and retest over multiple calls before changing production.

---

## VAPI Platform

### GPT-Live: `endCall` must be an inline built-in tool
- **Discovered:** 2026-11-15
- **Agent:** PR011 Tatravet V2.0
- **What happened:** Speaker repeatedly said „Do widzenia.”, but call stayed open and eventually ended only when caller disconnected. Prompt changes alone did not fix it.
- **Root cause:** GPT-Live used a saved `endCall` tool through `model.toolIds`. Switching to Vapi's documented inline built-in tool made delegation call `endCall` successfully.
- **Working config:** Keep saved business tools in `model.toolIds`, but define hangup inline:
  ```json
  {
    "model": {
      "toolIds": ["<faq-tool-id>"],
      "tools": [{ "type": "endCall" }]
    }
  }
  ```
- **Speaker prompt:** Explicitly list ending as backend work and a mandatory delegation trigger. State: “Saying goodbye does not end the call.”
- **Reasoner prompt:** Keep direct: `Call endCall when the caller asks to end the call, says goodbye, or says that nothing else is needed.`
- **Verification:** Transcript proves only spoken words. Verify an `endCall` entry and successful result in call **Messages**, plus assistant-ended reason.
- **Classic tool messages:** Saved-tool `request-start` messages are not spoken by GPT-Live. Do not rely on them for a farewell.
- **Farewell limitation:** Speaker and reasoner run concurrently. Inline `endCall` terminates immediately and does not wait for speaker audio. Even an exact speaker instruction can lose the race; PR011 said only `Jasne.` before successful hangup instead of the requested `Dziękujemy za kontakt z Tatravet. Do widzenia.`
- **Prompt limitation:** Putting the farewell in reasoner instructions does not solve this; reasoner executes tools and does not control speaker playback. Native conversational GPT-Live exposes no documented `delay`, `waitForSpeech`, `blocking` or farewell field on inline `{ "type": "endCall" }`.
- **Practical choice:** Prefer reliable immediate termination over a guaranteed farewell. A guaranteed “say, wait, then hang up” flow needs an ordered hook or custom backend orchestration.
- **Acknowledgment race:** Generic speaker rules such as “use a short acknowledgement while backend work runs” can produce `Jasne.` during termination. Scope those acknowledgments to retrieval/callback work or accept the artifact.
- **Backstop:** Add final `customer.speech.timeout` hook with ordered `say` then inline `{ "type": "endCall" }`; do not rely on idle speech alone. This solves timeout endings only, not conversational endings.
- **Deployment trap:** API updates can modify only an API-key-scoped draft. Normal calls keep using published version until dashboard publish. Vapi drafts are user-scoped, so compare full publish preview before publishing.

### GPT-Live uses speaker delegation and reasoner execution
- Speaker never calls tools directly. Speaker delegates; reasoner chooses and calls attached tool.
- A spoken acknowledgment or farewell does not prove delegation occurred.
- For missing actions, inspect call Messages in order: delegation, tool call, tool result, ended reason.
- Voice behavior is nondeterministic. Repeat critical scenarios across several fresh calls after every prompt or tool change.
- For exact timing, download `GET /call/{callId}/call-logs`. The gzipped JSONL contains `delegation`, `reasoner` and `tool` operations with `durationMs`, `toolRounds`, model, reasoning effort and voice configuration. `GET /call/{callId}` also contains message timestamps and `secondsFromStart`.
- GPT-Live may not populate standard `artifact.performanceMetrics.turnLatencies`; raw call logs are the more useful source for speaker/reasoner investigations.

### Missing config keys cause poor turn-taking
- **Discovered:** 2026-08-27
- **Key missing settings:** `startSpeakingPlan`, `stopSpeakingPlan`, `transcriptionEndpointingPlan`, `backgroundSound`
- **Impact:** Without `transcriptionEndpointingPlan.onNumberSeconds`, the agent cuts in before the caller finishes dictating numbers. Without `stopSpeakingPlan`, interruption behavior is unpredictable.
- **Reference config:** See PR005 notes or PRX01 settings for full key list

### Vapi data retention depends on plan
- Pay-as-you-go: ~7 days retention
- Higher plans: ~30 days
- Zero Data Retention (ZDR): nothing stored after call ends
- Don't promise clients a specific retention period — say "transkrypcje dostepne w systemie"

### End-of-call-report webhook still delivers data even with ZDR
- Even with Zero Data Retention / recording disabled, the webhook STILL receives the full transcript, summary, and structured data
- Vapi generates this in real-time, sends it on the webhook, then deletes on its side
- What matters is what YOU do with the data on your end

---

## Compliance / RODO

### Two approaches to RODO compliance for voice AI agents

#### Approach A: "With data collection" (complex, expensive)
- Agent collects PII (name, phone, case description)
- Requires: DPA (umowa powierzenia danych), RODO klauzula informacyjna in prompt, privacy policy update on client's website
- Data roles: Client = administrator danych, OptimizeLabs = procesor, Vapi = sub-procesor
- Agent MUST say at start: "Informuje, ze rozmowa jest rejestrowana w celu zapewnienia jakosci obslugi"
- Art. 6 ust. 1 lit. f RODO — prawnie uzasadniony interes (obrona przed roszczeniami)
- Higher price for client due to legal responsibility and complexity
- Violation: up to 4% annual revenue (RODO art. 83)

#### Approach B: "Without data collection" (simple, recommended for start)
- Agent does NOT collect PII — no name, no phone, no email
- Audio recording disabled, transcripts not stored (Vapi auto-deletes)
- Webhook collects ONLY aggregated KPI: call count, duration, case type breakdown, peak hours — no PII
- No DPA needed, no RODO klauzula needed, no privacy policy changes
- Agent still says "jestem wirtualna asystentka" (AI transparency)
- Caller ID handled by Telnyx under Prawo Telekomunikacyjne — not our responsibility
- **This is the recommended starting approach** — under-promise, over-deliver

#### Deciding between approaches
- Start with Approach B (no PII collection)
- If client later says "chce wiedziec kto dzwonil" — upgrade to Approach A with proper DPA
- Approach A requires knowing how to set up DPA, sub-processor agreements, and klauzule — charge more for it

### Aggregated KPI reports are the sweet spot
- Zero PII, zero RODO concerns
- Webhook → our server (HTTP) → aggregate → email report every 2 weeks
- Report from e.g. systemy@optimizelabs.pl — doubles as a touchpoint (client doesn't forget about us)
- Content: call count, avg duration, case type breakdown (%), peak hours, outcome (interested/question/spam)
- Graphs > text — lawyers don't want to read 75 transcripts, they want trends
- Position as "od siebie" (bonus) in the offer — not a contractual obligation

### Call forwarding costs (GSM)
- Forwarding from client's existing number to Telnyx DID costs ~0.10–0.20 PLN/min
- Charged by client's operator (Orange/Play/T-Mobile/Plus) on their bill — not ours
- Most business plans in Poland have unlimited calls — forwarding counts as outgoing call, usually included
- Worst case: 300 min × 0.15 PLN = ~45 PLN/month
- Don't complicate the offer with this — just mention "operator moze naliczac standardowa oplate"
