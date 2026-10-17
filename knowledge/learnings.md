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

---

## TTS / Voice

### Cartesia Sonic 3.5 (Kacper) — excellent Polish pronunciation and interruption handling
- **Discovered:** 2026-09-03
- **Agent:** Factolex Receptionist PL (PR004, VAPI)
- **Config:** Cartesia Sonic 3.5, voice: Kacper (43e52207-96fc-4e01-aaf8-cae317e43fdb)
- **What happened:** Agent read a 9-digit Polish phone number perfectly naturally, spoke addresses clearly, and stopped talking immediately when interrupted mid-sentence. Previous agents (PR005) had significant struggles with interruption and number pronunciation.
- **Takeaway:** Cartesia Sonic 3.5 with the Kacper voice is currently the best TTS option for Polish voice agents. Interruption handling and number dictation work out of the box without special config.

---

## VAPI Platform

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
