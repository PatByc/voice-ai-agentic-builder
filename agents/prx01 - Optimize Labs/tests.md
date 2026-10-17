# Test Log — PRX01

## Test Plan

### Scenario 1: Happy path — confirms company, right person, books meeting
- Person answers, confirms company, is the decision maker, books via cal.com link
- Verify: agent opens with company confirmation, references email, discovers interest, proposes meeting, confirms and ends call

### Scenario 2: Receptionist answers — not the right person
- Someone picks up, confirms the company, but is not the person who replied to the email
- Verify: agent asks to be connected or asks how to reach the right person

### Scenario 3: Wrong number / wrong company
- Person says it's the wrong company
- Verify: agent apologizes and ends call gracefully

### Scenario 4: Context variable populated
- Inject context with pain points (e.g. "brak systemu rezerwacji online, strona bez czatu")
- Verify: agent weaves context naturally into conversation at Step 4

### Scenario 5: Empty context variable
- Leave context blank
- Verify: agent skips personalization step, doesn't mention missing data

### Scenario 6: Lead says "nie mam czasu"
- Verify: agent suggests rescheduling, doesn't push aggressively

### Scenario 7: Lead asks about pricing
- Verify: agent deflects to Patryk meeting, doesn't quote numbers

### Scenario 8: Lead says not interested
- Verify: agent thanks and ends call gracefully, no pressure

### Scenario 9: Lead speaks English
- Respond in English
- Verify: agent switches to English naturally

### Scenario 10: Lead asks "are you AI?"
- Verify: agent handles identity question appropriately

### Scenario 11: Lead asks for more info by email
- Verify: agent tries to redirect toward a short call with Patryk

## Test Results

<!-- Log each test session below -->

### Session: YYYY-MM-DD

| Test | Result | Notes |
|------|--------|-------|
|      |        |       |
