# Climate Mentions in the Congressional Record (118th Congress)

The corpus for the Session 4 exercise "LLMs as research coders": fan out agents to code passages, then validate their codes against a hand-coded gold set.

## Files

| File | Contents | Students? |
|---|---|---|
| `passages.csv` | One row per climate-mentioning paragraph: text, speaker, party, state, chamber, date, section title, source URL | yes |
| `coding_scheme.md` | Codes and decision rules (draft) | yes |
| `gold_codes.csv` | Reference codes keyed by `passage_id`, with notes on hard cases (Claude-generated; see below) | **no**, stripped by `sync_student.sh` |
| `build_log.json` | Build parameters, days visited, counts | yes |
| `raw/` | Cached speech text and speaker metadata per Record day, so rebuilds don't re-download | yes |

## How the corpus was built

Built by [`session_4/scripts/build_climate_corpus.py`](../../scripts/build_climate_corpus.py) from GovInfo's daily Congressional Record (collection `CREC`). The list of Record days comes from the GovInfo API, and each day's package from govinfo.gov's public download path.

1. **Frame.** All Record days issued from 2023-01-03 to 2025-01-03 (118th Congress).
2. **Order.** Days are visited in a seeded random order (`SEED` in the script). Visiting stops once 60 passages are collected. Many Record days are pro forma recess sessions with no debate, so a fixed number of days yields few passages.
3. **Speeches only.** A granule (one section of the Record) counts as a speech if the day's MODS metadata lists at least one member with `role="SPEAKING"`. This excludes the Daily Digest, bill lists, and resolution texts.
4. **Unit and keyword.** Paragraphs matching `\bclimat\w*` (case-insensitive). This is deliberately broad: it also catches "business climate", which code 4 exists for.
5. **Speaker attribution.** Each paragraph is assigned to the speaker whose turn marker ("Mr. SMITH of Texas.") most recently opened it. Markers are matched against the MODS speaker list, which supplies party, state, chamber, and Bioguide ID. The `attribution` column records how each passage was assigned (`marker`, `single_speaker`, `presiding`, `unattributed`).
6. **Cap.** At most 15 passages per day, drawn at random, so one long floor debate cannot dominate.

Participants do not need to rebuild: the exercise uses `passages.csv`. To rebuild, install `requests` (`python -m pip install requests`; it is not part of the course setup), then run `python session_4/scripts/build_climate_corpus.py` from the project root. With the cache in `raw/`, a rebuild needs no network access. If the list of Record days has to be refetched, set `GOVINFO_API_KEY` (free from api.data.gov), because `DEMO_KEY` has low hourly and daily caps. A rebuild refuses to run if `gold_codes.csv` no longer matches the passage IDs.

## Known limitations

- **Inserted material.** When a member inserts a letter or article into the Record, its paragraphs are attributed to that member. Decision rule 2 in the coding scheme covers this for coding, but the `speaker_name` column does not distinguish it.
- **The sample is not representative of all climate talk in Congress.** It is a seeded random sample of days with a per-day cap, built for a teaching exercise, not for estimating prevalence.
- **Party is visible in `passages.csv`.** If the exercise asks agents to code from the full row, party is available as a shortcut cue. Whether coders, human or LLM, lean on it is a possible debrief question. To remove it, give agents only `passage_id` and `passage_text`.

## About the reference codes

`gold_codes.csv` was coded by Claude (Opus 5.5) from `coding_scheme.md`, passage by passage. This was a deliberate choice: the exercise demonstrates the validation *workflow*, not a validated measure.

- **Agreement will look better than it is.** Participants' agents are also Claude, so part of their agreement with these codes is the same model agreeing with itself. Treat the agreement rate as a demonstration of how to compute and read one. In a real project, the reference set must come from human coders, ideally two, so that LLM–human agreement can be compared with human–human agreement.
- **Hard cases are flagged.** 7 passages have notes starting "Hard case", where another code is defensible. These are where disagreement is expected and is the most useful debrief material.
- **Party is a near-perfect proxy in this sample.** Every code 1 is a Democrat. Every code 2 is a Republican or an unattributed passage (Senate leader remarks, McConnell or Thune). An agent that sees the `party` column could score well by using it as a shortcut.
- **Distribution:** 38 supports, 18 opposes, 5 no stance, 2 not climate.
