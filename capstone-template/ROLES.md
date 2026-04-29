# ROLES.md

Fill in your names and confirm your role split before branching.

## Group members

| Role | Member | Branch name |
|------|--------|-------------|
| Replication | _________________ | `replication` |
| Extension + writing | _________________ | `extension` |

## What each role owns

### Replication (branch: `replication`)
- `starter/replicate_fig1.*` — reproduce Figure 1 (marginal means by treatment)
- Opens PR into `main` when Figure 1 matches the paper
- Writes the Methods paragraph in `paper/paper.tex`

### Extension + writing (branch: `extension`)
- `starter/extend_TEMPLATE.*` — your extension analysis
- `paper/paper.tex` — Introduction, Results, Discussion, Abstract
- `paper/refs.bib` — add any new references
- Opens PR into `main` when analysis and writing are complete

## Merge order

1. Replication PR merges first (establishes the baseline)
2. Extension PR merges second (builds on it)

Both PRs require the other person to review and approve before merging.

## Two-person note

With two people, the extension person also owns writing. If the replication is running smoothly, the replication person can start drafting the Methods section early so there is something to review.
