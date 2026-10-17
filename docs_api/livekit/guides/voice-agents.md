<!-- Source: https://docs.livekit.io/agents/start/voice-ai.md -->
<!-- Retrieved: 2026-10-17 -->
<!-- License: citation-only; this file is local paraphrased synthesis -->

# Voice agents

LiveKit Agents supports Python and Node.js agent servers. The official quickstart currently requires Python 3.10+ or Node.js 20+, and presents two pipeline families: a chained STT–LLM–TTS pipeline and a realtime speech-to-speech model.

A Python agent normally defines an `AgentServer`, registers an RTC session handler, creates an `AgentSession`, and starts that session with the job room and an `Agent`. Agent instructions belong on the `Agent`; model, turn handling, and room I/O belong on the session.

CLI lifecycle:

- `lk agent init <name> --template agent-starter-python` creates a starter.
- `lk agent dev` connects a development worker.
- `lk agent start` runs production mode locally.
- `lk agent create` registers and deploys to LiveKit Cloud.

The SDK source pinned in `SOURCE.yaml` reports `livekit-agents` version `1.8.8` and Python `>=3.10,<3.15`. Treat model names and plugin versions as time-sensitive.

Canonical source: https://docs.livekit.io/agents/start/voice-ai
