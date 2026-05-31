# Project Notes

A scratch document for the Session 1 terminal demo. Ask Claude Code, from the
terminal, to edit one section and leave the others alone.

## Summary

In this project we are taking county-level presidential election returns and
joining them to demographic information drawn from the census so that we can
look at how the composition of a county relates to how it votes, and we are
doing all of this across several election years so that we can also say
something about how these relationships have been changing over time, and the
eventual goal is to have a single clean county-year panel that other scripts
can read without having to redo any of the merging or cleaning work themselves.

## Data sources

- County presidential returns (`data/election/`)
- IPUMS census microdata, sampled (`data/ipums/`)

## Open questions

- Which education threshold counts as "college"?
- How should we handle counties that change FIPS codes across years?
