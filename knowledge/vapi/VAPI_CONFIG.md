# Vapi Configuration as Code

The repository is the control plane for Vapi assistants. After the initial pull, each linked agent has a complete editable `vapi.config.json`. Normal configuration work happens in VS Code and through `scripts/vapi-config.ps1`; the Vapi dashboard is optional.

## Files and ownership

- `agents/<agent>/vapi.config.json` is the canonical deployable Vapi assistant configuration.
- `agents/<agent>/prompt.md` is the readable prompt mirror and notes document.
- `agents/<agent>/settings.json` stores project metadata and the Vapi organization/assistant mapping.
- `agents/<agent>/.vapi/remote.full.json` is an ignored, sanitized pre-change snapshot.
- `agents/<agent>/tests.md` defines acceptance routes and records results.

`Validate` blocks deployment when the system prompt or first message differs between `vapi.config.json` and `prompt.md`. Use `ImportPrompt` when `prompt.md` was edited intentionally, or `ExportPrompt` when the JSON configuration was edited intentionally.

## Full configuration scope

`Pull` retrieves the assistant and writes every returned configuration field except Vapi-managed identity fields:

- `id`
- `orgId`
- `createdAt`
- `updatedAt`
- `isServerUrlSecretSet`
- `latestVersion`

The complete nested objects—model, messages, voice, transcriber, tools, hooks, server settings, artifact settings, speaking plans, analysis settings, metadata, and other Vapi-supported fields—remain editable in `vapi.config.json`.

`Apply` sends the complete local configuration, retrieves it again, and verifies an exact normalized match. This avoids silently dropping nested properties when Vapi replaces a nested object.

For compatibility with Windows PowerShell 5.1, requests bypass the legacy PowerShell web cmdlets and use .NET `HttpClient` with an explicitly UTF-8 `StringContent`. Request JSON contains literal Unicode characters encoded as UTF-8 bytes, matching the Vapi dashboard and avoiding the legacy web-cmdlet encoding defaults.

`Apply` updates Vapi's draft/API view. It does not publish that draft. Vapi documents drafts as per-user, so the API-key draft and the signed-in dashboard user's draft can differ. Publishing from the dashboard can therefore publish only the dashboard user's changes rather than the configuration verified by `Apply`. Vapi inbound calls and default web/outbound calls continue using the current published version until the intended draft is published. Always compare the complete dashboard publish preview and distinguish a successful API sync from a production release.

## Secret policy

Raw secrets are never written into the tracked configuration or snapshots.

On pull, secret-like values become:

```json
"apiKey": "${VAPI_REMOTE_SECRET}"
```

That placeholder preserves the current remote value in memory during an update. To intentionally supply a value from the current process environment, use:

```json
"apiKey": "${ENV:PROVIDER_API_KEY}"
```

Validation rejects raw values in fields named like API keys, tokens, passwords, authorization headers, client secrets, or private keys. Credential IDs and other non-secret references remain in the configuration normally.

## Temporary Vapi authentication

Never paste the Vapi private key into chat or pass it as a command argument. In the same PowerShell process that will run the CLI, use a masked prompt:

```powershell
$vapiSecret = Read-Host "Vapi private key" -AsSecureString
$vapiPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($vapiSecret)
try {
    $env:VAPI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($vapiPointer)
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($vapiPointer)
}
```

If Windows blocks local scripts, allow them only in the current PowerShell process:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

Remove the key when finished:

```powershell
Remove-Item Env:VAPI_API_KEY
Remove-Variable vapiSecret -ErrorAction SilentlyContinue
```

An environment variable created in a separate PowerShell cannot appear in an already-running Codex process. For direct Codex-operated Vapi changes, launch the Codex CLI from the PowerShell containing `VAPI_API_KEY`. Otherwise, run the final reviewed CLI command yourself in that shell.

## Commands

Run these commands from the project root.

Offline validation and self-test:

```powershell
.\scripts\vapi-config.ps1 -Action SelfTest
.\scripts\vapi-config.ps1 -Action Validate -ProjectCode PR004
```

List assistants:

```powershell
.\scripts\vapi-config.ps1 -Action List -ProjectCode PR004
```

Create an assistant from a complete local configuration when no Vapi assistant exists yet:

```powershell
.\scripts\vapi-config.ps1 -Action Create -ProjectCode PR004 -AccountId "vapi-1" -ConfirmCreate
```

`Create` is blocked without `-ConfirmCreate` and when the project already has a provider assistant ID. After creation, the returned assistant ID and complete server-normalized configuration are saved locally automatically.

Initial full pull and link:

```powershell
.\scripts\vapi-config.ps1 -Action Pull -ProjectCode PR004 -AssistantId "VAPI_ASSISTANT_ID" -AccountId "vapi-1"
```

Pull refuses to overwrite differing local configuration. Use `-ConfirmOverwrite` only after reviewing the diff and intentionally choosing Vapi as the source.

Synchronize the prompt mirror after editing one representation:

```powershell
# prompt.md was edited
.\scripts\vapi-config.ps1 -Action ImportPrompt -ProjectCode PR004

# vapi.config.json was edited
.\scripts\vapi-config.ps1 -Action ExportPrompt -ProjectCode PR004
```

Review the complete normalized diff:

```powershell
.\scripts\vapi-config.ps1 -Action Diff -ProjectCode PR004
```

Apply and verify the complete configuration:

```powershell
.\scripts\vapi-config.ps1 -Action Apply -ProjectCode PR004 -ConfirmApply
```

`Apply` is blocked if:

- `-ConfirmApply` is absent;
- the local agent is marked `live`;
- the prompt mirror has drifted;
- a raw secret is detected;
- the post-update Vapi configuration does not match the local configuration.

`Create` is used only once. All later changes use `Diff` and `Apply`.

## Working loop

1. Discuss the observed call behavior and identify the smallest necessary change.
2. Edit `vapi.config.json` and, when relevant, synchronize `prompt.md`.
3. Run `Validate` and `Diff`.
4. Review the complete diff.
5. Run `Apply`.
6. Test the draft, then publish it intentionally when ready.
7. Repeat the failed test route and its closest regression route.
8. Record the result in `tests.md`.
