<!-- Sources: https://docs.livekit.io/agents/start/telephony.md ; https://docs.livekit.io/telephony/start/phone-numbers.md -->
<!-- Retrieved: 2026-10-17 -->
<!-- License: citation-only; this file is local paraphrased synthesis -->

# Telephony

LiveKit telephony bridges SIP calls into rooms. Inbound routing generally combines a phone number or inbound trunk with a SIP dispatch rule; the rule selects the room and can dispatch an agent. Outbound calling uses an outbound trunk and creates a SIP participant.

The canonical service messages are in `schemas/livekit_sip.proto`. They cover inbound/outbound trunks, dispatch rules, SIP participants, and call transfer. Use the official SDK or CLI so grants and Twirp details are generated correctly.

LiveKit Cloud phone numbers and imported SIP-provider numbers have different setup paths. Provider credentials, caller ID, regional availability, emergency calling, and regulatory requirements remain provider- and country-specific. Confirm those in the current provider guide before production use.

Do not place caller PII or provider secrets in room names or logs. Pass per-call routing data through controlled metadata and validate it before triggering tools or external systems.

Canonical sources:
- https://docs.livekit.io/agents/start/telephony
- https://docs.livekit.io/telephony/start/phone-numbers
