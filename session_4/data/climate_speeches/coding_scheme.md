# Coding Scheme: Climate Mentions in Congressional Speech

**Status: DRAFT, used as written for the Session 4 exercise.** The reference codes were produced by Claude from this scheme, not hand-coded (see `README.md`). Revise the scheme before any use in a real project, and recode the reference set by hand.

## Unit

One passage, meaning one paragraph of a floor speech or inserted statement (see `passages.csv`). Code the passage as written. Do not use the rest of the speech.

## Construct

The speaker's **stance toward action on climate change**, as expressed in this passage.

## Codes

| Code | Label | Use when the passage… |
|---|---|---|
| 1 | SUPPORTS_ACTION | treats climate change as a real problem that warrants a response, or supports policies framed as addressing it |
| 2 | OPPOSES_ACTION | opposes climate policy or climate-motivated regulation, or dismisses or derides climate concern ("climate alarmists", "the climate agenda") |
| 3 | NO_STANCE | refers to the Earth's climate without taking a position: descriptive, procedural, a bill or office name, a list item |
| 4 | NOT_CLIMATE | uses "climate" in a non-environmental sense ("business climate", "political climate", "investment climate") |

## Decision rules

1. **Code the passage, not the speaker.** Party, name, and the rest of the debate are not evidence.
2. **Quoted or inserted material:** code the stance the speaker endorses, not the stance of the text they quote.
3. **Supports the goal but opposes a specific bill:** code 2 if the passage's evaluative weight is against the climate measure, and code 1 if it is against an obstacle to climate action. If neither dominates, code 3 and explain in `notes`.
4. **Several uses of "climate" in one passage:** code the environmental use. Code 4 only if no use is environmental.

## Hard cases to watch for (debrief material)

- Opposition framed as cost or energy prices, with no claim about climate itself.
- Support for an energy source (nuclear, gas) framed as good for the climate.
- Sarcasm and rhetorical concessions ("even if you believe in climate change…").
- Statements of constituent concern ("my farmers are worried about climate change"). Is this the speaker's own stance?
