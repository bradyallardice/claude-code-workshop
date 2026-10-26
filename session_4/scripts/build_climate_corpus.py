"""Build the climate-mentions corpus for the Session 4 LLM-coding exercise.

Source: the daily Congressional Record (GovInfo collection CREC), 118th Congress.
The script visits Record days in a seeded random order and stops once
TARGET_PASSAGES passages are collected. A fixed number of days does not work:
many Record days are pro forma sessions during recesses with no debate. For
each day visited, the script:
  1. downloads the day's package ZIP from the GovInfo API (one request per day),
  2. keeps speech granules -- granules with at least one member tagged
     role="SPEAKING" in the day's MODS metadata (this drops the Daily Digest,
     bill lists, and other non-speech sections),
  3. splits each speech into paragraphs and keeps every paragraph that matches
     KEYWORD_PATTERN (the unit of analysis is the paragraph),
  4. attributes each paragraph to a speaker using the turn markers in the text
     ("Mr. MERKLEY.") matched against the MODS speaker list,
  5. keeps at most MAX_PASSAGES_PER_DAY of the day's passages (seeded random
     draw), so that one long floor debate cannot dominate the corpus.

Outputs (session_4/data/climate_speeches/):
  - passages.csv          one row per climate-mentioning paragraph (student-facing)
  - gold_codes.csv        blank hand-coding sheet; written only if it does not
                          already exist, so hand codes are never overwritten
  - build_log.json        parameters, sampled days, and counts
  - raw/                  cached text and speaker metadata per day, so reruns
                          do not spend API requests

API key: set GOVINFO_API_KEY (free from api.data.gov). Without it the script
uses DEMO_KEY, which is limited to roughly 10 requests per hour. If the limit is
hit, rerun later: completed days are cached in raw/ and are not re-downloaded.

Run from the project root: python session_4/scripts/build_climate_corpus.py
"""

import html
import io
import json
import os
import random
import re
import xml.etree.ElementTree as ET
import zipfile
from datetime import datetime, timezone

import pandas as pd
# requests rather than urllib: requests verifies HTTPS with the certifi bundle,
# which works on python.org macOS installs that lack system CA certificates.
import requests

OUTPUT_DIR = os.path.join("session_4", "data", "climate_speeches")
RAW_DIR = os.path.join(OUTPUT_DIR, "raw")

# 118th Congress (2023-01-03 to 2025-01-03)
DATE_START = "2023-01-03"
DATE_END = "2025-01-03"
TARGET_PASSAGES = 60  # enough for a 20-minute fan-out exercise
MAX_PASSAGES_PER_DAY = 15
MAX_DAYS = 40  # stop even if the target is not reached
SEED = 20261026

# Matches climate, climatic, climates, climatologist. Deliberately broad: it also
# catches non-environmental uses ("business climate"), which the coding scheme
# has a category for.
KEYWORD_PATTERN = re.compile(r"\bclimat\w*", re.IGNORECASE)

API_BASE = "https://api.govinfo.gov"
MODS_NS = {"m": "http://www.loc.gov/mods/v3"}

# Turn markers that open a member's paragraph, e.g. "Mr. SMITH of Texas."
MEMBER_MARKER = re.compile(r"^(Mr|Ms|Mrs|Miss)\. ([^.]+?)\.(\s|$)")
# Presiding-officer turn markers; paragraphs after these are not a member's speech
PRESIDING_MARKER = re.compile(
    r"^The (PRESIDING OFFICER|SPEAKER pro tempore|SPEAKER|ACTING PRESIDENT pro "
    r"tempore|PRESIDENT pro tempore|Acting CHAIR|CHAIR|CHAIRMAN|VICE PRESIDENT)"
)


# ── API access ──────────────────────────────────────────────────────────────

def get_api_key():
    """Return the GovInfo API key from the environment, or DEMO_KEY with a warning."""
    key = os.environ.get("GOVINFO_API_KEY")
    if key:
        return key
    print("WARNING: GOVINFO_API_KEY not set; using DEMO_KEY (about 10 requests/hour).")
    return "DEMO_KEY"


def api_get(url):
    """GET a URL and return the response bytes. Raises a clear error on rate limiting."""
    response = requests.get(url, timeout=300)
    if response.status_code == 429:
        raise RuntimeError(
            "GovInfo rate limit reached. Completed days are cached in "
            f"{RAW_DIR}; rerun later or set GOVINFO_API_KEY."
        )
    response.raise_for_status()
    return response.content


