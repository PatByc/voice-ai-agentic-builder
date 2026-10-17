<!-- Source: https://docs.livekit.io/reference/other/roomservice-api.md -->
<!-- Retrieved: 2026-10-17 -->
<!-- License: citation-only; this file is local paraphrased synthesis -->

# Server API and Twirp

LiveKit's backend services use Twirp rather than conventional REST/OpenAPI. Calls are HTTP `POST` requests with JSON bodies. Room service methods use:

```text
<https-project-host>/twirp/livekit.RoomService/<MethodName>
```

Send `Content-Type: application/json` and `Authorization: Bearer <signed-access-token>`. Empty requests still use `{}`. Request keys may be snake_case or camelCase. Tokens must carry the grant required by the method, such as `roomCreate`, `roomList`, or `roomAdmin`.

Core `RoomService` methods include room creation/list/deletion, participant lookup/removal/update, track muting, subscription updates, data sending, metadata updates, participant forwarding/moving, and RPC execution. The exact canonical RPC messages are retained under `schemas/`.

Prefer an official server SDK over constructing tokens and Twirp requests manually. For Python, `livekit-api` reads `LIVEKIT_URL`, `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET` when explicit values are absent.

Canonical source: https://docs.livekit.io/reference/other/roomservice-api
