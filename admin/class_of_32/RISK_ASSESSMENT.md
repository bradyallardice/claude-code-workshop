# Risk Assessment: Running the Workshop for 32 Participants

Prepared 2026-10-26 from the teacher branch, the published student branch, and the public GitHub repo.

**How to read the evidence tags**
- **[verified]**: reproduced or checked directly (command output, test run, official docs).
- **[inferred]**: follows from reading the materials, but not exercised end to end.
- **[base rate]**: a general expectation for a class of this size, not specific to these materials.

---

## 0. Update, 2026-10-26 afternoon: four sessions, prework already sent

Two facts changed the priorities below:

- **The course is now four sessions** (`admin/course_plan_4_sessions.md`). GitHub collaboration and the capstone moved to back matter, so R5–R10 (git push credentials, GitHub MCP tokens, collaborator invites, story exercise, capstone hooks, `rsync`) now matter only if you use those back-matter blocks. Their fixes stay in the kit, tested, in case you do.
- **The prework has already gone out**, so nothing can be fixed by changing it. Fixes must happen in the first minute of class.

**New first-line defence, getting everyone onto the right version:**

| Piece | Who | What it does |
|---|---|---|
| `admin/class_of_32/publish_check.sh` | You, before class | Refuses to publish if a sync is half-finished, teacher work is uncommitted, `student` is missing teacher commits, a slides PDF is older than its `.tex`, or the manifest points at missing files. Shows what students will receive, prints the version stamp they should see, then offers to push. |
| `tools/start_session.sh` / `.ps1` | Students, first minute | One command per OS (Mac: `curl … \| bash -s -- N`; Windows: `irm … \| iex`, same pattern as the Claude Code installer). Fetches only the published snapshot (no merge, nothing to conflict), backs up any edits in the course repo, copies the session's folders into `my_workspace` without ever overwriting, copies the newest slides, opens `my_workspace` in VS Code (which is also the R4 path fix), and prints a READY box with the materials version. Falls back to a zip download if git is broken. |
| `tools/sessions.txt` | You | Which folders and slides each session needs. Read after fetching, so changing it and publishing changes what students get; no script edits when you settle the folder numbering. Session 3 lists `session_2` too, so students who missed Session 2 get it while everyone else keeps theirs. |
| `snippets/README_start_block.md`, `snippets/start_of_session_frame.tex` | You | The block for the top of the repo README (students copy the command from the GitHub page, not the projector) and a drop-in slide frame (compiles in Madrid beamer). |

**Found by testing on Windows and with current package versions (verified):**

| ID | Finding | Status |
|---|---|---|
| R29 | **The Session 1 exercise script crashes on every pandas version** (3.1.0 and 1.5.3 tested). 31 of 472 counties have no 2012 row, so line 122 (`groupby(...)["abs_change"].idxmax()`) fails before either plot is saved, although the docstring says the script works. | **Kit:** fixed copy in `session_1/scripts/`; those 31 counties are left out of the "largest change" ranking only and stay in the panel and CSV. Runs under both pandas versions and produces all three outputs. |
| R30 | **Windows path-length limit.** 21 Zotero PDFs in `session_4/` (the two Zotero library folders) have relative paths of 113–193 characters; nothing else in the materials exceeds 110. Under a OneDrive or Documents folder the full path passes 260, and on a laptop with Windows' default settings **git cannot write those files at all**: tested six ways of enabling `core.longpaths`, all fail. Windows students may already have a partially failed clone from the prework, which also blocks later updates. | **Kit:** `admin/class_of_32/shorten_long_paths.py` renames them to `<Author>_<Year>.pdf` and updates the two `.rdf` files (longest path afterwards: 109). Start scripts recover a damaged copy by cloning fresh beside it and keeping the old one. Libraries students already imported into Zotero are unaffected. |
| R31 | **Several Pythons per machine.** On GitHub's Windows machine the `py` launcher picks Python 3.15 (no packages) while `python` is 3.12 (all packages). python.org's main download button now gives 3.15, which is new this month. | **Kit:** both checkers test every interpreter on PATH and name the one to use. |
| R32 | `session_4/scripts/build_climate_corpus.py` (new) imports `requests`, which is not in the prework install list. It downloads from the GovInfo API, so it looks instructor-only. | If instructor-only, add it to `sync_student.sh`'s removal list; otherwise students need `pip install requests`. |
| R28 | Confirmed: `session_4/option_b` merge and robustness scripts read `option_b/...` while estimate reads `session_4/option_b/...`; under the `my_workspace` layout the first two fail. | Not changed: the other session is renumbering these paths now. |

