# Prompt Optimization Techniques

Source: Voice AI Bootcamp notes (Henryk) + Liam Ottley

## Markdown Formatting

Markdown is one of the most powerful optimization techniques for voice AI prompts. LLMs interpret markdown structures similarly to how humans do — bold text, headers, and lists signal importance and hierarchy.

**Why it matters for voice AI:**
- Properly formatted prompts generate tokens faster because the AI can more quickly determine the next appropriate token
- Faster token generation = faster response times, which is critical for voice interactions
- Headers create clear section boundaries so the AI knows when one type of information ends and another begins

**How to use it:**
- Use `#` headers to create section boundaries (H1 for main sections, H2/H3 for subsections)
- Use `**bold**` for important terms and key instructions
- Use `-` or numbered lists for sequential steps or grouped items
- Don't go beyond 3-4 levels of headers deep — unnecessary complexity increases hallucinations

## Prompt Sections

Break prompts into clearly defined sections rather than writing monolithic instruction blocks.

**Benefits:**
- Individual sections can be modified without rewriting the entire prompt
- The AI better understands when one type of information ends and another begins
- Sections can be developed and tested independently

**Typical sections for a voice agent prompt:**
- Role / Identity
- Context (business info, environment)
- Guidelines / Rules
- Tone & Style
- Examples
- Call flow / Process steps
- Closing call protocol
- Notes

## Negative Prompting (Avoid This)

Telling the AI what NOT to do often backfires — it draws attention to the unwanted behavior (the "pink elephant" effect).

**Bad:** "Do not use too many commas and points"
**Good:** "Make the conversation fluent and natural"

**Bad:** "Do not add smileys"
**Good:** "Use a professional communication style"

**Rule:** Always reframe negative instructions as positive directives. Tell the AI what you WANT, not what to avoid.

## Prompt Compression

Reduce token usage while maintaining effectiveness. Especially valuable for voice apps where speed matters.

**Basic compression:**
- Eliminate unnecessary words, restructure verbose sentences
- Before: "You are a lead support assistant from our company and you should assist users with their property inquiries while making sure to utilize all available user details during the conversation"
- After: "You're a lead support assistant. Assist users with property inquiries utilizing available user details."

**Advanced compression:**
- Use AI itself to compress prompts (see meta-prompting.md, Example #3)
- Compressed prompts can use emojis, abbreviations, and compact syntax
- Always test compressed versions to ensure they maintain the same effectiveness

**Results:** A properly compressed prompt can reduce character count by 20-30% (one example went from 2520 to 1090 characters) while maintaining equivalent or superior performance.

## Context Management

Models have limited context windows. Organize prompts to make the most of this space.

**Key principles:**
- Put critical instructions at both the beginning AND end of long prompts (the "Lost in the Middle" effect — info at start/end gets ~75% accuracy vs ~50% in the middle)
- Keep instructions short, concise, and bespoke
- Tool descriptions are already seen by the model — don't duplicate tool logic in the system prompt

**Before (verbose):**
```
Collect the users name because we require it for our tool call and then ask for 
their email and don't forget to confirm both of those required fields...After you 
collected the information confirm, then we want to use the 'toolName' to send 
that over to our database
```

**After (concise):**
```
Grab the following required fields, one by one:
- Name
- Email
Then confirm.
```

The tool description handles the rest: "Use this tool after you collected the required fields."

## Optimized Prompt Template Structure

An optimized voice AI prompt combines all techniques above:

1. Clear primary instruction section with markdown headers
2. Well-organized sections for user context, behavioral guidelines, response formatting
3. Positive language throughout (desired behaviors, not prohibited actions)
4. Concise but complete instructions
5. Modular structure allowing easy modification of individual sections
6. Bold text for important elements, bulleted lists for multiple items
7. Critical instructions repeated at both start and end for long prompts

## Max Prompt Length Guidelines

- **GPT-4o:** 1200-1400 words max
- **GPT-4.1 and newer:** Can handle up to 4000+ words
- Shorter is almost always better for voice agents — compress where possible
