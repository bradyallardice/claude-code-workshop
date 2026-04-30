---
name: tex-reference-audit
description: Use when reviewing or finalizing paper/paper.tex. Audits LaTeX citations, bibliography keys, figure/table labels, refs, orphan labels, missing files, and unresolved cross-references.
---

# TeX Reference Audit

Use this skill before final compile or submission.

## Checks

1. List every `\cite{}` key in `paper/paper.tex`.
2. Confirm every cited key appears in `paper/refs.bib`.
3. Flag unused bibliography entries.
4. List every `\label{}` and every `\ref{}`.
5. Confirm every `\ref{}` points to an existing label.
6. Flag orphan labels that are never referenced.
7. Confirm figure paths in `\includegraphics{}` exist.
8. Confirm table files used with `\input{}` exist.
9. Confirm figure labels use `fig:` and table labels use `tab:`.
10. Compile if a TeX engine is available and report unresolved references.

## Output format

Return:

- blocking compile/reference problems
- citation problems
- figure/table file problems
- cleanup suggestions