**Found by the publish check on the real repo at 11:06:** `slides/session5_slides.pdf` is older than its `.tex` (edited during the restructure, not recompiled), and the local `student` branch is 53 commits ahead of GitHub, so today students would get the pre-restructure version.

---

## 1. Bottom line

The materials were designed and timed for 8–16 people: Session 1 intros (8–10), the GitHub story exercise (8–15, 16 chapter files), and the capstone (8 teams). Doubling to 32 creates two kinds of problems:

1. **Latent bugs become class-wide stalls.** A bug that one person in 10 used to hit, and that you fixed in 30 seconds, now hits 3–6 people at once, often in the same five minutes. Three bugs below would hit **everyone** at the same moment (R4, R6, and R5 for Mac users).
2. **Your attention is the bottleneck.** With 16 pairs and a "stuck >90 seconds → flag the instructor" rule, the help queue outgrows one person within minutes of any exercise starting.

**The five things that most reduce risk, in order:**

| # | Action | Fixes | When |
|---|---|---|---|
| 1 | Decide the workspace-path fix (R4) and change the session slides/READMEs before Session 1 | Every student's first script run | Before Session 1 |
| 2 | Have every student run `tools/doctor` and send the SUMMARY screenshot; chase the NOT READY ones | R2, R11–R17 | 72 h before Session 1 |
| 3 | Change the prework so students create a **classic** GitHub token and set up git push credentials | R5, R6 | Before Session 4 prework goes out |
| 4 | Recruit 2–3 helpers (TAs or strong past participants) and use a visible help signal | R1 | Before Session 1 |
| 5 | Install the patched capstone hooks + `.gitattributes`; build the story repo with the script | R8, R9 | Before Sessions 4–5 |

---

## 2. Risk register

L = likelihood, I = impact (H/M/L). **Status** says whether the kit fixes it, it needs a decision from you, or it needs a process change.

