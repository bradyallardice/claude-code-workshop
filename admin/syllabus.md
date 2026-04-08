# Claude Code for Academic Researchers

**Course Outline — Two Delivery Formats**
60-70% Hands-On

---

## Weekly Format: 5 Sessions x 2 Hours (10 Hours Total)

| Session | Topic | Time | Format | Priority |
|---------|-------|------|--------|----------|
| 1 | What This Is / How It Works | 2 hr | Demo + Lecture + Exercise | Core |
| 2 | Research Pipelines: Data to Results | 2 hr | Exercise-Heavy | Core |
| 3 | Code Auditing, Git, and LaTeX in VS Code | 2 hr | Exercise + Demo | Core |
| 4 | Power Features: Hooks, MCPs, and Skills | 2 hr | Demo + Exercise | Core |
| 5 | Expert Judgment + Capstone | 2 hr | Discussion + Independent Work | Core |

## Summer School Format: 2 Sessions x 4.25 Hours (8.5 Hours Total)

| Block | Topic | Time | Format |
|-------|-------|------|--------|
| **Day 1** | | | |
| 1A | What This Is / How It Works | 90 min | Demo + Lecture + Exercise |
| 1B | Research Pipelines: Data to Results | 90 min | Exercise-Heavy |
| 1C | Code Auditing + Git | 60 min | Exercise |
| | Buffer | 15 min | |
| **Day 2** | | | |
| 2A | The Integrated Research Environment: LaTeX, Hooks, MCPs | 90 min | Demo + Exercise |
| 2B | Power Features Hands-On | 75 min | Guided Exercise |
| 2C | Capstone + Debrief | 75 min | Independent Work |
| | Buffer | 15 min | |

---

## Session 1: What This Is and How It Works

*Weekly: Session 1 (2 hr) | Summer school: Block 1A (90 min)*

### Part 1 — What This Is and What You Can Do With It (50 min)

Live demo: two messy datasets cleaned and merged in under 2 minutes

- The coding paradigm spectrum: manual coding -> Copilot -> web chat -> agentic coding
- What Claude Code can do: write code, clean data, generate robustness checks, audit code, build replication packages
- What requires human judgment: analytical decisions, specification choice, interpretation
- The RA analogy and the control principle: you are the PI, Claude Code is the RA
- Why Python; how principles transfer to Stata and R
- Concrete failure examples: silent merge drops, log-of-zeros, unsorted panel lags

**Exercise:** Ask Claude Code to explain a script and add a validation check

### Part 2 — How Claude Code Works (70 min; 40 min in summer school)

- From interactive (Stata/R) to file-based agentic workflows
- The context window: what Claude Code can see, what it forgets, and why this constrains your workflow
- The three execution modes: plan mode, default, auto-accept
  - Plan mode as the default for academic research
  - Default mode: the risk of mismatched judgment about when to ask
  - Auto-accept: speed gains for low-risk mechanical tasks only
- CLAUDE.md: encoding project conventions, variable definitions, and constraints
- Cost management: token economics, structuring requests efficiently

**Exercise:** Set up a project directory, write a CLAUDE.md, issue a task in plan mode and evaluate the proposed plan

*Summer school adaptation: trim cost management to essentials. Participants have not yet hit rate limits, so the motivation is abstract. Cover it informally during later exercises.*

---

## Session 2: Research Pipelines — From Data to Results

*Weekly: Session 2 (2 hr) | Summer school: Block 1B (90 min)*

### Part 1 — Data Cleaning and Merging (60 min; 50 min in summer school)

- The value-to-risk spectrum: what to delegate, what to verify, what to keep
- Writing effective instructions: specifying inputs, outputs, types, dimensions, and edge cases
- The core workflow: describe -> review plan -> generate -> verify -> commit or reject

**Exercise:** Build a data cleaning and merging pipeline from two messy CSVs using plan mode. Verify output against a provided specification sheet (expected row counts, column names, value ranges).

### Part 2 — Robustness and Replication with LaTeX Output (60 min; 40 min in summer school)