def list_crec_packages(api_key):
    """List CREC package IDs issued between DATE_START and DATE_END (cached to raw/)."""
    cache_path = os.path.join(RAW_DIR, "package_list.json")
    if os.path.exists(cache_path):
        with open(cache_path) as f:
            return json.load(f)

    package_ids = []
    url = (f"{API_BASE}/published/{DATE_START}/{DATE_END}"
           f"?collection=CREC&pageSize=1000&offsetMark=%2A&api_key={api_key}")
    while url:
        page = json.loads(api_get(url))
        package_ids += [p["packageId"] for p in page["packages"]]
        next_page = page.get("nextPage")
        url = f"{next_page}&api_key={api_key}" if next_page else None

    package_ids = sorted(set(package_ids))
    os.makedirs(RAW_DIR, exist_ok=True)
    with open(cache_path, "w") as f:
        json.dump(package_ids, f, indent=1)
    return package_ids


def sample_days(package_ids, n_days, seed):
    """Draw a reproducible random sample of Record days, returned in date order."""
    return sorted(random.Random(seed).sample(package_ids, n_days))


# ── Parsing one day's package ───────────────────────────────────────────────

def parse_speakers(mods_xml):
    """Map each granule ID to its title and its SPEAKING members, from the day's MODS."""
    root = ET.fromstring(mods_xml)
    granules = {}
    for item in root.findall("m:relatedItem[@type='constituent']", MODS_NS):
        granule_id = item.get("ID", "").removeprefix("id-")
        title = item.findtext("m:titleInfo/m:title", default="", namespaces=MODS_NS)
        members = []
        for member in item.iter(f"{{{MODS_NS['m']}}}congMember"):
            if member.get("role") != "SPEAKING":
                continue
            names = {n.get("type"): n.text for n in member.findall("m:name", MODS_NS)}
            members.append({
                "parsed_name": names.get("parsed"),
                "full_name": names.get("authority-fnf"),
                "party": member.get("party"),
                "state": member.get("state"),
                "chamber": member.get("chamber"),
                "bioguide_id": member.get("bioGuideId"),
            })
        granules[granule_id] = {"title": title, "members": members}
    return granules


def html_to_text(raw_html):
    """Extract the plain text of a granule from its <pre> block."""
    match = re.search(r"<pre>(.*)</pre>", raw_html, re.DOTALL)
    body = match.group(1) if match else raw_html
    return html.unescape(re.sub(r"<[^>]+>", "", body))


def process_day_zip(zip_bytes, package_id):
    """Keep speech granules that mention the keyword; return {granule_id: record}.

    A record holds the granule title, its SPEAKING members, and its plain text.
    """
    with zipfile.ZipFile(io.BytesIO(zip_bytes)) as archive:
        mods_name = next(n for n in archive.namelist() if n.endswith("/mods.xml"))
        speakers = parse_speakers(archive.read(mods_name))
        kept = {}
        for name in archive.namelist():
            if not (name.endswith(".htm") and "/html/" in name):
                continue
            granule_id = os.path.basename(name).removesuffix(".htm")
            granule = speakers.get(granule_id)
            if granule is None or not granule["members"]:
                continue  # not a speech granule
            text = html_to_text(archive.read(name).decode("utf-8", errors="replace"))
            if KEYWORD_PATTERN.search(text):
                kept[granule_id] = {**granule, "text": text}
    return kept


def fetch_day(package_id, api_key):
    """Download and process one day, caching the result in raw/<package_id>.json."""
    cache_path = os.path.join(RAW_DIR, f"{package_id}.json")
    if os.path.exists(cache_path):
        with open(cache_path) as f:
            return json.load(f)

    print(f"  downloading {package_id} ...")
    zip_bytes = api_get(f"{API_BASE}/packages/{package_id}/zip?api_key={api_key}")
    kept = process_day_zip(zip_bytes, package_id)
    os.makedirs(RAW_DIR, exist_ok=True)
    with open(cache_path, "w") as f:
        json.dump(kept, f, indent=1)
    return kept


# ── Paragraphs and speaker attribution ──────────────────────────────────────

def split_paragraphs(text):
    """Split Record text into paragraphs.

    A paragraph starts on a line indented by exactly two spaces; unindented lines
    continue it. Deeper-indented lines (centered section titles) and the bracketed
    header lines end the current paragraph and are dropped.
    """
    paragraphs, current = [], []
    for line in text.splitlines():
        if re.match(r"^  \S", line):
            if current:
                paragraphs.append(" ".join(current))
            current = [line.strip()]
        elif re.match(r"^\S", line) and current and not line.startswith("["):
            current.append(line.strip())
        else:
            if current:
                paragraphs.append(" ".join(current))
            current = []
    if current:
        paragraphs.append(" ".join(current))
    return [re.sub(r"\s+", " ", p) for p in paragraphs]


