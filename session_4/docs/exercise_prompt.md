# Session 4 Exercises

Four exercises, in the order you do them in the session, all in your `session_4` copy. Open it in VS Code (`code .` from inside `session_4`) and start a new Claude Code conversation for each exercise.

---

## Exercise 1: Mini Literature Review with Zotero (12 min)

You have Zotero with the Zotero MCP connected, and the practice library (`docs/claude_code_zotero/`) imported as a collection named `claude_code_zotero`: nine papers on economic voting. (Import steps are in `README.md`, "Before Exercise 1".)

Draft a **five-sentence literature review** on one of:

- How economic conditions shape vote choice
- Whether voters punish incumbents for bad economies
- Whether voters respond to the local economy versus the national one

Rules:

- Every sentence cites at least one paper from `claude_code_zotero`.
- Only use cite keys that actually exist in the collection.
- Claude does the searching, full-text reading, and drafting.

While it works, watch the tool calls. Did it run a Zotero search, or guess? Did it pull the full text, or cite from titles alone? Afterwards, spot-check one citation: open the paper in Zotero and ask whether your sentence represents what it argues.

---

## Exercise 2: Build a Skill (15 min)

Working solo. You leave with one skill installed and tested.

1. **Pick a convention (2 min).** Something you actually did in the last two weeks: a format you enforce, an audit you redo by hand, context you retype. Not a hypothetical.
2. **Route it (1 min).** Is this really a skill? Not project context, not an MCP. If a skill, is it verification or production?
3. **Write `SKILL.md` (6 min).** A clear `name`, a `description` that says *when* to fire (and what it does not handle), and the instructions.
4. **Install (1 min).** Save to `~/.claude/skills/<your-skill>/SKILL.md`.
5. **Try it (5 min).** Open a **fresh** Claude Code session. Ask for a task that should trigger it. If it does not fire, the `description` is wrong: fix it and retry.

**Leave with:** a folder with a real `SKILL.md`, one transcript where the skill fired on a real task, and one thing you would change now that you have seen it run.

---

## Exercise 3: Literature Scan, Then Check Every Citation (10 min)

**Choose a narrow question from your own field.** Narrow means you could name the three most relevant papers if asked. "Does civil-service tenure affect corruption?" works; "political economy" does not.

### Step 1: Scan (3 min)

Ask Claude Code to search the web and find 5 or 6 relevant papers. Use this pattern, with your question filled in:

```
Search the web for papers on: <your question>.
Find 5-6 relevant papers. For each, give me: authors, year,
title, venue, a URL or DOI, the one-sentence claim you attribute
to it, and the exact passage that supports the claim.
If you only saw the abstract, say so. If you could not open
the paper, say so. Do not fill gaps from memory.
Write the result to lit_scan/papers.md.
```

### Step 2: Check each paper yourself (6 min)

Do this **outside Claude Code**. For every paper, fill in a row in `lit_scan/check.md`:

| # | Exists? | Details right? | Claim supported? |
|---|---|---|---|
| 1 | Y / N | Y / N | Y / N / could not open |

- **Exists?** Search the exact title in Google Scholar or a library search. Does a paper with these authors exist?
- **Details right?** Compare year, venue, and authors with the publisher or DOI page.
- **Claim supported?** Open the paper. Find the quoted passage by searching the text. Does the paper say what Claude Code says it says?

### Step 3: Tally (1 min)

How many papers passed all three columns? Which column failed most often?

**Why you do it by hand:** asking Claude Code to verify its own citations reuses the process that produced the error.

---

## Exercise 4: Fan Out the Coding (15 min)

**Corpus:** 63 paragraphs of floor speech from the 118th Congress that contain the word "climate" (`data/climate_speeches/passages.csv`). **Scheme:** `data/climate_speeches/coding_scheme.md`.

### Step 0: Read the scheme (2 min)

Before touching Claude Code, read `coding_scheme.md`. Find one passage in `passages.csv` that you expect to be hard to code, and write down which code you would give it and why.

### Step 1: Test on two batches (4 min)

```
Using coding_scheme.md, code the passages in
data/climate_speeches/passages.csv. Spawn two subagents in
parallel: one for the first 10 rows, one for the next 10.
Give each subagent ONLY passage_id and passage_text for its
batch, plus the scheme. Each writes a CSV with columns
passage_id, code to output/batch_N.csv.
```

Check: do the files have the right columns? Do the codes match what the scheme allows? How much of your usage did two agents use? (Look at your usage display before and after.)

### Step 2: Fan out the rest (4 min)

Same prompt for the remaining passages, in batches. When all batches are done, merge them to `output/agent_codes.csv` with columns `passage_id`, `code`. Confirm the merged file has 63 rows and no duplicate `passage_id`.

**Do not give the agents the `party` or `speaker_name` columns.** A coder who sees party can use it as a shortcut. Whether yours would have is something you can only know if you controlled what it saw.

### Step 3: Compare (4 min)

The instructor will give you the reference codes (`gold_codes.csv`) now. Put the file in `data/climate_speeches/`. Then ask Claude Code for:

- the raw agreement rate,
- a confusion matrix (reference codes as rows, agent codes as columns),
- agreement within each category.

Then read the disagreements one at a time. For each, decide: was the agent wrong, was the reference wrong, or does the scheme not decide it?

### Step 4: Check the computation (1 min)

Verify one number by hand (count the diagonal of the matrix, divide by 63), or run:

```
python scripts/compare_to_reference.py
```

and compare its output with what Claude Code reported.

### Debrief questions

1. Which category had the lowest agreement? Which scheme rule explains it?
2. Would you report these codes in a paper? If not, what is the cheapest change that would make you willing?

---
