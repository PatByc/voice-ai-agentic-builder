# Test Log — PR007

## Test Plan

### Functional Tests
1. **Greeting** — Agent opens with correct Polish greeting as Renata
2. **Menu inquiry (pizza)** — Ask "jakie macie pizze?" → agent calls `searchInMenu`, returns formatted results
3. **Menu inquiry (sushi)** — Ask about sushi → agent uses only canonical categories (Zestawy, Hosomaki, Futomaki, Uramaki)
4. **Allergen question** — Ask about gluten/dairy → agent calls `searchInMenu`, never guesses
5. **Recommendation** — Ask "co polecacie?" → agent recommends 1-3 items max, asks follow-up
6. **Order flow (delivery)** — Full order: items + name + phone + address + time preference + summary
7. **Order flow (pickup)** — Full order: items + name + phone + time — agent does NOT ask for address
8. **Light upsell** — Agent suggests sauce/drink naturally without pressure
9. **Mandatory summary** — Agent summarizes full order before closing
10. **End call** — Caller says "to wszystko" → agent confirms and calls `endCall`

### Voice & Tone Tests
11. **Gender detection** — Male caller says "chcialbym" → agent uses Pan consistently
12. **Polish fillers** — Agent uses natural fillers (yyy, mhm, dokladnie) not robotic speech
13. **Price pronunciation** — Prices spoken naturally ("dwadziescia piec zlotych" not "25 zl")
14. **Self-correction** — Agent occasionally self-corrects naturally

### Edge Cases
15. **Unknown menu item** — Ask for item not on menu → agent uses searchInMenu, says not found
16. **Generic sushi type** — Ask for "nigiri" → agent does NOT mention it unless in search results
17. **No searchInMenu hallucination** — Agent never describes items not returned by the tool
18. **Caller undecided** — Agent asks preference questions to narrow down instead of listing everything

### Analysis Plan Tests
19. **KPI generation** — After call, check if structuredDataPlan produces RT/AHT/FCR/NPS/CSAT values
20. **Success evaluation** — After call, check if successEvaluationPlan returns a percentage score

## Test Results

<!-- Log each test session below -->

### Session: YYYY-MM-DD

| Test | Result | Notes |
|------|--------|-------|
|      |        |       |
