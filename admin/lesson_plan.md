# Lesson Plan: Claude Code for Academic Researchers

**A Methods Workshop in AI-Assisted Research**
Two Delivery Formats: Weekly (5 x 2 hr) | Summer School (2 x 4.25 hr)
Draft — April 2026

---

## Course Overview

### What This Course Is

This workshop teaches academic researchers how to use agentic coding tools — specifically Claude Code — to accelerate their research workflows. Participants will learn to automate data cleaning, generate robustness checks, audit existing code, build replication packages, produce publication-ready LaTeX output, and connect external tools like Zotero and GitHub. The course is built around realistic academic research tasks and emphasizes the workflows, judgment, and verification practices that make these tools genuinely useful for published, peer-reviewed work.

The course teaches principles that apply across agentic coding tools (Claude Code, Cursor, Windsurf, and their successors), using Claude Code as the primary platform.

### Target Audience

Academic researchers (primarily PhD students and postdocs in political science and the social sciences) who code regularly in Stata or R but are not software engineers. Participants may have limited experience with Python, the terminal, or version control. The course assumes comfort with quantitative research methods and data analysis concepts, but not with software development practices.

### Core Pedagogical Thesis

Agentic coding tools can dramatically expand what a researcher can accomplish in a given amount of time. The course teaches participants to capture that productivity gain while maintaining the rigor and transparency that academic research demands. The central framework is that the researcher remains the principal investigator: directing the work, making analytical decisions, and verifying every result. Claude Code handles the mechanical execution.

The second thesis, introduced in Session 4, is that the real power comes from building an **integrated research environment** — bringing your paper, references, automation, and version control into the same project directory so the agent can operate on all of it. This is the difference between using Claude Code as a chatbot and using it as research infrastructure.

### Course-Level Learning Outcomes

By the end of this course, students will be able to:

1. Use Claude Code to automate data cleaning, robustness checks, code auditing, documentation, and LaTeX output
2. Assess whether a given research task should be delegated to Claude Code, done manually, or handled via the API
3. Configure and use Claude Code's execution modes (plan, default, auto-accept) appropriately for different research tasks
4. Verify Claude Code's output against known properties of their data and research design
5. Maintain control of their codebase and analytical decisions using git, structured instructions, and project configuration
6. Configure hooks, MCPs, and skills to build persistent research infrastructure around Claude Code
7. Produce a version-controlled project containing data, code, output, and a compiled LaTeX paper
8. Recognize when Claude Code is failing and intervene effectively

### Format

Guided workshop, approximately 60-70% hands-on exercises with pair programming. Participants work on provided academic datasets and, in the capstone, optionally on their own research projects. Pair programming is used both pedagogically and as a mitigation for rate limiting on lower-tier Claude plans.

### Prerequisites (Pre-Work)

Participants must complete the following before the workshop:

1. Install Node.js (LTS version) on their machine
2. Install Claude Code via npm
3. Authenticate with their Anthropic or Claude account
4. Install VS Code with the Claude Code extension
5. Install a TeX distribution (TeX Live or MacTeX) and the VS Code LaTeX Workshop extension
6. Verify installation by running a basic command (instructions provided)

A detailed setup guide with troubleshooting steps will be distributed one week before the workshop. Participants who encounter issues are asked to contact the instructor at least 48 hours in advance.

### Materials Required

- Two messy CSV datasets for Session 2, with specification sheet
- Cleaned panel dataset for Session 2, with base regression specification script
- Python script with 3 planted errors for Session 3
- Methods section paragraph for Session 3 code-matching exercise
- LaTeX document template for Session 3
- Auto-commit hook script (`.claude/scripts/auto_commit_hook.sh`) for Session 4
- Pre-configured Zotero MCP access for Session 4
- 2-3 failure transcripts for Session 5
- New messy dataset for Session 5 capstone Track A
- CLAUDE.md template
- Git cheat sheet (minimum viable commands only)
- API take-home package: template script + instructions + corpus

---

## Session 1: What This Is and How It Works

**Duration:** 2 hours (weekly) | 90 minutes (summer school)
**Format:** Live demo, short lecture segments, guided exercises
**Materials:** Two messy CSV datasets; a Python cleaning script; pre-prepared failure examples (screenshots/transcripts); CLAUDE.md template; token cost reference sheet

### Learning Outcomes

- See a compelling demonstration of what Claude Code can do for academic research workflows
- Understand where agentic coding sits on the spectrum from manual coding to full automation
- Articulate what Claude Code is good at and what requires human judgment
- Configure and explain the three execution modes and choose the appropriate mode for a given task
- Write a CLAUDE.md file that usefully constrains Claude Code's behavior
- Successfully issue tasks in plan mode and evaluate the proposed plan

### Part 1 — What This Is and What You Can Do With It (50 min)

**[0:00-2:00] Opening Hook**

No slides. Open Claude Code in the terminal. Tell the room: "I have two messy datasets that need to be cleaned and merged. This would take me 30-45 minutes in Stata. Watch what happens." Issue the command live. While Claude Code works, transition to the next segment.

**[2:00-10:00] What Just Happened — and the RA Analogy**

Claude Code has produced output. Walk through what it did: read both files, identified the join key, handled cleaning steps, wrote a script. Point out what it got right — emphasize the speed and capability.

