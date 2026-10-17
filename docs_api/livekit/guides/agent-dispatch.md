<!-- Source: https://docs.livekit.io/agents/server/agent-dispatch.md -->
<!-- Retrieved: 2026-10-17 -->
<!-- License: citation-only; this file is local paraphrased synthesis -->

# Agent dispatch

Agent dispatch associates a named agent worker with a room. Explicit dispatch is available through server SDKs, CLI, or the Twirp `AgentDispatchService`. The canonical request and response messages are in `schemas/livekit_agent_dispatch.proto`.

A dispatch identifies the room and agent name and may include opaque metadata for the job. Encode structured metadata as JSON and validate it inside the agent before use. Keep job-specific metadata distinct from shared room metadata.

Raw method paths follow the Twirp convention, for example:

```text
/twirp/livekit.AgentDispatchService/CreateDispatch
```

The bearer token must carry the required room-administration grant. A room can also cause automatic agent dispatch through room configuration or SIP routing.

Canonical source: https://docs.livekit.io/agents/server/agent-dispatch
