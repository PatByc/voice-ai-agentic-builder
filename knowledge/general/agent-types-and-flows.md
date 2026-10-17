# Voice AI Agent Types and Flows

Source: Voice AI Bootcamp v2 — Intent, Flows & Logic

## Two Main Types

### Inbound Agents (Intent-Based)
The agent has to figure out what the caller wants.

**Characteristics:**
- More "fluid" prompts — must handle diverse inputs
- Focus on handling various customer intents
- Agent matches the caller to the right intent at the start of every call

**Challenges:**
1. Handling diverse customer intents
2. Managing emotional callers
3. Balancing conversation efficiency with empathy
4. Accurately gathering and validating information
5. Knowing when to escalate to humans

**Example:** E-commerce store with three intents — delivery tracking, FAQs, callbacks

### Outbound Agents (Script-Based)
You control the flow and keep the person engaged.

**Characteristics:**
- More "rigid" prompts — follow a defined script
- Focus on redirecting the user toward the agent's goal
- Remind them why they're getting the call (they signed up, they enquired, etc.)

**Challenges:**
1. Initiating conversations with specific goals
2. Qualifying prospects efficiently
3. Converting interest into concrete actions
4. Maintaining conversation control throughout

## Flow-Based Prompt Architecture

For inbound agents, break the prompt into sub-sections (flows) that reference each other.

```markdown
## Greeting flow
- Respond to the initial utterance of the user
- Ask how you can help
Based on the users intent either choose Sales or Delivery
**here might have to provide few shot prompting examples below**

## Sales flow
Use this flow if user wants to ask about prices of items or wants to buy
**insert complex flow here**

## Delivery flow
Use this flow when asked about deliveries, orders, late shipping etc
**insert complex flow here**
```

This "flowception" approach keeps complex prompts organized and lets you reference flows from other flows.

## Do's and Don'ts

### Do
- Keep your prompt clean — write it yourself
- Minimize data collection steps during the call
- Ask for name → confirm last 3 digits of their number → move on
- Skip the email unless absolutely necessary (adds 30-60 sec, kills the experience)

### Don't
- Use ChatGPT to write your prompts — worst performing prompts come from this
- Collect first name, last name, phone, address, email in sequence — any one of those steps will go wrong and the caller gets frustrated
- Make it feel like a process instead of a conversation

## Tools

Tools are OUTSIDE the system prompt — you don't need to describe tool logic inside your prompt.

**A tool has:** name, description, URL, parameters (with their own descriptions)

**Biggest mistake:** People duplicate tool logic in both the system prompt AND the tool parameters. The tool description is already visible to the model.

**Bad:** Detailed booking workflow written in the system prompt AND duplicated in the tool parameters.

**Good:** Clean system prompt that references the tool. Tool handles its own logic.

## Prompting Techniques for Voice Agents

### Zero-Shot Prompting
Ask the model to perform a task without providing examples. Works for simple, well-defined tasks.

### Few-Shot Prompting
Provide input/output examples to demonstrate the pattern you want.

**Benefits:**
- Steers model behavior without explicit instructions
- Demonstrates expected output format
- Shows edge cases and how to handle them
- More effective than lengthy explanations

### Chain of Thought (CoT)
Encourage the model to break down complex problems into intermediate steps. Useful for complex branching logic in call flows.