Then identify a choice it made without being asked — a join type, a dropped variable, a silent recoding. If it made no visible mistake, switch to a pre-prepared example. The point: "This took 90 seconds instead of 45 minutes. It also made a decision about my data without asking. Both are true."

Introduce the RA analogy: "Claude Code is like a research assistant who is extremely fast, has read a lot, and will never say 'I don't know how to do that' — they will just do it wrong and hand it in. You have all managed RAs. You know how valuable and how dangerous that profile is. This course teaches you to capture the value while managing the risk."

**[10:00-16:00] The Coding Paradigm Spectrum**

Place Claude Code in context:

- **Manual coding:** You write every line. Full control, no assistance. This is what you do now in Stata/R.
- **Autocomplete / Copilot:** AI suggests the next line or block as you type. You accept or reject each suggestion. The AI assists; you drive.
- **Web interface chat:** You describe a task in a chat window, the AI gives you code to copy and paste into your project. Conversational, but you still move code manually.
- **Agentic coding (Claude Code):** The AI reads your project files, writes and modifies code, and can run it directly. It operates on your project, not just in a chat window.

The key insight: "As you move along this spectrum, the tool gets more powerful and more autonomous. Agentic coding is the first paradigm where the tool modifies your project directly. That is what makes it so productive — and why learning to use it well matters."

**[16:00-19:00] What Claude Code Can and Cannot Do**

Frame positively first — what it enables: write code rapidly, clean data, generate robustness checks, create visualizations, audit existing code, write documentation, build replication packages, process text at scale.

Then the boundary: it cannot safely make analytical decisions, choose specifications, interpret results, or determine identification strategies. The test: "If a referee questioned this choice, who would need to answer — you or the RA?"

**[19:00-23:00] Why Verification Matters — Concrete Examples**

Show 2-3 pre-prepared examples rapidly:

1. A merge that silently drops 300 observations. The code looks clean. The error is invisible without checking row counts.
2. A log transformation applied to a variable containing zeros. No error raised, wrong results.
3. A lagged variable in panel data computed without sorting by time within panels.

"These are the kinds of errors that end up in published work. The rest of this course teaches you how to catch them systematically."

**[23:00-25:00] The Control Principle**

"You are the PI. Claude Code is the RA. The question is not 'can Claude Code do this' but 'what is the best way to get this done reliably.' If you cannot verify a result, you should not delegate the task."

**[25:00-27:00] Why Python**

Brief and honest: Claude Code is substantially better at Python than Stata or R. The principles transfer to any language. Python is increasingly where the tools and ecosystem are for computational research.

**[27:00-37:00] Setup and Troubleshooting**

Walk through: open terminal, verify Node.js, confirm Claude Code is installed, authenticate. Participants who completed pre-work help neighbors. If more than 2-3 have issues, deploy pair programming. Do not let this exceed 12 minutes.

**[37:00-47:00] First Hands-On Exercise**

- Task 1 (low-stakes): "Here is a Python script that cleans a dataset. Ask Claude Code to explain what it does, line by line."
- Task 2 (introduces verification): "Ask Claude Code to add an assertion that the row count after cleaning matches [X]."
- Stretch: "Ask Claude Code to handle a new edge case — negative values in a column that should be positive."

Debrief (3 min): What did it get right? Anything wrong or confusing?

**[47:00-50:00] Transition**

"You have seen what Claude Code can do and you have used it for the first time. Now we need to understand how it actually works, because that determines how to use it well."

### Part 2 — How Claude Code Works (70 min; 40 min in summer school)

**[50:00-58:00] From Interactive to File-Based Workflows**

"Most of you work in Stata or R. You open a session, load data into memory, run commands interactively, see results immediately. Claude Code does not work this way."

Claude Code reads and writes files on disk. It does not have a persistent session with your data loaded. When you give it a task, it reads your files, writes or modifies scripts, and optionally runs them. Your data lives in files, not in memory.

Practical implication: you need to think in terms of project directories, file paths, and scripts that run end-to-end — not interactive exploration.

**[58:00-62:00] The Context Window**

Claude Code can only "see" a limited amount of text at once. This includes your instructions, the files it reads, and its own responses. When a conversation gets long or a project gets large, it starts to lose earlier context.

Why this matters: in a complex project with many files, Claude Code cannot hold everything in its head. It may change one file in a way that is inconsistent with another file it can no longer see. Practical strategies: keep tasks focused, provide only relevant context, and tell Claude Code explicitly which files matter.

**[62:00-80:00] The Three Execution Modes**

This is the most important configuration decision. These modes determine how much autonomy you give the agent.

**Plan Mode:** Claude Code analyzes your request, proposes a detailed plan, and waits for explicit approval before doing anything. You review, approve, modify, or reject. Only then does it act.

- *When to use:* any task where the approach matters, not just the output. Data transformation, variable construction, merges, anything analytical. Recommended default for academic research.
- *Why it matters:* the plan is your checkpoint. This is where you catch "I am going to do an inner join" before it happens, rather than discovering 300 missing observations after the fact.

**Default Mode (Ask Before Proceeding):** Claude Code executes steps but pauses to ask permission before actions it considers significant.

