# Testing

Use this template when testing an agent directly in VAPI's interface (call test button) to skip the backend pipeline and avoid burning VOIP provider tokens.

## Test Message (paste into VAPI's "First Message" or prepend to system prompt for the test)

> **This is a test call.** The agent may behave unexpectedly — this is expected during testing. Do not treat this interaction as a live customer call.

## Input Variables

Set these in VAPI's interface under the assistant's variable/context fields before running the test call. Adjust values per scenario.

| Variable | Example Value | Description |
|----------|--------------|-------------|
| `{{name}}` | `Jan Kowalski` | Caller's name |
| `{{phone}}` | `+48 500 123 456` | Caller's phone number |
| `{{email}}` | `test@example.com` | Caller's email |
| `{{company}}` | `Testowa Firma Sp. z o.o.` | Caller's company name |
| `{{source}}` | `Facebook Ad` | Lead source / how they found us |
| `{{language}}` | `pl` | Language code (pl, en, etc.) |

## Scenario

Fill in per test run. This context goes into the variable/prompt so the agent has a realistic situation to work with.

| Field | Value |
|-------|-------|
| **Date** | `YYYY-MM-DD` |
| **Time** | `HH:MM` (24h, agent's timezone) |
| **Day of week** | `Monday` |
| **Scenario type** | `Inbound lead` / `Follow-up` / `Appointment reminder` / `Cold outreach` |
| **Scenario notes** | _Brief description of what the caller wants or the situation being simulated_ |
| **Expected outcome** | _What the agent should do (book appointment, qualify lead, transfer, etc.)_ |

## How to use

1. Open the agent in VAPI's dashboard
2. Set the input variables in the table above to match your test scenario
3. Paste the scenario context (date, time, notes) into the relevant variable or prompt field
4. Hit the test call button
5. Log results in the agent's `tests.md`
