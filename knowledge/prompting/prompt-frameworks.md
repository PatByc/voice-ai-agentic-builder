# Prompt Engineering Frameworks

Three proven frameworks for structuring voice AI agent prompts.

---

## 1. The INSANE Framework (Henryk, Version 3)

The most repeating pattern across all of Henryk's production prompts. Four core pillars plus three supporting sections.

### The Four Pillars

**1. Role**
Define who the AI is, what it specializes in, and its goal.
```
You are X, you specialise in Y, and your goal is Z
```

**2. Context**
Give the LLM information about its environment. What's its place in the world?
- Company info, business hours, department
- Current time/date via variables like `{{system_time}}`
- What the agent can and cannot do

**3. Guidelines (a.k.a. Specifics)**
Instructions on how the agent should behave.
- Response length limits
- Process steps / call flows
- Rules and constraints

**4. Tone & Style**
Personality and speech patterns. This is how you make an agent "sound human."
- Filler words: "um", "let's see", "just to confirm"
- Personality traits: sarcastic, warm, professional
- Pronunciation rules: "say nine o'clock instead of 09:00"
- Number formatting: "ten thousand dollars instead of $10,000"

Note: As of June 2025, no models on VAPI or Retell can control emotional aspects (loudness, cheerfulness) — it only comes through vocabulary choices.

### Three Supporting Sections

**5. Examples**
Provide example conversations, responses, Q&A setups. This is few-shot prompting applied to voice agents.

**6. Closing Call**
Needed for every voice agent that needs to hang up. Define the end-of-call protocol explicitly.

**7. Notes**
Typically a negatively-framed section at the end of the prompt. Items placed here are quite effective because they're at the end of the prompt (recency effect).

---

## 2. Liam Ottley's Prompt Formula

Six components, each backed by prompting research.

### Components

**1. Role** — Define who the AI is
- Assign an advantageous role suited for the task
- Enrich with complimentary descriptions: "You are an experienced..."
- Add key qualities: "engaging, informative, and concise"
- Research: Role prompting increases accuracy by 10-25%

**2. Task** — Describe what it should do
- Start with a clear verb (generate, classify, analyze, respond)
- Include step-by-step instructions (chain of thought)
- Insert variables where needed: `{{lead_name}}`, `{{ebook_title}}`
- Research: Chain of thought increases accuracy by 10% on simple problems, up to 90% on complex ones

**3. Specifics** — Add important details
- Additional bullet points clarifying instructions
- Emotional stimuli: "This task is critical to our business success"
- Research: Emotion prompting increases performance by 8% on simple tasks, 115% on complex tasks

**4. Context** — Provide background
- Business info, customers, services, products
- The system the AI is part of
- Importance and impact of the task

**5. Examples** — Show sample inputs/outputs
- 3-5 clear examples is the sweet spot
- Structure matters more than perfect accuracy of examples
- Going from 0 to 1 example can increase accuracy from 10% to 45%
- Optimal performance at 10-32 examples, but most gains come from first 3-5

**6. Notes** — Final reminders
- Output formatting instructions
- "Do not" statements for common errors
- Tone adjustments
- Keep concise — info at the end is remembered well (recency effect)

---

## 3. PDER Process (Morningside AI)

A systematic approach for creating production-grade prompts efficiently. Cuts prompt creation time by ~80%.

### P — Plan (5-10 minutes)
Answer these questions before writing anything:
- What are the inputs? What data will this prompt process?
- What format does the output need to be in?
- Where can I find high-quality input/output examples?
- Which model should be used (budget vs performance)?
- What are the specific requirements or constraints?
- Gather 2-3 high-quality input/output examples

### D — Draft
- Use an AI tool (like the "Perfect Prompt Generator" on Relevance AI) to generate a first draft
- Feed in your planning notes and examples
- The tool applies research-backed techniques automatically (role prompting, chain of thought, emotion prompting, markdown formatting)
- Result: ~90% of the way there in minutes

### E — Evaluate
- Use a prompt engineering IDE (e.g., PromptMetheus) to test systematically
- Create a dataset with multiple test cases (e.g., 10 different inputs)
- Run the prompt against each test case
- Grade responses (thumbs up/down) to track which variations work best
- Test with appropriate model and settings (temperature ~0.1 for consistent outputs)

### R — Refine
- Iterative cycle: evaluate → refine → evaluate again
- Create variants of specific sections to test changes
- Toggle sections on/off to see which are truly necessary
- Test different models to find cost/performance balance
- Continue until consistent, correct responses across all test cases

### Tools Referenced
- **Relevance AI** — Draft generation + turning finalized prompts into shareable tools
- **PromptMetheus** — Prompt engineering IDE for testing and iteration
- **StackEdit** — Visual Markdown editor
- **CharacterCountOnline** — Token/character counting

---

## Framework Comparison

| Aspect | INSANE (Henryk) | Ottley Formula | PDER |
|--------|----------------|----------------|------|
| Focus | Voice AI agent structure | General prompt structure | Prompt creation process |
| Best for | Building voice agent prompts | Any AI prompt | Systematic prompt development |
| Key insight | Tone & Style + Closing Call are voice-specific | Emotion prompting + few-shot | Test systematically, don't guess |
| Use together? | Yes — use INSANE structure, informed by Ottley research, refined via PDER process |
