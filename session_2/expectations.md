# Expectations

Fill this in **before** Claude Code touches the data. After the merge, check each
expectation yourself and fill in **What I found**. Then ask Claude Code to turn this
file into a check script, so the checks rerun every time the code changes.

**Never edit an expectation after you have seen the output.** If you were wrong,
say so under "What I found" (for example: expected 1,200 rows, found 1,150,
because ...).

Answer "How I know" from the codebook, the raw files, or something you counted by
hand. Never from Claude Code's output.

**How many?** There is no fixed number. You are done when every step the code will
take (keep some rows, merge, recode a variable, drop missing values...) has at least
one expectation that would fail if that step went wrong, plus a person or two you
looked up by hand in the raw files. For one merge, that is usually about 5–8.

## The file I am checking

(the path of the file, for example `output/...csv`)

## Expectation 1

- **What must be true:**
- **How I know:**
- **How to check it:**
- **What I found:** (after the merge)

## Expectation 2

- **What must be true:**
- **How I know:**
- **How to check it:**
- **What I found:** (after the merge)

## Expectation 3

- **What must be true:**
- **How I know:**
- **How to check it:**
- **What I found:** (after the merge)

(Copy a block to add more.)
