# Vapi MCP

Pi connects to Vapi's official remote MCP server through the project configuration in `.pi/mcp.json`.

- Endpoint: `https://mcp.vapi.ai/mcp`
- Authentication: `Authorization: Bearer ${VAPI_API_KEY}`
- Access: all tools exposed by the Vapi MCP server, including mutating assistant/tool operations and outbound call creation
- The private key is never stored in this repository

## Connect Make with OAuth

Pi also connects to Make's official MCP server at `https://mcp.make.com`.

Before the first launch, run:

```powershell
pi mcp login make
```

In the browser:

1. Select the correct Make organization.
2. Grant scenario viewing/running and execution-result access.
3. Do not grant scenario, connection, webhook, data-store, team, or organization management scopes.

Make stores the OAuth session in Pi's user-level MCP auth store, not in this repository. The approved scope exposes active on-demand scenarios in the selected organization, so review inputs before running side-effecting scenarios such as calendar booking.

## Start Pi with Vapi and Make access

From PowerShell in the project root:

```powershell
.\mcp\start-pi-with-vapi.ps1
```

The script prompts for the Vapi private key using a masked input, validates the MCP connection with `pi mcp list`, launches Pi in the same process, and removes the temporary environment variable when Pi exits.

If `VAPI_API_KEY` is already set in the current PowerShell process, the script reuses it.

## Existing Pi session

A running Pi process cannot inherit an environment variable created in another shell. Exit and relaunch Pi with the script above. After changing MCP configuration outside a running session, use `/reload`.

Inside Pi:

```text
/mcp
```

Use it to inspect both `vapi` and `make`, their tools, connection status, and errors.

## Safety

The Vapi private key can allow billable calls and production assistant/tool changes. Make scenario-run access can trigger real external actions and consume operations. Review the target resource and proposed inputs before every mutation or scenario run. Keep local `vapi.config.json`, prompt files, and Make scenario exports synchronized as rollback evidence.

Security preflight was performed against official source commit `7edd5c7323096f48a5d3aa198fcb918977faa24b`. The hosted MCP service remains a mutable vendor trust boundary.
