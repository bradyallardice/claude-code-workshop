---
name: research-docs
description: Use when tracking analysis decisions, verification checks, sample restrictions, merge/reshape choices, or reasons for changing specifications during the capstone.
---

# Research Docs

Use this skill to keep a lightweight audit trail of analytical decisions.

## Default file

Use `research_log.md` at the repo root unless the user specifies another file.

## What to record

Add short entries for:

- chosen extension and why
- reshape decisions
- factor/reference category decisions
- sample restrictions
- missing-data handling
- attention-check filtering
- estimator choices
- robustness variants
- failed checks and fixes
- final output file paths

## Entry format

```markdown
## YYYY-MM-DD HH:MM - Short title
- Decision:
- Reason:
- Files changed:
- Verification:
- Open question:
```

Keep entries factual. Do not write long prose or interpret results unless the user asks.
