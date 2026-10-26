"""
Session 4 exercise: compare agent codes with reference codes.

Reads the agents' codes (passage_id, code) and the reference codes
(passage_id, gold_code) and reports raw agreement, Cohen's kappa, a
confusion matrix, and per-category agreement. Use it to check the numbers
Claude Code gives you; do not treat it as the only computation.

Run from the project root (AIAgentsCourse/ or your copy of session_4's parent).
Interactive use: run the constants and function definitions, then call
main() or the functions one at a time.
"""

import pandas as pd

AGENT_CODES_PATH = "session_4/output/agent_codes.csv"
REFERENCE_CODES_PATH = "session_4/data/climate_speeches/gold_codes.csv"
VALID_CODES = [1, 2, 3, 4]
CODE_LABELS = {1: "SUPPORTS_ACTION", 2: "OPPOSES_ACTION", 3: "NO_STANCE", 4: "NOT_CLIMATE"}


def load_and_merge(agent_path, reference_path):
    """Load both files, validate them, and return one row per passage_id."""
    agent = pd.read_csv(agent_path)
    reference = pd.read_csv(reference_path)

    for name, frame, column in [("agent", agent, "code"), ("reference", reference, "gold_code")]:
        assert "passage_id" in frame.columns and column in frame.columns, (
            f"{name} file needs columns passage_id and {column}; has {list(frame.columns)}"
        )
        assert frame["passage_id"].is_unique, f"{name} file has duplicate passage_id values"
        bad = frame.loc[~frame[column].isin(VALID_CODES), column].unique()
        assert len(bad) == 0, f"{name} file has codes outside {VALID_CODES}: {list(bad)}"

    # Report unmatched ids instead of silently dropping them.
    missing_from_agent = set(reference["passage_id"]) - set(agent["passage_id"])
    extra_in_agent = set(agent["passage_id"]) - set(reference["passage_id"])
    assert not missing_from_agent, f"{len(missing_from_agent)} reference passages have no agent code, e.g. {sorted(missing_from_agent)[:5]}"
    assert not extra_in_agent, f"{len(extra_in_agent)} agent passages are not in the reference, e.g. {sorted(extra_in_agent)[:5]}"

    merged = agent[["passage_id", "code"]].merge(
        reference[["passage_id", "gold_code"]], on="passage_id", how="inner", validate="one_to_one"
    )
    assert len(merged) == len(reference)
    return merged


def raw_agreement(merged):
    """Share of passages where the agent code equals the reference code."""
    return (merged["code"] == merged["gold_code"]).mean()


def cohens_kappa(merged):
    """Chance-corrected agreement: (observed - expected) / (1 - expected)."""
    observed = raw_agreement(merged)
    agent_share = merged["code"].value_counts(normalize=True).reindex(VALID_CODES, fill_value=0)
    reference_share = merged["gold_code"].value_counts(normalize=True).reindex(VALID_CODES, fill_value=0)
    expected = (agent_share * reference_share).sum()
    return (observed - expected) / (1 - expected)


def confusion_matrix(merged):
    """Rows = reference code, columns = agent code."""
    return pd.crosstab(
        merged["gold_code"], merged["code"], rownames=["reference"], colnames=["agent"]
    ).reindex(index=VALID_CODES, columns=VALID_CODES, fill_value=0)


def per_category_agreement(merged):
    """For each reference code, how many passages the agent also gave that code."""
    rows = []
    for code in VALID_CODES:
        subset = merged[merged["gold_code"] == code]
        rows.append({
            "reference_code": code,
            "label": CODE_LABELS[code],
            "n_reference": len(subset),
            "n_agent_agrees": int((subset["code"] == code).sum()),
            "agreement": (subset["code"] == code).mean() if len(subset) else float("nan"),
        })
    return pd.DataFrame(rows)


def main():
    merged = load_and_merge(AGENT_CODES_PATH, REFERENCE_CODES_PATH)
    print(f"Passages compared: {len(merged)}")
    print(f"Raw agreement:     {raw_agreement(merged):.3f}")
    print(f"Cohen's kappa:     {cohens_kappa(merged):.3f}")
    print("\nConfusion matrix (rows = reference, columns = agent):")
    print(confusion_matrix(merged))
    print("\nPer-category agreement:")
    print(per_category_agreement(merged).to_string(index=False))
    print("\nDisagreements (read these):")
    print(merged[merged["code"] != merged["gold_code"]].to_string(index=False))


if __name__ == "__main__":
    main()
