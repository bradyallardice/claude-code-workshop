# Climate Mentions in the Congressional Record (118th Congress)

The corpus for the Session 4 exercise "LLMs as research coders": fan out agents to code passages, then validate their codes against a hand-coded gold set.

## Files

| File | Contents | Students? |
|---|---|---|
| `passages.csv` | One row per climate-mentioning paragraph: text, speaker, party, state, chamber, date, section title, source URL | yes |
| `coding_scheme.md` | Codes and decision rules (draft) | yes |
| `gold_codes.csv` | Hand-coding sheet keyed by `passage_id`; blank until the instructor codes it | **no**, stripped by `sync_student.sh` |
| `build_log.json` | Build parameters, days visited, counts | yes |
| `raw/` | Cached speech text and speaker metadata per Record day, so rebuilds don't re-download | yes |

## How the corpus was built

Built by [`session_4/scripts/build_climate_corpus.py`](../../scripts/build_climate_corpus.py) from the GovInfo API (collection `CREC`, the daily Congressional Record).

1. **Frame.** All Record days issued from 2023-01-03 to 2025-01-03 (118th Congress).
2. **Order.** Days are visited in a seeded random order (`SEED` in the script). Visiting stops once 60 passages are collected. Many Record days are pro forma recess sessions with no debate, so a fixed number of days yields few passages.
3. **Speeches only.** A granule (one section of the Record) counts as a speech if the day's MODS metadata lists at least one member with `role="SPEAKING"`. This excludes the Daily Digest, bill lists, and resolution texts.
4. **Unit and keyword.** Paragraphs matching `\bclimat\w*` (case-insensitive). This is deliberately broad: it also catches "business climate", which code 4 exists for.
5. **Speaker attribution.** Each paragraph is assigned to the speaker whose turn marker ("Mr. SMITH of Texas.") most recently opened it. Markers are matched against the MODS speaker list, which supplies party, state, chamber, and Bioguide ID. The `attribution` column records how each passage was assigned (`marker`, `single_speaker`, `presiding`, `unattributed`).
6. **Cap.** At most 15 passages per day, drawn at random, so one long floor debate cannot dominate.

To rebuild, run `python session_4/scripts/build_climate_corpus.py` from the project root. A free api.data.gov key in `GOVINFO_API_KEY` avoids `DEMO_KEY`'s limit of about 10 requests per hour.

## Known limitations

- **Inserted material.** When a member inserts a letter or article into the Record, its paragraphs are attributed to that member. Decision rule 2 in the coding scheme covers this for coding, but the `speaker_name` column does not distinguish it.
- **The sample is not representative of all climate talk in Congress.** It is a seeded random sample of days with a per-day cap, built for a teaching exercise, not for estimating prevalence.
- **Party is visible in `passages.csv`.** If the exercise asks agents to code from the full row, party is available as a shortcut cue. Whether coders, human or LLM, lean on it is a possible debrief question. To remove it, give agents only `passage_id` and `passage_text`.

## Gold codes: how to make them meaningful

The gold codes must be **human** codes, made **before** class and without LLM assistance. Codes produced or pre-filled by Claude would make the validation circular, because the exercise compares LLM coding with itself.

An LLM–human agreement rate is only interpretable next to human–human agreement on the same passages. If a second person codes at least a subset (e.g., 30 passages) independently, the debrief can compare LLM agreement against intercoder reliability, not against an implicit 100%.
