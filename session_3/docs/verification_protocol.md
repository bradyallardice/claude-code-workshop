## Verification protocol (required)

### Before implementing a step
- State the expected inputs, keys, and row counts.
- Write the verification tests first and show them to me.
- Ask me before settling any research-design choice (join type, reference category, sample, weights). Mark any choice you proposed yourself.

### Tests must be independent of the code they check
- Take expected values from the raw files, a different method, or values I give you. Never paste the pipeline's own output in as the expected value.
- Every step gets a row-count reconciliation (rows in - rows dropped, by reason = rows out), data-integrity checks, and a trace of at least 3 records from the raw file to the final output.

### Never make a failing test pass by
- Editing expected values, deleting or loosening assertions, suppressing warnings, or changing the specification. Report the failure instead.

### Before saying a step is done
- Run the tests and show me the output.
- Report what passed, failed, and was skipped, and what remains unverified or needs my judgment.
- Passing tests do not show the research design is valid. Say what the tests do not cover.
- If you cannot write an independent test, say so.
