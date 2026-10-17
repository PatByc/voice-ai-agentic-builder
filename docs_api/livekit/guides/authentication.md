<!-- Source: https://docs.livekit.io/frontends/build/authentication.md -->
<!-- Retrieved: 2026-10-17 -->
<!-- License: citation-only; this file is local paraphrased synthesis -->

# Authentication and tokens

Clients connect to LiveKit with short-lived JWT access tokens created by a trusted backend. Never expose `LIVEKIT_API_SECRET` in a browser, mobile application, repository, log, or prompt. A token carries identity, room, and permission grants; issue only the grants required for the session.

Server APIs also use signed access tokens in the `Authorization: Bearer <token>` header. Official server SDKs generate these from `LIVEKIT_API_KEY` and `LIVEKIT_API_SECRET` and attach them automatically.

Typical server-side environment variables are:

- `LIVEKIT_URL`: project/server URL.
- `LIVEKIT_API_KEY`: API key / token issuer.
- `LIVEKIT_API_SECRET`: signing secret.

Use separate projects and credentials for development and production. Do not use a development token server as a production trust boundary.

Canonical source: https://docs.livekit.io/frontends/build/authentication
