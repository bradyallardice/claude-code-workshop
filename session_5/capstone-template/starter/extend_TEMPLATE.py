# extend_TEMPLATE.py
# Extension analysis for Magistro et al. 2026 replication
#
# Fill in EXTENSION_LABEL and the analysis section for your assigned extension.
# Run from the repo root: python starter/extend_TEMPLATE.py

EXTENSION_LABEL = "A"  # change to "A", "B", or "C"

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import statsmodels.formula.api as smf
from itertools import product

# ── Load and reshape data ─────────────────────────────────────────────────────
# Copy your working reshape code from replicate_fig1.py here.
data = pd.read_csv("data/clean_AJPS.csv")
multi2_reshape = None  # replace with your reshape code

# ── Extension A: Framing × job type interaction ───────────────────────────────
# Does the AI vs. offshoring frame shift preferences differently for
# data science jobs (dsafter) vs. factory jobs (factoryafter)?
#
# Approach:
#   1. Estimate marginal means by treat_offshoring × job attribute (ds vs. factory).
#   2. Compute the AI–Offshoring difference for each job attribute level.
#   3. Plot: side-by-side panels, one per job type.
#   4. Test interaction significance with an OLS model including frame × job_type.

if EXTENSION_LABEL == "A":
    pass  # TODO: your Extension A code here

# ── Extension B: Robustness battery ──────────────────────────────────────────
# Specification grid:
#   attention_filter: "all" vs. "pass_only"
#   weights:          "unweighted" vs. "weighted"
#   estimator:        "ols" vs. "ologit"
#   task_fe:          False vs. True
#
# For each combination, run the main framing effect and record estimate + CI.
# Produce a specification curve (sorted by estimate) or robustness table.

if EXTENSION_LABEL == "B":
    from statsmodels.miscmodels.ordinal_model import OrderedModel
    pass  # TODO: your Extension B code here

# ── Extension C: Prior trade attitudes as moderator ───────────────────────────
# Variable: tables_policygr_5 (1–5, higher = more pro-trade)
# Median split → trade_support_hi / trade_support_lo
# Estimate marginal means by treat_offshoring within each group.
# Test moderation with an OLS interaction model.

if EXTENSION_LABEL == "C":
    pass  # TODO: your Extension C code here

# ── Save outputs ──────────────────────────────────────────────────────────────
# plt.savefig("paper/figures/extension_result.png", dpi=300, bbox_inches="tight")