- *When to use:* routine tasks in established projects where you trust the general approach but want a safety net.
- *The risk:* Claude Code's judgment about what is "significant" may not match yours. It might pause before writing a file but not before silently recoding a variable.

**Auto-Accept Mode:** Claude Code executes everything without asking.

- *When to use:* low-risk mechanical tasks where you are confident in the instruction and can verify output easily. File reformatting, boilerplate generation, documentation.
- *When not to use:* anything involving your data or analysis. The speed gain is not worth the loss of checkpoints.

Live demonstration: run the same task in plan mode and auto-accept mode. Show what a plan looks like, how to evaluate it.

The key insight: "Plan mode means you direct the work. Auto-accept means you review the work after the fact. For published research, directing is almost always safer than reviewing after the fact."

**[80:00-90:00] CLAUDE.md — Your Lab Notebook for the Agent**

CLAUDE.md is a file in your project directory that Claude Code reads automatically. It encodes your project conventions. It is the single most effective way to prevent errors before they happen.

What belongs in a CLAUDE.md for a research project:
- Project description and research question
- Data structure: file names, key variables, units, expected ranges
- Coding conventions: naming, style, libraries
- Constraints: "never drop observations without logging," "always use robust standard errors," "all merges must report pre- and post-merge row counts"
- What Claude Code should not do: "do not choose model specifications," "do not interpret coefficients"

Show a completed example.

**[90:00-98:00] Cost Management**

"If you are on the $20/month Claude plan, you can burn through your allocation quickly if you are not strategic."

- Not everything needs Claude Code. Small edits are faster to do yourself.
- A well-written CLAUDE.md and clear instructions reduce back-and-forth and tokens.
- If Claude Code is spinning on a wrong approach, intervene early.
- Batch related tasks into one well-scoped request rather than five small follow-ups.

**[98:00-118:00] Exercise: Set Up a Project in Plan Mode**

Participants work in pairs:

1. Create a project directory with a sensible structure (data/, scripts/, output/)
2. Write a CLAUDE.md from the provided template for a provided research scenario or their own project
3. Switch Claude Code to plan mode
4. Issue a task and review the plan Claude Code proposes before approving
5. Evaluate: does it match what you intended? Would you change anything?
6. Approve the plan, run the generated code, verify the output

Instructor circulates to review CLAUDE.md files and plan evaluations. Watch for: CLAUDE.md files that are too vague, participants approving plans without reading them.

**[118:00-120:00] Debrief**

"What did you put in your CLAUDE.md? Did anyone reject or modify a plan? The act of writing a CLAUDE.md forces you to be explicit about conventions you have kept implicit."

### Instructor Notes — Session 1

- Record the live demo as backup. If the live version fails, switch without apology.
- The pre-prepared failure examples require actual artifacts: scripts, output, specific error lines. Budget 2-3 hours of preparation.
- Lead with capability and excitement. The failure examples come after participants have seen what the tool can do, not before.
- Watch for terminal anxiety. The first exercise is deliberately low-stakes.
- The CLAUDE.md template should be distributed as a file to edit, not something created from scratch.
- The plan mode demonstration is critical. Show a plan that includes a questionable choice and demonstrate rejecting or modifying it.
- **Summer school adaptation:** Compress Part 2 to 40 min. Trim cost management to 3 min of principles. Skip the detailed mode comparison — they will experience it in the Session 2 exercises. The exercise can be shorter (15 min) since they will get more practice immediately.

---

## Session 2: Research Pipelines — From Data to Results

**Duration:** 2 hours (weekly) | 90 minutes (summer school)
**Format:** Brief instruction followed by extended guided exercises
**Materials:** Two messy CSV files; specification sheet (expected row counts, column names, value ranges); cleaned panel dataset; base regression specification script; LaTeX template for results table

### Learning Outcomes

- Write structured instructions that specify inputs, expected outputs, and edge cases explicitly
- Execute the full workflow: describe -> review plan -> generate -> verify -> commit/reject
- Verify Claude Code's output against known data properties
- Generate specification variants from a base analysis and verify each one
- Output regression results as publication-ready LaTeX tables

### Part 1 — Data Cleaning and Merging (60 min; 50 min in summer school)

**[0:00-5:00] The Value-to-Risk Spectrum**

- High value, low risk (delegate freely): file management, reformatting, boilerplate, documentation, data cleaning with known specifications.
- High value, moderate risk (delegate with verification): data merges, variable construction, robustness check variants, visualization.
- High risk (do not delegate): choosing specifications, interpreting results, identification strategies, sample selection.

This session focuses on the first two categories.

**[5:00-12:00] Writing Effective Instructions**

The most common mistake: vague instructions that force Claude Code to guess.

- Bad: "Clean this dataset and make it ready for analysis."
- Good: "Read data/raw/survey_2024.csv. Drop rows where country_code is missing. Rename 'gdp_pc' to 'gdp_per_capita'. Convert 'year' from string to integer. Assert that the output has exactly 4,320 rows and 12 columns. Save to data/clean/survey_clean.csv."

Principle: specify column names, expected types, expected dimensions, and edge cases. Never let Claude Code guess about your data.

**[12:00-17:00] The Core Workflow with Plan Review**

The five-step pattern for the rest of the course:

