# ElevenLabs Setup Guide

Source: Voice AI Bootcamp — Lessons 2.2, 2.4, 2.9

## Account Creation

Set up an ElevenLabs account and walk through the UI.

## Default Agent Settings

Set up a default agent configuration. These settings get reused across solutions and save time by keeping things consistent — you can duplicate from the default.

Key settings to configure:
- Default voice selection
- Timezone (click the "set timezone" button in the UI)
- System time variable: `{{system_time}}`

## Voice Selection

- Test voices in the ElevenLabs UI before committing
- See `voice-list-v2.md` for the full v2 voice list with IDs
- For multi-lingual use cases, Arabella (`aEO01A4wXwd1O8GPgGlF`) is recommended
- ElevenLabs V3 voices exist but are not production-ready as of June 2025

## Building an Agent

Both bootcamp solutions (static appointment setter and construction receptionist) were built entirely within the ElevenLabs UI:

1. Create agent from default settings (or duplicate an existing one)
2. Paste the system prompt
3. Configure voice selection
4. Set timezone
5. Test within the UI
6. Demo to client
