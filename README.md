# Voice AI Agentic Builder

A local workspace for managing voice AI agents across providers (VAPI, ElevenLabs, and others). Tracks prompts, settings, accounts, and test results in one place.

## Structure

```
agents/              Agent registry — one folder per agent (PR001, PR002, ...)
  _template/         Template files for new agents
  registry.json      Master index of all agents
accounts/            Provider account registry
knowledge/           Best-practice docs, prompt guides, testing methodology
  prompting/         Prompt engineering references
  testing/           Testing guides and checklists
  vapi/              VAPI-specific documentation
  elevenlabs/        ElevenLabs-specific documentation
  general/           General voice AI best practices
docs/                Project planning docs
references/          Project reference material
```

## Agent Workflow

1. Create a new agent folder under `agents/` with the next project code (PR001, PR002, ...)
2. Copy files from `agents/_template/`
3. Fill in `settings.json` with provider, account, and config details
4. Draft the prompt in `prompt.md` using knowledge base references
5. Run tests from the test plan and log results in `tests.md`

## Vapi configuration as code

Linked Vapi agents use `agents/<agent>/vapi.config.json` as the complete deployable configuration. Use `scripts/vapi-config.ps1` to pull, validate, diff, and apply configuration without relying on the Vapi dashboard. See `docs/VAPI_CONFIG.md` for the workflow and secret-handling rules. The dated Vapi LLM, STT and TTS comparison is in `docs/VAPI_MODEL_CATALOG_2026-09-02.md`.

## Providers

- **VAPI** — 2 accounts
- **ElevenLabs** — 1 account
