---
name: llm-prose-audit
description: Use when reviewing capstone prose for generic AI-written style, vague transitions, inflated claims, repetitive sentence structure, and low-information phrasing.
---

# LLM Prose Audit

Flag prose that sounds generic or inflated.

Look for:

- broad claims without a specific noun or result
- repeated sentence openings
- "important", "complex", "nuanced", or "significant" without evidence
- empty roadmap phrasing
- overlong sentences that hide the claim
- generic transitions like "This highlights the importance of..."

Return:

- the phrase or sentence
- why it weakens the note
- a tighter direction for revision

Do not rewrite the whole paper unless asked.