1. **Describe:** Write a clear, specific instruction.
2. **Review the plan:** In plan mode, read what Claude Code proposes. Does it match your intent?
3. **Generate:** Claude Code writes and runs the code.
4. **Verify:** Check the output against known properties.
5. **Commit or reject:** If correct, save via git. If wrong, identify the error and re-instruct.

**[17:00-55:00] Exercise: Build a Cleaning Pipeline**

Participants work in pairs. Provided: two messy CSV files and a specification sheet.

Clean and merge the datasets using plan mode. For each task:
- Write the instruction
- Review Claude Code's proposed plan before approving
- Verify the output against the specification sheet

Instructor circulates. Watch for: Claude Code choosing join types without being told; participants approving plans without reading them; assertions that are too loose.

**[55:00-60:00] Brief Debrief**

Did anyone's merge lose observations? Did Claude Code make choices you did not ask for? What did you catch in the plan?

### Part 2 — Robustness and Replication with LaTeX Output (60 min; 40 min in summer school)

**[60:00-68:00] The Robustness Workflow**

"You have a core specification. A referee asks for alternative specifications, different standard errors, subgroup analyses. This is tedious, mechanical, and error-prone. It is exactly what Claude Code excels at — if you stay in control."

The principle: you write or fully understand the base specification. Claude Code generates the variations. You verify each one. Claude Code never chooses what robustness checks to run.

Sanity checks as research infrastructure:
- Sample size: does each regression use the expected N?
- Coefficient bounds: is the estimate in a plausible range?
- Sign checks: do control variables have expected signs?
- Merge diagnostics: pre- and post-merge row counts

**[68:00-73:00] LaTeX Tables — Bringing Results into Your Paper**

"Until now, your results are printed to the console or saved as CSVs. In your actual workflow, they need to end up in a paper. We are going to have Claude Code output results directly as LaTeX tables."

Brief demo: show a formatted LaTeX regression table compiled to PDF. "This is what we are building toward."

**[73:00-110:00] Exercise: Generate a Robustness Table**

Provided: a cleaned dataset and a base OLS specification. Participants generate 5+ variants:

1. Alternative standard error corrections (robust, clustered)
2. Adding/removing control variables
3. Subgroup analysis
4. Alternative functional form
5. Alternative sample restriction

For each variant: verify sample size, read the code (not just output), write at least one assertion.

**Final step:** Have Claude Code format all results into a single LaTeX table. Compile the table to PDF.

The log-of-zeros error is highly likely to occur. Let it happen — it is a powerful teaching moment.

**[110:00-120:00] Debrief**

How many specifications were correct on the first try? What errors were caught? "Claude Code is excellent at generating boilerplate for robustness tables. It is not reliable at understanding statistical implications. That is your job."

Show the compiled LaTeX table. "You now have a publication-ready table generated from verified specifications, sitting in your project directory. In Session 3, we will put this inside a full LaTeX document."

### Instructor Notes — Session 2

- The messy CSVs should contain realistic problems: mixed date formats, inconsistent country codes, negative values that should not exist, duplicate rows.
- The specification sheet is critical. Without it, participants cannot verify output.
- The base regression specification should be simple enough for Python newcomers to read but substantive enough for 5+ meaningful variations.
- Provide the base specification as a working script, not pseudocode.
- The log-of-zeros error demonstrates the precision problem concretely. Do not prevent it from happening.
- A LaTeX template for the results table should be provided so participants are not starting from scratch.
- **Summer school adaptation:** Provide the base specification pre-written. Cut the data cleaning exercise to 35 min by providing clearer specification sheets. The LaTeX table is a "follow along" rather than open-ended. Total: 90 min.

---

## Session 3: Code Auditing, Git, and LaTeX in VS Code

**Duration:** 2 hours (weekly) | 60 minutes (summer school, Parts 1-2 only; Part 3 moves to Day 2)
**Format:** Exercise, demo, guided practice
**Materials:** Python script with 3 planted errors; methods section paragraph; git cheat sheet; LaTeX document template

### Learning Outcomes

- Use Claude Code to review existing code for silent errors and calibrate trust in its auditing
- Execute the commit-instruct-diff-revert cycle independently
- Set up a LaTeX project in VS Code and use Claude Code to write and compile .tex documents
- Understand why bringing your paper into the project directory matters for an agentic workflow

### Part 1 — Code Auditing and Review (50 min; 35 min in summer school)

**[0:00-8:00] Claude Code as a Second Set of Eyes**

Until now, Claude Code has been writing code. This module reverses the relationship: Claude Code reads and critiques your code. For researchers who already have working pipelines, this is often the highest-value use case.

Applications: pre-submission code review, checking code against methods sections, finding silent data processing errors, generating replication documentation.

Important calibration: Claude Code is useful but imperfect as an auditor. This exercise teaches you where to trust it and where not to.

**[8:00-30:00] Exercise: Find the Planted Errors**

Participants receive an 80-100 line Python script with 3 planted errors:

1. **Error 1 (data processing):** A merge with an incorrect join key that silently drops observations.
2. **Error 2 (statistical):** Standard errors clustered at the wrong level.
3. **Error 3 (logic):** A lagged variable computed without proper time-sorting within panels.

Participants ask Claude Code to review the script. Document: which errors it finds, which it misses, any false positives.

