# Claude Code Workshop: AI Agents in Academic Research

Workshop materials for learning how to use Claude Code as an AI-powered research assistant.

## Setup

### Prerequisites

1. **Claude Code CLI** — Install via `npm install -g @anthropic-ai/claude-code`
2. **Python 3.9+** — With `pandas`, `numpy`, `statsmodels`, `scipy`, and `matplotlib`
3. **Git** — For cloning this repo and version control exercises
4. **A text editor or IDE** — VS Code recommended (Claude Code has a VS Code extension)

### Verify Your Setup

```bash
# Clone the repo
git clone https://github.com/bradyallardice/claude-code-workshop.git
cd claude-code-workshop

# Verify Claude Code is installed
claude --version

# Verify Python dependencies
python -c "import pandas; import numpy; import statsmodels; import matplotlib; print('All good!')"
```

## Workshop Modules

| Module | Topic | Folder |
|--------|-------|--------|
| 1 | Introduction to Claude Code | `module_1/` |
| 2 | CLAUDE.md & Plan Mode | `module_2/` |
| 3 | Data Cleaning & Merging Pipelines | `module_3/` |
| 4 | Statistical Analysis & Visualization | `module_4/` |
| 5 | Debugging & Testing | `module_5/` |
| 6 | Git & Version Control with AI | (this repo itself) |

## License

MIT
