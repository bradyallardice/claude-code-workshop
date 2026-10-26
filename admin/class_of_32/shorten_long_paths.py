"""Shorten over-long Zotero PDF filenames so the repo checks out on Windows.

Windows limits a full path to 260 characters unless long paths are switched on
(they are off by default), and git cannot write longer paths there even with
core.longpaths. A few Zotero-exported PDFs have relative paths of 150-193
characters, which pass 260 under a OneDrive or Documents folder.

For every tracked file under a Zotero `files/` folder whose repo-relative path
is longer than MAX_PATH_LENGTH, this script renames it to <Author>_<Year>.pdf
in the same folder (`git mv`) and updates the one `<z:path rdf:resource=...>`
line that points to it in the .rdf next to that `files/` folder.

Run from the repository root:
    python admin/class_of_32/shorten_long_paths.py          # dry run: show the plan
    python admin/class_of_32/shorten_long_paths.py --apply  # rename and update the .rdf files
"""

import re
import subprocess
import sys
import unicodedata
from pathlib import Path

MAX_PATH_LENGTH = 110


def tracked_files():
    """Return repo-relative paths of all tracked files (handles non-ASCII names)."""
    result = subprocess.run(["git", "ls-files", "-z"], capture_output=True, check=True)
    return [p for p in result.stdout.decode("utf-8").split("\0") if p]


def short_name(filename):
    """'Gallego and Kurer - 2022 - Automation ....pdf' -> 'Gallego_2022.pdf'."""
    parts = filename.split(" - ")
    author_part = parts[0]
    year_match = re.search(r"(19|20)\d\d", filename)
    if year_match is None:
        raise ValueError(f"no year in filename: {filename}")
    first_author = re.split(r"\s+(?:et al\.?|and)(?:\s+|$)|,", author_part)[0]
    ascii_author = unicodedata.normalize("NFKD", first_author).encode("ascii", "ignore").decode()
    ascii_author = re.sub(r"[^A-Za-z0-9]", "", ascii_author)[:24] or "paper"
    return f"{ascii_author}_{year_match.group(0)}{Path(filename).suffix}"


def plan_renames(paths):
    """List (old_path, new_path, rdf_path) for every over-long Zotero file."""
    plan = []
    for path in paths:
        if "/files/" not in path or len(path) <= MAX_PATH_LENGTH:
            continue
        zotero_dir, inside = path.split("/files/", 1)
        rdf_files = sorted(Path(zotero_dir).glob("*.rdf"))
        if len(rdf_files) != 1:
            raise ValueError(f"expected one .rdf in {zotero_dir}, found {len(rdf_files)}")
        old = Path(path)
        new = old.with_name(short_name(old.name))
        plan.append((old, new, rdf_files[0]))
    return plan


def rdf_reference(path, zotero_dir):
    """The rdf:resource value for a file, e.g. 'files/2005/Gallego_2022.pdf'."""
    return Path(path).relative_to(zotero_dir).as_posix()


def apply_plan(plan):
    rdf_text = {}
    for old, new, rdf in plan:
        text = rdf_text.setdefault(rdf, rdf.read_text(encoding="utf-8"))
        old_ref = f'rdf:resource="{rdf_reference(old, rdf.parent)}"'
        new_ref = f'rdf:resource="{rdf_reference(new, rdf.parent)}"'
        count = text.count(old_ref)
        if count != 1:
            raise ValueError(f"{rdf}: expected 1 reference to {old.name}, found {count}; nothing changed")
        rdf_text[rdf] = text.replace(old_ref, new_ref)
    # All references found: now change files.
    for old, new, _ in plan:
        subprocess.run(["git", "mv", str(old), str(new)], check=True)
    for rdf, text in rdf_text.items():
        rdf.write_text(text, encoding="utf-8")
        subprocess.run(["git", "add", str(rdf)], check=True)


def check_rdf_links(rdf_paths):
    """Every z:path in each .rdf must point to an existing file."""
    missing = []
    for rdf in rdf_paths:
        for ref in re.findall(r'<z:path rdf:resource="([^"]+)"', rdf.read_text(encoding="utf-8")):
            if not (rdf.parent / ref).exists():
                missing.append(f"{rdf}: {ref}")
    return missing


def main():
    apply = "--apply" in sys.argv
    plan = plan_renames(tracked_files())
    if not plan:
        print(f"No Zotero files with paths over {MAX_PATH_LENGTH} characters. Nothing to do.")
        return
    for old, new, rdf in plan:
        print(f"{len(str(old)):4d} -> {len(str(new)):3d}  {old.name}  ->  {new.name}")
    print(f"\n{len(plan)} file(s) over {MAX_PATH_LENGTH} characters, in {len({r for _, _, r in plan})} library folder(s).")
    if not apply:
        print("Dry run. Re-run with --apply to rename and update the .rdf files.")
        return
    apply_plan(plan)
    missing = check_rdf_links({rdf for _, _, rdf in plan})
    if missing:
        print("ERROR: .rdf links that point to missing files:\n  " + "\n  ".join(missing))
        sys.exit(1)
    longest = max(len(p) for p in tracked_files())
    print(f"Applied. All .rdf links resolve. Longest tracked path is now {longest} characters.")


if __name__ == "__main__":
    main()