After 15 minutes, reveal the errors. Compare results across pairs.

**[30:00-40:00] Group Discussion: Calibrating Your Expectations**

Pattern: Claude Code catches structural and syntactic issues (wrong join key, missing sort) more reliably than statistical or methodological issues (wrong clustering level). It is better at "this code does not do what you think" than "this code does the wrong thing statistically."

"You now know what Claude Code catches and what it misses. Use it as a first pass, not a final check."

**[40:00-50:00] Exercise: Check Code Against Methods**

Using earlier code from Session 2, ask Claude Code to:
- Read a provided methods paragraph and compare it to the code
- Flag any discrepancies between what the methods section claims and what the code does

Brief discussion: what did it catch? What would a human reviewer catch that it missed?

### Part 2 — Version Control with Git (30 min; 25 min in summer school)

**[50:00-58:00] Git as Your Safety Net**

"Claude Code will sometimes change files you did not ask it to change. Without git, your only option is to try to undo changes manually. With git, you see exactly what changed and revert anything you do not want."

The minimum viable workflow:

1. `git add` + `git commit`: Snapshot your working state before Claude Code touches anything.
2. `git diff`: See exactly what changed, line by line.
3. `git checkout` / `git revert`: Restore the previous state if needed.

That is the entire workflow. Branching, merging, and remotes are useful but not essential for today.

**[58:00-62:00] Live Demo**

Full cycle: commit -> instruct Claude Code -> diff -> identify good and bad changes -> revert the bad. Show that this takes 30 seconds.

**[62:00-75:00] Exercise: Practice the Cycle**

Initialize git, commit current work, ask Claude Code to modify code, review the diff, identify good and bad changes, revert what is wrong. Repeat at least twice.

Watch for: forgetting to commit first; difficulty reading diffs; uncertainty about what counts as a bad change.

**[75:00-80:00] Debrief**

"Commit first, instruct second, diff third, decide fourth. This is the habit. If you take one thing from this module, it is this sequence."

### Part 3 — The Integrated Research Environment (40 min; moves to Day 2 in summer school)

**[80:00-85:00] The Conceptual Pivot**

"So far, Claude Code has operated on your code and your data. But there is one part of your research project that most of you keep in a completely separate tool: your paper. If your paper lives in Overleaf, Claude Code cannot read it, cannot check it against your code, cannot commit changes to it. Your coauthors interact with it through a different system than your code."

"What if your paper lived in the same project directory as everything else? Claude Code could write a methods section, check it against your regression code, update a results table when your analysis changes, and commit the paper alongside the code that produced it. Your coauthors could review changes through git, the same way they would review code changes."

"That is what LaTeX in VS Code gives you. It is not about LaTeX vs. Word. It is about bringing your paper into the agentic workflow."

**[85:00-95:00] Setting Up LaTeX in VS Code**

- Confirm TeX distribution is installed (should be pre-work, but troubleshoot)
- The LaTeX Workshop extension: syntax highlighting, compilation, PDF preview — all inside VS Code
- Basic LaTeX document structure for those new to it (provide template)
- Live demo: open a .tex file in VS Code, compile to PDF, show the split-pane workflow

**[95:00-110:00] Exercise: Build a LaTeX Document with Claude Code**

Using the provided template:

1. Have Claude Code write a data description section based on your Session 2 pipeline
2. Include the robustness table from Session 2 (either `\input{}` the table or have Claude Code embed it)
3. Compile the document to PDF
4. Commit the .tex file with git

Stretch: have Claude Code check the data description against the actual data cleaning code and flag any inconsistencies.

**[110:00-118:00] Demo: The Full Loop**

Show the workflow that ties everything together: Claude Code modifies the analysis code -> the results table updates -> Claude Code updates the .tex file to match -> compile -> diff -> commit. "Every piece of your project is now under version control and accessible to the agent."

**[118:00-120:00] Preview of Session 4**

"You have a project with code, data, output, and a paper — all in VS Code, all under git. Next session, we automate the workflow and connect external tools. What if every change Claude Code made was automatically committed? What if Claude Code could search your Zotero library and pull citations directly into your paper?"

### Instructor Notes — Session 3

- The planted-error script is the most important piece of preparation. It must be realistic. Budget 3+ hours.
- The clustering error is the most likely to be missed by Claude Code. This is by design.
- Frame the calibration positively: knowing the tool's boundaries is the skill.
- By this point participants have experienced Claude Code making unexpected changes. The git motivation is concrete.
- Pair experienced git users with novices.
- The git cheat sheet should contain exactly the commands covered and nothing else.
- LaTeX installation issues are the biggest risk in Part 3. Push hard on pre-work. Have a backup plan: pair participants who have LaTeX working with those who don't.
- The LaTeX template should be minimal but complete: document class, packages, title, sections for data description and results. Do not make participants write boilerplate.
- **Summer school adaptation:** Only Parts 1-2 (60 min). Part 3 moves to Day 2 Block 2A where it opens the power features sequence. This actually works better for summer school because the LaTeX setup frames the "integrated environment" concept right before hooks and MCPs.

---

## Session 4: Power Features — Hooks, MCPs, and Skills

