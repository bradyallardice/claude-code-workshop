# Claude Code Workshop: AI Agents in Academic Research

Workshop materials for learning how to use Claude Code as an AI-powered research assistant.

## Start of every session: one command

Copy the line for your computer, change the last number to today's session, and run it.

**Mac** (Terminal):
```bash
curl -fsSL https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.sh | bash -s -- 1
```

**Windows** (PowerShell, not as Administrator). It asks which session:
```powershell
irm https://raw.githubusercontent.com/bradyallardice/claude-code-workshop/student/tools/start_session.ps1 | iex
```

It updates your copy of the course materials to today's version, brings today's
folders in `my_workspace` up to date, copies today's slides, and opens `my_workspace`
in VS Code. Check that the **Materials version** in the READY box matches the one on
the screen.

**Work only in `~/my_workspace`.** The course repo (`~/claude-code-workshop`) is a
read-only mirror that the command resets every time.

When I fix something between sessions, the same command delivers it without touching
your work: a file you have **not** edited is replaced by the newer version; a file you
**have** edited is never changed, and the newer version is saved beside it as
`<name>.new`; files you created or deleted are left alone.

If anything fails: `tools/TROUBLESHOOTING.md`.

## Setup

The full step-by-step instructions are in the Pre-Workshop Setup Guide distributed by the instructor. In summary:

### Prerequisites

1. **Claude Code CLI** — Install with the native installer (no Node.js needed): `curl -fsSL https://claude.ai/install.sh | bash` on Mac, or `irm https://claude.ai/install.ps1 | iex` in PowerShell on Windows. Requires a Claude Pro or Max subscription.
2. **Python 3.11 or 3.12** — With `pandas`, `numpy`, `statsmodels`, `scipy`, `linearmodels`, `matplotlib`, `seaborn`, `scikit-learn`, and `openpyxl`
3. **Git** — For cloning this repo and version control exercises (required by Claude Code on Windows)
4. **VS Code** — With the Python, R, Claude Code, and LaTeX Workshop extensions
5. **A TeX distribution** — MacTeX/BasicTeX (Mac) or TeX Live/MiKTeX (Windows)
6. **R** (optional, for R users) and **Stata** (optional, requires your own licence)
7. **Node.js (LTS)** — Not needed at the start. Install it before Session 4, where the `claude-ignore` hook is installed with `npm`.

### Verify Your Setup

Run the one-command start above first (it downloads the course materials), then:

```bash
# Verify Git and Claude Code are installed
git --version
claude --version

# Verify Python dependencies (on Mac, use python3 if python is not found)
python -c "import pandas; import numpy; import statsmodels; import scipy; import linearmodels; import matplotlib; print('All good!')"

# Verify a TeX distribution is installed
pdflatex --version
```

## Workshop Sessions

| Session | Topic | Folder |
|---------|-------|--------|
| 1 | What Claude Code Is and How It Works | `session_1/` |
| 2 | Context Strategies, Parallel Sessions, Plan Mode, Verification | `session_2/` |
| 3 | Verification Through to the Paper: LaTeX and Git | `session_3/` |
| 4 | Power Use: Web Search, Agent Swarms, Connected Tools, Skills | `session_4/` |

`session_6/` through `session_9/` are empty placeholder folders reserved for later use; they are not used in the four-session format.

## License

MIT