| ID | Risk | Session | L | I | Evidence | Status |
|---|---|---|---|---|---|---|
| R1 | One instructor cannot serve 16 pairs; help queue stalls exercises | All | H | H | [base rate] | Process: helpers + help signal (§4) |
| R2 | Several students arrive with broken setups | 1 | H | H | [base rate] | **Kit:** `tools/doctor.sh` / `.ps1` |
| R3 | Session 1 intros take 30+ min (budgeted 12 for 8–10 people) | 1 | H | M | [verified] `session_1/docs/instructor_notes.md` | Process: replace with intake survey / hands |
| R4 | Starter scripts fail with `FileNotFoundError` because of the workspace layout | 1–3 | **H (everyone)** | H | [verified] | **Decision needed** (§3.1) |
| R5 | Mac users cannot `git push` (no credential set up in prework) | 4–5 | H (Mac) | H | [inferred] | Prework change; TROUBLESHOOTING F05 |
| R6 | GitHub MCP's fine-grained token cannot write to the class repo or a partner's repo | 4–5 | **H (everyone but owner)** | H | [verified] GitHub docs | Prework change; F14 |
| R7 | Collaborator invites not accepted / expired (7-day expiry) / username typos | 4 | H | M | [verified] INSTRUCTOR.md; [inferred] at 32 | **Kit:** `invite_collaborators.sh` |
| R8 | Story exercise: 16 chapter files, 8 prompts, 5 chapters pre-written, `assemble.sh` filter matches no placeholder | 4 | H | M | [verified] | **Kit:** `build_story_repo.sh` |
| R9 | Capstone hooks silently disabled when the project path contains a space (common with OneDrive); `python3` may not exist on Windows; hook blocks ROLES.md on `main`. (Correction: an earlier draft said CRLF line endings also break the hooks. That was reproduced with macOS bash only; on Windows, Git for Windows' bash runs CRLF scripts without error.) | 5 | H (Windows) | M | [verified] on macOS and on Windows/Git Bash | **Kit:** patched hooks, 6/6 hook cases pass on Windows |
| R10 | Capstone `rsync` step fails on Windows | 5 | H (Windows) | M | [verified] rsync is not in Git Bash/PowerShell | F19; README edit recommended |
| R11 | Python chaos: several interpreters, pip into the wrong one, Store alias, Homebrew `externally-managed-environment` | 1–2 | H | M | [base rate]; your own Mac has 4 Pythons on PATH | doctor + F07/F08 |
| R12 | `code .` not on PATH (Mac) | 1 | M | L | [base rate] | doctor + F09 |
| R13 | LaTeX: MiKTeX+latexmk needs Perl; BasicTeX missing `makecell` etc.; VS Code PATH stale | 3, 5 | M | M | [inferred] | doctor + F10/F11 |
| R14 | Claude auth: free plan, API/Console login ("credit balance"), wrong account | 1 | M | H for that person | [base rate] | F16; pair them |
| R15 | Pro usage limits hit mid-exercise (Session 2 pipeline, capstone) | 2, 5 | M | M | [base rate] | Pairs swap laptops; F17 |
| R16 | Zotero MCP: not on PATH (esp. Windows), app closed, local API off, PDFs not imported | 4 | M | M | [inferred] | doctor + F12/F13 |
| R17 | Windows: Claude Code cannot find Git Bash | 1 | L–M | H for that person | [inferred] | doctor + F06 |
| R18 | Re-running the copy command overwrites work (Mac `cp -r src/ dest/`) or nests folders (Windows) | 1–5 | M | M | [inferred] | Tell students: copy once per session |
| R19 | Students edit inside the course repo, then `git pull` conflicts | 2–5 | M | L | [verified] READMEs already have recovery | doctor warns; F03 |
| R20 | Session 5 `npm install -g` fails with EACCES on Mac | 5 | M | L | [inferred] | F22 (`npx`) |
| R21 | Venue Wi-Fi / eduroam / captive portal; late cloners downloading the full repo in class | Any | M | H if it happens | [base rate] | §4 fallbacks |
| R22 | Anthropic outage or slowdown during a session | Any | L | H | [base rate] | Recorded demos; plan-review exercises on paper |
| R23 | Answer keys and instructor notes are public on the `teacher` branch | All | Already true | M | [verified] HTTP 200 on `tree/teacher/admin` | **Decision needed** (§3.3) |
| R24 | Your auto-commit + post-commit sync chain flips branches under you; concurrent sessions race | Prep, live demos | M | M | [verified] today (§3.4) | **Decision needed** |
| R25 | Wider skill spread: fast pairs idle, slow pairs lost; debriefs cannot hear 16 pairs | All | H | M | [base rate] | Stretch tasks; sample 3 pairs |
| R26 | Room logistics: power for 32 laptops over 2 h, sightlines to a terminal font, space to circulate | All | M | M | [base rate] | Check room; extension leads |
| R27 | Someone puts restricted/IRB data into a Claude session (Option A, capstone track b) | 3, 5 | M | H | [base rate] | Restate rule before each "own data" exercise |
| R28 | Session 5 `option_b` scripts disagree on paths (`option_b/...` vs `session_5/option_b/...`) | 5 | L | L | [verified] | Check whether intentional for the audit demo |

---

## 3. Details for the risks that need your decision

### 3.1 R4: the workspace path mismatch (hits everyone, first exercise)

**Mechanism.** Every session's slides and README tell students to run `cp -r session_1/ ~/my_workspace/session_1/`, then `cd ~/my_workspace/session_1 && code .`. That makes `~/my_workspace/session_1` the project root. But the scripts use paths that start from the *course-repo* root:

- `session_1/scripts/exercise_build_panel.py:12`: `DATA_DIR = os.path.join("session_1", "data")`
- `session_2/scripts/swiss_franc_logit.py`: `pd.read_csv('session_2/data/swiss_franc_survey.csv')`
- `session_3/option_b/exercise_1/*.py|R|do`: `session_3/option_b/data/...`

Run from `~/my_workspace/session_1`, `session_1/data` resolves to `~/my_workspace/session_1/session_1/data`, which does not exist. Every student gets `FileNotFoundError` on the first run. Claude Code will usually notice and patch the paths, but each student does it differently, and the first five minutes of the exercise go to a non-lesson. The repo's own `CLAUDE.md` convention ("hardcoded relative paths from the project root, e.g. `session_1/data/`") is also not copied into the workspace, so Claude has no instruction pointing to the intended convention.

**Options:**
- **(a) Open the parent folder.** Change the last step to `cd ~/my_workspace && code .`. All `session_N/...` paths then resolve, which matches the repo's `CLAUDE.md` convention. Cost: one line per slide/README; Claude sees earlier sessions' folders, which is minor context noise. Session 5 `option_b/merge` and `robustness` use `option_b/...` and would then break instead (R28), so check those.
- **(b) Rewrite script paths** to be relative to the session folder (`data/...`). Matches the current open-folder instruction, but touches many scripts in three languages and contradicts the repo `CLAUDE.md`.
- **(c) Keep it as a deliberate teaching moment.** Defensible ("Claude made an undocumented fix to your paths; did you check it?"), but only if you announce it. Otherwise 32 people flag you at once.

My recommendation is (a): one line per session, and consistent with the existing convention. Slides are in active editing right now, so I did not change them.

### 3.2 R5 + R6: GitHub credentials (Session 4 will stall without a fix)

There are two separate credentials, and the prework sets up only one, in a form that will not work for the exercise.

- **git itself (push/pull over HTTPS).** The prework never sets up a credential. Windows users get Git Credential Manager from the Git installer, which opens a browser login on first push. Mac users get a username/password prompt, and GitHub rejects account passwords. **Expect most Mac users' first `git push` in Session 4 to fail.** [inferred from the prework text and GitHub's password policy]
- **The GitHub MCP.** The prework (Step 8a) creates a **fine-grained** token. GitHub's documentation lists, among fine-grained token limitations, that they cannot "contribute to repositories where the user is an outside or repository collaborator" [verified, docs.github.com, "Managing your personal access tokens"]. The class story repo is owned by you, and in the capstone the non-owner partner is a collaborator. So MCP calls that write there (create branch, open PR) fail for every student except repo owners. **The prework's verification step (listing the student's own repos) succeeds anyway, so it hides the problem.**

**Fix (one change covers both):** in the prework, have students create a **classic** token with the `repo` scope (30-day expiry) and use it for the MCP. On a Mac, pasting the same token at git's password prompt stores it in the Keychain for git as well. Students who already followed the old prework re-add the server (F14). If you prefer not to use classic tokens, the alternative is a GitHub organization for the class repo, with students as members rather than outside collaborators. I have not tested that path.

### 3.3 R23: answer keys are public

`teacher`, `new-teacher` and `session-4` are all pushed to the public repo. `https://github.com/bradyallardice/claude-code-workshop/tree/teacher/admin` returns HTTP 200. A default `git clone` downloads every branch, so each student has the solutions locally, and Claude Code running inside the course repo can read them with `git show origin/teacher:...`. `sync_student.sh` already notes that answers remain in the student branch's history. With no grades, the main cost is pedagogical: Claude "solving" an exercise by finding the answer key.

Options: move `teacher` to a private repo and delete the public teacher-side branches (irreversible for anyone who has not cloned yet; already-cloned students keep their copies), or accept it. Either way, recommend `git clone --branch student --single-branch` to latecomers (F02). That also cuts the in-class download.

### 3.4 R24: your own commit hooks (observed today)

This checkout runs a global PostToolUse hook that `git add -A` + commits after every Claude Edit/Write, and `.git/hooks/post-commit` runs `sync_student.sh` after every commit on `teacher`. That script checks out `student`, merges, commits, and checks out `teacher` again. Today, with another Claude session also writing in this checkout, a file I created was swept into the student-sync merge commit `cf78baa` (local only, not pushed) and then vanished from the working tree when the sync switched back to `teacher`. In class, the same chain means:
- any live edit you make during a demo triggers a branch flip in the folder VS Code is showing;
- two Claude sessions in the teacher checkout can commit each other's half-finished work onto `student`.

Suggested practice: disable the post-commit hook for teaching days (`mv .git/hooks/post-commit .git/hooks/post-commit.off`), run `./sync_student.sh` manually when you mean to publish, and use one Claude session per checkout. The demo worktree (`start_demo.sh`) is a separate folder and is unaffected.

---

## 4. Operating model for 32 people

**Before Session 1**
- **T-7 days:** send the prework with the doctor command. Ask for the SUMMARY screenshot rather than seven separate command outputs; the READY/NOT READY line makes 32 screenshots triageable in minutes.
- **T-3 days:** list everyone not READY and offer a 45-minute online setup clinic. Run `invite_collaborators.sh status` before Session 4 the same way.
- **T-1 day:** pre-assign pairs. Same OS within a pair (so commands on the slides match), mixed experience, and at least one READY laptop per pair. Pairs are also your usage-limit insurance (R15).
- **Recruit helpers.** A workable ratio is one helper per 8–10 students. Give them `tools/TROUBLESHOOTING.md` printed.

**In the room**
- **Help signal:** a green and a red sticky note per pair (red up = stuck after 90 s). Helpers sweep red notes; you handle content questions.
- **Peer-first rule:** ask your neighbouring pair, then the troubleshooting sheet, then raise red.
- **Never wait for the last person.** For every "everyone run X" step, move on when about 80% are done; the rest catch up with helpers.
- **Debriefs:** sample 2–3 pairs, or collect one sentence per pair in a shared doc or poll.
- **Fallbacks:** recorded demos (the lesson plan already calls for these), a USB stick or zip of the student branch for anyone who cannot clone, a phone hotspot for your demo machine, and a plan-review exercise that works on a printed plan if the service is down.
- **Stretch tasks** at the end of every exercise slide for fast pairs (R25).

**Capstone at 16 teams**
- Assign extensions about 5/5/6 across A/B/C (the INSTRUCTOR table covers 8 teams).
- Private repos on the free GitHub plan cannot use branch protection; either make team repos public or point students to GitHub Education (free Pro).
- Have helpers own team repo setup during the first 10 minutes. That step needs the most hand-holding and is identical for everyone.

---

## 5. What the kit contains

| File | Audience | What it does | Tested? |
|---|---|---|---|
| `tools/doctor.sh` | Students (Mac/Linux/Git Bash) | Read-only setup check, PASS/WARN/FAIL with fix codes, one-screen summary | Yes, on your Mac (12 s full, 4 s `--quick`) |
| `tools/doctor.ps1` | Students (Windows) | Same checks for Windows PowerShell 5.1/7 | **No:** no Windows/PowerShell available here; dry-run it on one Windows machine first |
| `tools/TROUBLESHOOTING.md` | Students + helpers | Fix codes F01–F22 matching the doctor output and in-class failures | Commands checked against docs/CLI help where noted |
| `admin/class_of_32/invite_collaborators.sh` | You | Bulk invite + status for a roster; re-invites expired invitations; flags bad usernames | Yes, against a mock `gh` (all six cases) |
| `admin/class_of_32/build_story_repo.sh` | You | Builds a fresh story repo for N students (fresh placeholders, prompts cycle through the 8, CHAPTERS.md filled, PAIRS.md references fixed) | Yes, with a 32-student roster, including `assemble.sh` |
| `admin/class_of_32/roster_TEMPLATE.csv` | You | `name,github` format shared by both scripts | — |
| `session_5/capstone-template/.claude/...` | Students (Session 5) | Hooks patched for paths with spaces, missing `python3`, and the ROLES.md-on-main bug | Yes, 10-case test matrix in a path containing spaces |
| `.gitattributes`, `session_4/capstone-template/.gitattributes` | Repo | Keep `.sh` files LF on every OS. Insurance only: Git for Windows' bash tolerates CRLF, but other bash builds (macOS, Linux, WSL) do not | Verified on Windows: LF kept under `core.autocrlf=true` |

`admin/` is stripped from the student branch by `sync_student.sh`; `tools/` is not, so students receive it.