**Duration:** 2 hours (weekly) | Blocks 2A + 2B combined, 165 minutes (summer school)
**Format:** Demo, guided configuration, hands-on exercises
**Materials:** Auto-commit hook script; Zotero MCP access (pre-configured or with setup instructions); LaTeX template (for summer school, where Part 3 of Session 3 is included here)

### Learning Outcomes

- Configure a hook that automates git commits after Claude Code file changes
- Connect an MCP server (Zotero) and use it within Claude Code to search references and generate bibliographies
- Understand what custom skills are and when they are worth building
- Execute the full integrated pipeline: Zotero references -> LaTeX document -> auto-commit -> version control

### Framing (5 min)

"Until now, you have been using Claude Code one task at a time: you give an instruction, it executes, you verify. That is the core workflow and it works. But there is a layer above this — building infrastructure that makes Claude Code more useful *by default*, across every session, without you having to re-explain things."

"Today we cover three levels of that infrastructure:
1. **Hooks** — automation that triggers every time Claude Code acts
2. **MCPs** — connections to tools outside your project directory
3. **Skills** — reusable workflows you can invoke by name

By the end of today, your Claude Code environment will be meaningfully different from what it was this morning."

### Part 0 — LaTeX in VS Code (Summer School Only, 35 min)

*This section is only for the summer school format, where it replaces Session 3 Part 3.*

*Content is identical to Session 3 Part 3 above (The Conceptual Pivot, Setting Up LaTeX, Exercise). See that section for minute-by-minute plan.*

"We just brought your paper into the project. Now let's automate the workflow around it."

### Part 1 — Hooks: Automating the Workflow (40 min)

**[5:00-12:00] What Hooks Are**

Hooks are shell commands that Claude Code runs automatically in response to events. You configure them in `.claude/settings.local.json`. They execute every time the specified event occurs — you do not have to remember to trigger them.

The event model:
- `PostToolUse` with matcher `Edit|Write`: runs after Claude Code modifies a file
- Other possibilities: pre-tool validation, notification on completion

"Think of hooks as standing instructions that never fall out of the context window. Your CLAUDE.md tells Claude Code *what* to do. Hooks tell your *system* what to do when Claude Code acts."

**[12:00-20:00] The Auto-Commit Hook — Walkthrough**

Walk through the auto-commit hook script line by line:

1. It runs after every file edit Claude Code makes
2. It checks if there are any changes to stage
3. It stages all changes
4. It generates a short commit message (using Claude via `claude --print`)
5. It commits

Show the configuration in `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/scripts/auto_commit_hook.sh"
          }
        ]
      }
    ]
  }
}
```

"Remember Session 3 — commit first, instruct second, diff third? This hook automates the commit step. Every change Claude Code makes is now tracked automatically."

**[20:00-35:00] Exercise: Install and Test the Auto-Commit Hook**

Participants:

1. Copy the hook script into their project (`.claude/scripts/auto_commit_hook.sh`)
2. Add the hook configuration to `.claude/settings.local.json`
3. Ask Claude Code to make several changes to their project
4. Inspect the git log — every change should have its own commit with a descriptive message
5. Try reverting one specific change using the granular commit history

Discussion questions:
- When is auto-commit useful? (Exploratory work, rapid iteration, teaching yourself what Claude Code does)
- When do you want manual control? (Polished commits for shared repos, grouping logical changes)
- How would you turn it on and off?

**[35:00-45:00] Other Hook Possibilities**

Brief discussion — do not build these, just plant the idea:
- A pre-tool hook that warns if Claude Code is about to modify a file outside the project directory
- A post-tool hook that runs a linter after every code change
- A notification hook that sends a message when a long-running task completes

"Hooks are simple but powerful. The auto-commit hook is the one most researchers should start with."

### Part 2 — MCPs: Connecting External Tools (50 min)

**[45:00-52:00] What MCPs Are**

MCP stands for Model Context Protocol. MCPs are servers that give Claude Code the ability to interact with external services — tools that live outside your project directory.

Without MCPs: Claude Code can read and write files in your project. That's it.
With MCPs: Claude Code can search your Zotero library, create GitHub issues, query databases, access Google Calendar — anything with an MCP server.

"MCPs turn Claude Code from a tool that operates on your files into a tool that operates on your workflow."

**[52:00-60:00] The Zotero MCP**

For academic researchers, Zotero is probably the most immediately useful MCP.

What it enables:
- Search your Zotero library from inside Claude Code
- Pull citation metadata (author, title, year, journal, abstract)
- Export BibTeX entries for use in LaTeX documents
- Semantic search: "find papers about the effect of voter ID laws on turnout"

Live demo: search for papers, pull a citation, show the data Claude Code receives.

**[60:00-65:00] The GitHub MCP**

Brief overview — less hands-on than Zotero, but important to know about:
- Create issues to track tasks ("open an issue for the missing robustness check")
- Open pull requests for coauthor review
- Comment on PRs

"If your coauthor uses GitHub, this closes the loop: your project is in VS Code, your paper is in LaTeX, your references are in Zotero, your collaboration is on GitHub — and Claude Code can touch all of it."

**[65:00-85:00] Exercise: Zotero -> LaTeX Pipeline**

Participants:

