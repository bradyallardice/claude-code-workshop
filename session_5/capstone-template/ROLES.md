# ROLES.md

Fill this in before branching. The goal is not to divide the project into isolated silos; it is to give each partner ownership while preserving reciprocal review.

## Team members

| Lane | Member | Branch name |
|------|--------|-------------|
| Paper + literature | _________________ | `lit/<name>` |
| Data + analysis | _________________ | `analysis/<name>` |

## Ownership lanes

### Paper + literature lane

Primary owner for:

- Reading the assigned paper and instructor synthesis notes
- Importing/checking the Zotero library
- Searching the supporting literature with the Zotero MCP
- Drafting the literature review and introduction
- Checking that cited papers support the claims attached to them

Expected branch: `lit/<name>`

### Data + analysis lane

Primary owner for:

- Validating `data/clean_AJPS.csv`
- Replicating Figure 1
- Running the assigned extension
- Saving figures to `paper/figures/`
- Saving any tables to `paper/tables/`
- Checking that output claims match scripts and figures

Expected branch: `analysis/<name>`

## Shared responsibilities

Both partners:

- Review the other person's pull request before merge
- Pull `main` after each merge
- Resolve conflicts together, especially in `paper/paper.tex`
- Complete `AI_WORKFLOW_REFLECTION.md`
- Make sure the final PDF compiles from `main`

## Merge order

A reasonable default:

1. Paper + literature PR establishes the framing and citations
2. Data + analysis PR adds replication and extension outputs
3. Final integration PR resolves prose, tables, figures, and reflection

If your team works in a different order, note why in the PR descriptions.
