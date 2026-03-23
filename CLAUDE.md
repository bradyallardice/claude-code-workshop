# CLAUDE.md — Project Configuration

This is the CLAUDE.md file for the workshop repository. It tells Claude Code about the project context.

## Project Overview

This is a teaching repository for a workshop on using Claude Code in academic research. Each `module_N/` folder contains exercises and demo data for that module.

## Conventions

- Python scripts should use pandas for data manipulation
- Use descriptive variable names appropriate for academic audiences
- All data files are CSV format
- Scripts should include docstrings explaining their purpose
- Scripts must also be runnable interactively in VS Code (Shift+Enter line by line)
- Use hardcoded relative paths from the project root (e.g., "module_1/data/") instead of __file__-based paths
- Always assume scripts are run from the project root (AIAgentsCourse/)
- Keep function definitions separate from execution so individual functions can be tested interactively

## Data

- Demo and exercise datasets are synthetic / anonymized
- Data files live inside their respective module folders