1. Confirm the Zotero MCP is connected (pre-configured for workshop, or guide setup for those with Zotero accounts)
2. Ask Claude Code to search Zotero for papers related to their analysis topic (e.g., "voter turnout and demographics")
3. Have Claude Code generate a `.bib` file with the found references
4. Add a literature review paragraph to their LaTeX document with proper `\cite{}` commands
5. Compile the document and verify the bibliography renders correctly

Instructor circulates. Watch for: MCP authentication issues, incorrect BibTeX formatting, `\cite{}` keys that don't match the .bib file.

**[85:00-95:00] The Full Pipeline Demo**

Put it all together in one live sequence:

1. Ask Claude Code to search Zotero for a reference
2. Claude Code adds it to the .bib file
3. Claude Code writes a sentence in the .tex file citing it
4. The auto-commit hook commits both changes
5. Show the git log: two clean, descriptive commits

"This is what an integrated research environment looks like. Every tool is connected, every change is tracked, and the agent operates across all of it."

### Part 3 — Custom Skills: Reusable Research Workflows (25 min)

**[95:00-102:00] What Skills Are**

Skills are packaged prompts — reusable workflows that you invoke by name. They encode complex, multi-step instructions so you do not have to re-write them every time.

Think of them as CLAUDE.md for specific tasks: your CLAUDE.md sets project-wide conventions; a skill encodes a specific workflow.

When to build a skill vs. when a good prompt is enough:
- Build a skill: you do this task regularly, it has 5+ steps, getting it wrong has consequences
- Just prompt: one-time task, simple instruction, low stakes

**[102:00-112:00] Demo + Exercise: The Spec-Validator Skill**

Demo the spec-validator skill on the Session 2 dataset:

1. Invoke the skill: `/spec-validator`
2. Walk through what it checks: variable types, value ranges, sample sizes, merge diagnostics, missing data patterns
3. Show the output: a structured report of what passed and what flagged

Exercise: participants run the spec-validator on their own Session 2 data. Inspect the output. Discussion:
- What did it check that you would not have thought to check?
- What would you add for your specific research context?
- Is this worth having as a reusable skill, or would a one-time prompt suffice?

**[112:00-120:00] Wrap-Up and Preview of Session 5**

"You now have a Claude Code setup that is meaningfully different from what you started with:
- Your CLAUDE.md encodes your project conventions
- Your auto-commit hook tracks every change
- Your Zotero MCP connects your reference library
- Your paper lives in the same project as your code
- You know what skills are available and when to use them

Next session: we talk about when Claude Code fails and what to do about it, and then you build a complete project using everything you have learned."

### Instructor Notes — Session 4

- **MCP setup is the biggest risk.** Pre-configure Zotero MCP access if possible. Have participants with existing Zotero accounts pair with those who don't. Have a backup plan: provide a pre-built .bib file so participants without Zotero can still do the LaTeX integration exercise.
- The auto-commit hook should be distributed as a ready-to-use script. Do not make participants write bash from scratch.
- The skills demo should use a skill that is already installed. Do not spend time on skill installation — focus on usage and value.
- Keep Part 3 (skills) as demo + light exercise, not deep configuration. The goal is awareness and one hands-on experience, not mastery.
- **Summer school adaptation:** Block 2A (90 min) = LaTeX setup (35 min from Session 3 Part 3) + hooks (40 min) + transition (15 min). Block 2B (75 min) = MCPs (50 min) + skills (25 min). The summer school version is more guided: provide exact commands to run, exact searches to try. Less open-ended exploration.

---

## Session 5: Expert Judgment and Capstone

**Duration:** 2 hours (weekly) | 75 minutes (summer school)
**Format:** Group discussion, then independent project work
**Materials:** 2-3 failure transcripts; diagnostic checklist; new messy dataset for capstone Track A; capstone specification sheet

### Learning Outcomes

- Recognize common failure patterns and apply the correct-restart-bail framework
- Independently execute a full research workflow using Claude Code with hooks, MCPs, and LaTeX
- Produce a version-controlled project containing data, code, output, and a compiled paper
- Articulate what they will and will not use Claude Code for in their own research

### Part 1 — Developing Expert Judgment (20 min; 10 min in summer school)

**[0:00-10:00] Failure Patterns Through Examples**

Present 2-3 failure transcripts. For each, participants diagnose what went wrong:

1. **Coherence loss:** Changes to one file break a dependency in another file Claude Code can no longer see.
2. **Circular behavior:** Three iterations of fixing and re-breaking the same thing with no progress.
3. **Confident wrong output:** A plausible-looking regression table produced from the wrong sample.

**[10:00-15:00] The Decision Framework**

- **Correct:** You know exactly what went wrong and can describe the fix. "Use a left join, not an inner join."
- **Restart:** The conversation has accumulated too much confusion. Start fresh with a clean instruction.
- **Do it yourself:** The task is not a good fit, or you have tried twice and it is still wrong.

Rule of thumb: if Claude Code has not gotten it right in two attempts, seriously consider doing it yourself.

**[15:00-20:00] Brief Exercise**

Pairs receive a failure transcript. Diagnose the pattern, choose an intervention, write the instruction you would give. Quick share-out.

"The skill is not getting Claude Code to work perfectly. It is recognizing quickly when it is not working and knowing what to do about it."

*Summer school: compress to 10 min. Show one failure transcript, state the framework, move to capstone. Participants have been coding for 4+ hours and the motivation is concrete.*

