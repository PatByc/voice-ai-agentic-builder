# Voice AI Agent Testing Methodology

Source: Voice AI Bootcamp — Production Prompt lesson

## Core Principle

Test 3 conversation routes x 10-50 times each. This is the minimum before considering an agent production-ready.

## Route-Based Testing

Define the critical conversation paths your agent must handle, then test each one repeatedly.

### Example: Plate City Customer Support

**Route 1 — Product issue → Refund**
1. Customer says "My plates arrived broken"
2. Agent should ask what type of plates
3. Agent should ask if they want a refund or replacement
4. User says refund
5. Take their order number and name (if not already given)
6. Create a callback ticket / tell them they'll get called back

**Route 2 — Product issue → Replacement**
1. Customer says "My plates arrived broken"
2. Agent should ask what type of plates
3. Agent should ask if they want a refund or replacement
4. User says replacement
5. Ask about their address (same or different), take it if different
6. Take their order number and name (if not already given)
7. Create a callback ticket

**Route 3 — Shipping issue**
1. Customer says "My Christmas tree has not arrived yet"
2. Clarify estimated delivery date
3. Their name (should not ask if already given)
4. Their order number (should not ask if already given)
5. Collect the order number

### Additional Routes to Test
- Hang up ability (does it ask if they need anything else, then hang up?)
- Order number section in isolation (does it repeat numbers correctly?)
- Tool call execution (does it trigger the ticket creation tool?)
- Edge cases specific to the business

## Testing Process

### Phase 1: Internal Testing (You)
1. Define 3+ core conversation routes based on the agent's use case
2. Call the agent 10-50 times per route
3. Check each step against expected behavior (use checkmarks: TICK/FAIL)
4. Fix issues, re-test affected routes
5. Tighten the prompt until you're happy with how it behaves

### Phase 2: Client Testing
1. Give the client the EXACT routes to test (not open-ended testing)
2. Tell them to call a few times for each route
3. Collect their feedback

**Why you give specific routes:** If you let clients test freely, they'll test things that would never happen in the real business — calling it names, being rude, saying random things. This wastes time and produces irrelevant feedback. Give them the specific routes that matter.

### Phase 3: Feedback Loop
1. Client provides feedback (wording, pronunciation, flow issues)
2. You fix the issues
3. Maybe one more round of client testing
4. Push HARD to release to production

**Critical:** Don't get stuck in an infinite testing loop. Clients will always find tiny things to nitpick. The best way to make a production prompt is to let it loose in the real world.

### Phase 4: Production Hardening (First 2-5 Days Live)
- Monitor real interactions with actual customers/callers
- You'll discover edge cases you never thought of
- Fix aggressively during this window
- The agent will improve dramatically from real-world interaction patterns

## Test Log Format

For each test session, log results in a table:

| Test | Result | Notes |
|------|--------|-------|
| Route 1: Broken plates → refund | PASS | Correctly asked for order number |
| Route 1: Broken plates → refund | FAIL | Asked for name twice |
| Route 2: Broken plates → replacement | PASS | Address confirmation was clear |
| Hang up flow | PASS | Asked if anything else, then ended |
| Order number read-back | FAIL | Didn't read in groups |

## Key Metrics to Watch

- Does the agent follow the defined flow?
- Does it skip questions for info already provided?
- Does it trigger tool calls at the right moments?
- Does it handle the hang-up gracefully?
- Does it stay in character?
- Is the response time acceptable?
- Does it pronounce numbers/names naturally?
