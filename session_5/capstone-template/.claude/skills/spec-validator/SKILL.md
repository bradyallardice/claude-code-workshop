---
name: spec-validator
description: Use before running capstone analyses on data/clean_AJPS.csv or after reshaping the conjoint data. Validates variables, types, ranges, missingness, treatment coding, respondent/task counts, and analysis-readiness. Does not choose specifications.
---

# Spec Validator

Use this skill to validate data before analysis. Do not estimate effects or interpret results while running this audit.

## Required checks

1. Confirm the file exists and can be read from the repo root.
2. Report row count, column count, and column names.
3. Confirm required raw columns exist:
   - `ID`, `countr`, `treat_offshoring`, `manipulation_check2`
   - `qtable_1` through `qtable_4`
   - `price_after_1` through `price_after_4`
   - `cs_after_1` through `cs_after_4`
   - `factory_after_1` through `factory_after_4`
   - `ds_after_1` through `ds_after_4`
   - `tables_policygr_5`
4. Check `qtable_*` values are numeric or coercible to numeric and in the 1-5 range.
5. Check `treat_offshoring` has exactly the expected treatment arms and report their counts.
6. Check each respondent has four conjoint tasks after reshape.
7. Check missingness for all variables used in the requested analysis.
8. Check duplicate respondent IDs in the raw data and duplicate respondent-task rows after reshape.
9. If the task uses attention filtering, report counts for all values of `manipulation_check2`.
10. If the task uses `tables_policygr_5`, report its distribution and missingness before constructing a median split.

## Output format

Return:

```markdown
## Spec Validation
- Status: pass/fail
- Blocking issues:
- Warnings:
- Row/task counts:
- Variables checked:
- Recommended next verification:
```

If any blocking issue appears, stop and tell the user what must be fixed before analysis.