### Part 2 — Capstone Project (80 min; 55 min in summer school)

**[20:00-25:00] Choose Your Track**

**Track A (guided):** New messy dataset -> clean -> analyze -> robustness -> document. Build a complete research artifact:

1. Initialize git, write/update CLAUDE.md
2. Auto-commit hook running
3. Clean and merge data (Session 2 workflow)
4. Run a base specification with 3+ robustness checks (Session 2 workflow)
5. Audit the code for at least one potential error (Session 3 workflow)
6. Connect Zotero, pull 2-3 relevant references (Session 4 workflow)
7. Produce a LaTeX document with: data description, results table, bibliography (Sessions 3-4 workflow)
8. Compile and commit the final version

The deliverable: a project directory containing data/, scripts/, output/, and a compiled .tex paper — all version-controlled with a clean git history.

**Track B (self-directed):** Integrate Claude Code into one stage of your own research project. Must use at least: CLAUDE.md, plan mode, git, and one power feature (hook, MCP, or skill).

**[25:00-30:00] Planning Phase**

Before touching Claude Code: what will you delegate? What will you do yourself? What verification checks will you use? Write it down.

Instructor reviews 2-3 plans.

**[30:00-85:00] Build Phase**

Independent work using the full stack of tools from the course. Structured check-ins at 45 min and 65 min.

Instructor watches for:
- Skipping verification (intervene)
- Failure loops — more than 2 attempts on the same task (suggest doing it yourself or restarting)
- Overly ambitious scope (help them cut)
- Not using power features (remind them of hooks, MCPs)

**[85:00-95:00] Documentation Phase**

Use Claude Code to generate a README for the project: inputs, outputs, dependencies, reproduction steps.

Write a 3-5 sentence reflection: what worked, what required intervention, what would you change.

### Part 3 — Debrief (20 min; 10 min in summer school)

**[100:00-120:00]**

Three questions for the room:

1. "What was the most useful thing Claude Code did for you today — or across the whole course?"
2. "What was the most important error you caught?"
3. "What will you use Claude Code for in your research, and what will you not use it for?"

Closing: "The goal was never to make you dependent on this tool. It was to give you a precise understanding of where it helps and where it does not, so you can make that judgment for yourself. You are the PI. Keep it that way."

### Instructor Notes — Session 5

- Track A dataset must differ from Session 2. It should require cleaning, merging, and at least one analytical task.
- Help Track B participants scope aggressively during the planning phase. "One stage of your project, not the whole thing."
- The debrief matters. Do not cut it. It consolidates learning and forms intentions for future use.
- Have participants save their capstone projects (including git history) to take home.
- **Summer school adaptation:** 55 min for capstone is tight. Pre-scope Track A more aggressively: provide a simpler dataset, reduce robustness checks to 3, make the LaTeX template more complete. The goal is completion, not ambition. Debrief at 10 min — hit all three questions but keep answers brief.

---

## The Anthropic API (Take-Home Resource)

**Distributed as a self-contained package. Not covered in class.**

### Contents

1. **When the API Is the Right Tool** — Web interface for conversations, Claude Code for project work, API for batch processing at scale.
2. **Walkthrough: Batch Text Classification** — Pre-built script that reads a CSV of texts, sends each to the API with a classification prompt, parses responses, saves results. Covers: API keys, request structure, response parsing, rate limiting.
3. **Cost Estimation** — Tokens per request x number of texts x price per token. Always estimate before you run.
4. **Exercise** — Change the classification prompt, run on 50 texts, inspect results.
5. **Resources** — API documentation, Python SDK, Batch API for large-scale jobs.

Materials: template script (heavily commented as a post-course reference), small text corpus (50-100 texts), setup instructions.

---

## Appendix: Preparation Checklist

### Materials to Prepare

- [ ] Two messy CSV datasets for Session 2, with specification sheet
- [ ] Cleaned panel dataset for Session 2, with base regression specification script
- [ ] LaTeX results table template for Session 2
- [ ] Python script with 3 planted errors for Session 3 (budget 3+ hours)
- [ ] Methods section paragraph for Session 3 code-matching exercise
- [ ] LaTeX document template for Session 3
- [ ] Auto-commit hook script for Session 4
- [ ] Zotero MCP access configuration for Session 4
- [ ] 2-3 failure transcripts for Session 5 (drawn from actual experience where possible)
- [ ] New messy dataset for Session 5 capstone Track A
- [ ] CLAUDE.md template
- [ ] Git cheat sheet (minimum viable commands only)
- [ ] API take-home package: template script + instructions + corpus

### Recordings and Backups

- [ ] Backup recording of Session 1 live demo
- [ ] Pre-prepared failure examples for Session 1 (screenshots/transcripts)
- [ ] Prepared plan mode demo showing a questionable plan (Session 1)
- [ ] Pre-built .bib file as backup for Session 4 Zotero exercise

### Logistics

- [ ] Distribute pre-work guide at least one week before (now includes LaTeX installation)
- [ ] Establish communication channel for pre-workshop troubleshooting
- [ ] Test all exercises end-to-end on a clean machine
- [ ] Prepare pair programming assignments or quick pairing method
- [ ] Verify Zotero MCP access works from a student-like account