- Using Claude Code to generate specification variants from a base analysis
- Alternative standard errors, control variables, subgroups, functional forms, sample restrictions
- Sanity checks as research infrastructure: sample size assertions, coefficient bounds, merge diagnostics
- **Outputting results as publication-ready LaTeX tables** — the first step toward bringing your paper into the same environment as your code

**Exercise:** Generate a robustness table with 5+ specifications from a provided base regression. Verify each specification. Have Claude Code format the results as a LaTeX table and compile it.

*Summer school adaptation: provide the base specification pre-written rather than having participants set it up. Focus time on generating variants and LaTeX output.*

---

## Session 3: Code Auditing, Git, and LaTeX in VS Code

*Weekly: Session 3 (2 hr) | Summer school: Block 1C (60 min, auditing + git only; LaTeX environment moves to Day 2)*

### Part 1 — Code Auditing and Review (50 min; 35 min in summer school)

- Flipping the relationship: Claude Code reads and critiques your code instead of writing it
- Code review for silent errors: wrong join keys, incorrect lags, improper clustering
- Calibrating trust: what Claude Code catches vs. what it misses

**Exercise:** Find 3 planted errors in a realistic research script. Document which errors Claude Code finds, which it misses, and any false positives. Group discussion on calibration.

### Part 2 — Version Control with Git (30 min; 25 min in summer school)

- Git as research insurance, not software engineering ceremony
- The minimum viable workflow: commit -> instruct Claude Code -> diff -> revert if needed
- Why this is essential when an agent modifies your files directly

**Exercise:** Practice the commit-instruct-diff-revert cycle on your project from earlier sessions.

### Part 3 — The Integrated Research Environment (40 min; moves to Day 2 in summer school)

This is the conceptual pivot of the course: expanding what lives inside your project directory so Claude Code can operate on all of it.

- **LaTeX in VS Code instead of Overleaf**: your paper becomes just another file in the project. Claude Code can write it, edit it, check it against your code, and commit it — and collaborators can interact with it through version control.
- Installing LaTeX and the VS Code LaTeX Workshop extension
- Basic LaTeX document structure (for those new to it)
- **Demo:** Claude Code writes a methods section and results table directly into a .tex file, compiles it, and commits the change — all without leaving the editor

**Exercise:** Create a LaTeX document for your project. Have Claude Code write a data description section based on your Session 2 pipeline, including the robustness table from earlier. Compile and commit.

*Summer school adaptation: Part 3 moves to Day 2, Block 2A, where it frames the full "integrated environment" concept alongside hooks and MCPs.*

---

## Session 4: Power Features — Hooks, MCPs, and Skills

*Weekly: Session 4 (2 hr) | Summer school: Blocks 2A + 2B (90 + 75 min)*

The framing: so far, Claude Code operates on your code and data one task at a time. This session is about building **research infrastructure** — automation that persists across sessions, connections to external tools, and reusable workflows.

### Part 1 — Hooks: Automating the Workflow (40 min)

- What hooks are: shell commands that run automatically in response to Claude Code events (file edits, tool calls)
- **The auto-commit hook**: every file change Claude Code makes is automatically committed with a descriptive message. Solves the "I forgot to commit" problem from Session 3.
- How to configure hooks in `.claude/settings.local.json`
- Other hook possibilities: validation gates, linting, notification

**Exercise:** Install the auto-commit hook on your project. Make several changes through Claude Code and inspect the resulting git log. Discuss: when is auto-commit useful vs. when do you want manual control?

### Part 2 — MCPs: Connecting External Tools (50 min)

- What MCPs (Model Context Protocol servers) are: plugins that let Claude Code interact with external services
- **Zotero MCP**: search your library, pull citation metadata, export .bib entries
- **GitHub MCP**: create issues, open PRs, review code — from inside Claude Code
- The integrated pipeline: Zotero MCP pulls references -> Claude Code writes a LaTeX document with proper citations -> auto-commit hook tracks the changes -> GitHub MCP opens a PR for your coauthor to review

