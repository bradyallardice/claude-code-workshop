#!/bin/bash
# assemble.sh --- concatenate all chapter files into a single story.
# Run after all PRs have been merged.
#
# Usage:
#   ./assemble.sh                         # default title
#   ./assemble.sh "The Conference From Hell"   # custom title

set -e

title="${1:-The Collaborative Story}"
output="story.md"

{
  echo "# $title"
  echo ""
  for f in chapters/chapter_*.md; do
    # Skip files that still contain the placeholder comment
    # (i.e., chapters no pair wrote)
    if grep -q "Drafter: replace this comment" "$f"; then
      continue
    fi
    cat "$f"
    echo ""
    echo "---"
    echo ""
  done
} > "$output"

echo "Assembled $(ls chapters/chapter_*.md | wc -l | tr -d ' ') chapter files into $output"
echo "(Chapters still containing the placeholder comment were skipped.)"