def attribute_paragraphs(paragraphs, members):
    """Yield (paragraph, member_or_None, method) for each paragraph of a granule.

    method is one of:
      marker         the paragraph or an earlier one opened with a member's turn
                     marker matching a SPEAKING member's parsed name
      single_speaker no marker seen yet, but the granule has exactly one SPEAKING
                     member (typical of Extensions of Remarks)
      presiding      the current turn belongs to the presiding officer
      unattributed   none of the above
    """
    by_marker = {m["parsed_name"]: m for m in members if m["parsed_name"]}
    current, method = None, "unattributed"
    if len(members) == 1:
        current, method = members[0], "single_speaker"
    for paragraph in paragraphs:
        member_match = MEMBER_MARKER.match(paragraph)
        if member_match:
            marker = f"{member_match.group(1)}. {member_match.group(2)}"
            if marker in by_marker:
                current, method = by_marker[marker], "marker"
            else:
                current, method = None, "unattributed"
        elif PRESIDING_MARKER.match(paragraph):
            current, method = None, "presiding"
        yield paragraph, current, method


def extract_passages(day_records, package_id):
    """Return one dict per keyword-matching paragraph across a day's speech granules."""
    date = package_id.removeprefix("CREC-")
    rows = []
    for granule_id, record in sorted(day_records.items()):
        paragraphs = split_paragraphs(record["text"])
        for paragraph, member, method in attribute_paragraphs(paragraphs, record["members"]):
            matches = KEYWORD_PATTERN.findall(paragraph)
            if not matches:
                continue
            member = member or {}
            rows.append({
                "date": date,
                "granule_id": granule_id,
                "section_title": record["title"],
                "speaker_name": member.get("full_name"),
                "party": member.get("party"),
                "state": member.get("state"),
                "chamber": member.get("chamber"),
                "bioguide_id": member.get("bioguide_id"),
                "attribution": method,
                "matched_terms": "; ".join(sorted({m.lower() for m in matches})),
                "passage_text": paragraph,
                "source_url": (f"https://www.govinfo.gov/content/pkg/{package_id}"
                               f"/html/{granule_id}.htm"),
            })
    return rows


# ── Outputs ─────────────────────────────────────────────────────────────────

def build_passage_table(all_rows):
    """Assemble, validate, and number the passage table."""
    passages = pd.DataFrame(all_rows)
    passages.insert(0, "passage_id", [f"P{i:03d}" for i in range(1, len(passages) + 1)])

    assert passages["passage_id"].is_unique
    assert passages["passage_text"].str.len().gt(0).all(), "empty passage text"
    assert passages["passage_text"].str.contains(KEYWORD_PATTERN).all(), \
        "a passage does not contain the keyword"
    duplicated_text = passages["passage_text"].duplicated().sum()
    if duplicated_text:
        print(f"  NOTE: {duplicated_text} passages repeat an earlier passage's text verbatim.")
    return passages


def write_gold_template(passages, path):
    """Write the blank hand-coding sheet, unless one already exists."""
    if os.path.exists(path):
        print(f"  {path} exists; not overwritten (it may contain hand codes).")
        return
    template = passages[["passage_id"]].copy()
    template["gold_code"] = ""
    template["coder"] = ""
    template["notes"] = ""
    template.to_csv(path, index=False)
    print(f"  wrote blank coding sheet -> {path}")


def main():
    api_key = get_api_key()
    package_ids = list_crec_packages(api_key)
    days = sample_days(package_ids, N_DAYS, SEED)
    print(f"{len(package_ids)} Record days in {DATE_START}..{DATE_END}; sampled {len(days)}:")
    print("  " + ", ".join(d.removeprefix("CREC-") for d in days))

    all_rows = []
    for package_id in days:
        all_rows += extract_passages(fetch_day(package_id, api_key), package_id)

    passages = build_passage_table(all_rows)
    passages_path = os.path.join(OUTPUT_DIR, "passages.csv")
    passages.to_csv(passages_path, index=False)
    write_gold_template(passages, os.path.join(OUTPUT_DIR, "gold_codes.csv"))

    counts = {
        "passages": len(passages),
        "granules": int(passages["granule_id"].nunique()),
        "by_day": passages["date"].value_counts().sort_index().to_dict(),
        "by_attribution": passages["attribution"].value_counts().to_dict(),
        "by_party": passages["party"].fillna("none").value_counts().to_dict(),
    }
    build_log = {
        "built_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "source": "GovInfo API, collection CREC",
        "date_range": [DATE_START, DATE_END],
        "n_record_days_in_range": len(package_ids),
        "seed": SEED,
        "sampled_days": days,
        "keyword_pattern": KEYWORD_PATTERN.pattern,
        "unit": "paragraph within a speech granule",
        "counts": counts,
    }
    with open(os.path.join(OUTPUT_DIR, "build_log.json"), "w") as f:
        json.dump(build_log, f, indent=1)

    print(f"\n{len(passages)} passages -> {passages_path}")
    print(json.dumps(counts, indent=1))


if __name__ == "__main__":
    main()
