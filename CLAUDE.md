# Voice AI Agentic Builder

## What this is

A local knowledge base and agent registry for managing voice AI agents across VAPI, ElevenLabs, and other providers. Not a web app — a file-based workspace.

## Core concepts

- **Agent** = a voice AI agent deployed on a provider. Each gets a project code (PR001, PR002, ...) and a folder under `agents/`.
- **Knowledge base** = best-practice docs in `knowledge/` used to inform prompt writing and testing.
- **Registry** = `agents/registry.json` is the master index. `AGENTS.md` is the human-readable version.

## Directory structure

```
agents/           One folder per agent (PR001/, PR002/, ...), plus registry.json
accounts/         Provider accounts registry (accounts.json)
knowledge/        Best-practice docs organized by topic
docs/             Project planning
references/       Project reference material
```

## Agent files (per agent folder)

- `settings.json` — metadata: project_code, provider, account, status, voice config, tags
- `prompt.md` — system prompt, first message, prompt notes
- `tests.md` — test plan and results log
- `vapi.config.json` — complete deployable Vapi assistant configuration after the first provider pull

## Workflows

### Creating a new agent
1. Get next project code from `agents/registry.json` → `_next_code`
2. Create folder `agents/PR___/` with files copied from `agents/_template/`
3. Fill in settings, draft prompt using knowledge base, define test plan
4. Add entry to `registry.json` and update `AGENTS.md`

### Updating a prompt
1. Read relevant knowledge base docs
2. For a linked Vapi agent, treat `vapi.config.json` as the deployment source of truth
3. Keep `prompt.md` synchronized using `scripts/vapi-config.ps1` (`ImportPrompt` or `ExportPrompt`)
4. Validate and review the full remote diff before applying
5. Note what changed and why in the Notes section

### Testing an agent
1. Refer to `knowledge/testing/` for methodology
2. Generate test plan in `agents/PR___/tests.md` based on agent's use case
3. User runs tests manually, results logged in tests.md

## Rules

- Project codes are sequential: PR001, PR002, PR003, ...
- Always check knowledge base docs before writing prompts
- Match the existing JSON structure in settings files
- Keep AGENTS.md in sync with registry.json
