# LiveKit Infrastructure Handoff

## Status

Initial infrastructure idea. Development-first; not final production architecture.

## Goal

Build telephone-only Tatravet voice agent while reusing existing Railway infrastructure and keeping initial platform costs low.

## Proposed architecture

```text
Caller
  → Telnyx phone number / SIP trunk
  → LiveKit Cloud SIP
  → LiveKit room and agent dispatch
  → LiveKit Agents worker on Railway
  → STT / LLM / TTS
  → LiveKit Cloud SIP
  → Telnyx
  → Caller
```

## Service responsibilities

### Railway

- Run Python LiveKit Agents worker continuously.
- Reuse already leveraged Railway infrastructure instead of paying LiveKit to host agent worker.
- Deploy worker automatically from GitHub.
- Start production worker with:

  ```text
  python livekit/agent.py start
  ```

- Store runtime secrets in Railway variables, never Git.

GitHub/Railway auto-deploy handles code deployment only. It does not dispatch calls to worker.

### Telnyx

- Supply telephone number and PSTN carrier service.
- Provide SIP trunk connected to LiveKit Cloud.
- Charge separately for number rental and inbound/outbound call usage.

### LiveKit Cloud

Use free Build plan initially.

LiveKit provides:

- SIP bridge from Telnyx into LiveKit.
- Temporary room for each telephone call.
- Realtime audio transport between caller and Railway worker.
- SIP dispatch rule and agent job dispatch.
- Authentication, connection state, and session lifecycle.

LiveKit does not host worker in this design.

Current Build-plan allowances relevant to this design:

- 1,000 third-party SIP minutes/month.
- 5,000 WebRTC participant minutes/month; self-hosted agent connections may count here.
- $2.50 LiveKit Inference credit, roughly 50 minutes using LiveKit's general estimate.
- 5 concurrent inference sessions.

Build pricing lists no overage rates. Treat allowances as development limits, not guaranteed pay-as-you-go production capacity.

## AI model route

Initial choice remains open:

1. **LiveKit Inference** — fastest setup; uses one LiveKit credential but $2.50 credit becomes likely first limit.
2. **Direct STT, LLM, and TTS APIs** — more credentials and billing relationships, but avoids dependence on LiveKit Inference credit.

Possible direct stack:

```text
STT: Deepgram
LLM: OpenAI
TTS: Cartesia or another Polish-capable provider
```

Direct model APIs do not remove LiveKit SIP or media usage.

## Expected initial costs

```text
Railway: existing worker infrastructure and incremental compute
Telnyx: phone number + call usage
LiveKit: $0 while within Build allowances
AI: $0 within LiveKit credit, otherwise direct-provider or future paid-plan usage
```

No assumption that full production traffic remains free.

## Upgrade path

When Build limits block real usage:

- Upgrade LiveKit to Ship, currently starting at $50/month.
- Ship includes 5,000 third-party SIP minutes, then usage overage.
- Keep worker on Railway unless LiveKit-hosted deployment becomes operationally valuable.
- Keep Telnyx as carrier unless quality, availability, or pricing tests justify change.
- Consider direct AI providers before upgrading only to obtain more inference credit.

## Required configuration

Railway variables:

```text
LIVEKIT_URL
LIVEKIT_API_KEY
LIVEKIT_API_SECRET
LIVEKIT_PROJECT_CODE=PR011
```

Additional direct-provider API keys only if direct STT/LLM/TTS route is selected.

LiveKit/Telnyx setup:

1. Configure Telnyx number and SIP trunk.
2. Configure matching LiveKit inbound trunk.
3. Add LiveKit SIP dispatch rule.
4. Route created rooms to named Railway worker.
5. Test browser room first if useful, then inbound telephone call.

## Decisions still needed

- Inbound only, outbound only, or both.
- Polish number type and expected destination mix.
- LiveKit Inference versus direct model APIs.
- Selected Polish STT and TTS models.
- Expected monthly minutes and peak concurrent calls.
- Recording, retention, observability, and privacy requirements.

## Initial decision summary

Use existing Railway infrastructure for agent runtime, Telnyx for telephony, and LiveKit Cloud Build for SIP/media/dispatch during development. Keep architecture minimal. Measure real call duration, concurrency, inference usage, and quality before paying for LiveKit Ship or changing providers.