**Exercise:** Connect the Zotero MCP (pre-configured for the workshop). Search for papers related to your analysis topic. Have Claude Code generate a .bib file and add a literature review paragraph to your LaTeX document with proper `\cite{}` commands.

### Part 3 — Custom Skills: Reusable Research Workflows (30 min)

- What skills are: packaged prompts that encode complex, reusable workflows
- **Spec-validator skill**: validates data, variables, and transformations before running any estimation
- **Robustness-checks skill**: generates a structured battery of robustness checks from a specification
- Building your own: when a workflow is worth packaging vs. when a good CLAUDE.md is enough

**Demo + Exercise:** Run the spec-validator skill on your Session 2 dataset. Inspect what it checks. Discuss: what would you add to this skill for your own research?

*Summer school adaptation: Block 2A (90 min) covers the "integrated environment" framing + LaTeX setup + hooks. Block 2B (75 min) covers MCPs + skills as a guided follow-along. Less open-ended exploration, more "build this exact thing."*

---

## Session 5: Expert Judgment and Capstone

*Weekly: Session 5 (2 hr) | Summer school: Block 2C (75 min)*

### Part 1 — Developing Expert Judgment (20 min; 10 min in summer school)

- Failure patterns: coherence loss, circular behavior, confident wrong output, scope creep
- The decision framework: correct the approach, restart the conversation, or do it yourself
- Rule of thumb: two failed attempts means do it yourself

Brief exercise: diagnose 2 failure transcripts and choose interventions.

*This discussion is richer after weeks (or a full day) of real experience. Keep it short and grounded in what participants have already encountered.*

### Part 2 — Capstone Project (80 min; 55 min in summer school)

**Track A (guided):** Build a complete research artifact from a new dataset:
- Clean and merge data (Session 2 skills)
- Run a base specification with robustness checks (Session 2 skills)
- Audit the code for errors (Session 3 skills)
- Commit with git; auto-commit hook running (Sessions 3-4 skills)
- Connect Zotero, pull references (Session 4 skills)
- Produce a LaTeX document: data description, results table, bibliography (Sessions 3-4 skills)
- The deliverable: a project directory containing data, code, output, and a compiled .tex paper — all version-controlled

**Track B (self-directed):** Integrate Claude Code into one stage of your own research project. Must use at least: CLAUDE.md, plan mode, git, and one power feature (hook, MCP, or skill).

Structured check-ins at 20 and 40 minutes.

### Part 3 — Debrief (20 min; 10 min in summer school)

Three questions:
1. What was the most useful thing Claude Code did for you?
2. What was the most important error you caught?
3. What will you use going forward, and what will you not?

"The goal was never to make you dependent on this tool. It was to give you a precise understanding of where it helps and where it does not. You are the PI. Keep it that way."

---

## The Anthropic API (Take-Home Resource)

Self-contained handout distributed to all participants.

- When the API is the right tool: batch processing at scale (classifying corpora, extracting data from many documents)
- One pattern: send texts to the API, get classifications back, save to CSV
- Cost estimation before running a job
- Pre-built template script with small text corpus for practice

---

## Prerequisites

Comfort with quantitative research and data analysis in any language. A laptop with the following installed (setup guide distributed one week before):

- Node.js (LTS version)
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- Python 3.9+ with pandas, numpy, statsmodels, scipy, matplotlib
- Git
- VS Code with the Claude Code and LaTeX Workshop extensions
- A TeX distribution (TeX Live or MacTeX)

## Materials Required

- Two messy CSV datasets for Session 2 data cleaning, with specification sheet
- Cleaned panel dataset for Session 2 robustness exercise, with base regression script
- Python script with 3 planted errors for Session 3 code auditing
- Auto-commit hook script for Session 4
- Pre-configured Zotero MCP access for Session 4 (or instructions for participants with existing Zotero libraries)
- 2-3 failure transcripts for Session 5
- New messy dataset for Session 5 capstone Track A
- CLAUDE.md template
- Git cheat sheet (minimum viable commands only)
- LaTeX document template
- API take-home package: template script + instructions + corpus
