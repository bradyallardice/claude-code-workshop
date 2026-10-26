#!/usr/bin/env bash
# invite_collaborators.sh — bulk-invite a class roster to a GitHub repo, and
# report who has / has not accepted.
#
# Requires the GitHub CLI, logged in as the repo owner:  gh auth login
#
# Usage (from anywhere):
#   bash invite_collaborators.sh status OWNER/REPO roster.csv
#   bash invite_collaborators.sh invite OWNER/REPO roster.csv
#
# roster.csv: header line "name,github", then one student per line. The github
# column may contain a bare username, "@username" or a github.com URL; all are
# normalised. Lines starting with # are ignored.
#
# What "invite" does for each student:
#   - username does not exist on GitHub  -> reported as BAD USERNAME, skipped
#   - already a collaborator             -> skipped
#   - pending invitation, not expired    -> skipped (they still need to accept)
#   - pending invitation, EXPIRED        -> old invitation deleted, new one sent
#   - otherwise                          -> invitation sent
# GitHub invitations expire after 7 days, so re-run "invite" a few days before
# class to refresh any that lapsed. Re-running is safe.

set -u

MODE="${1:-}"; REPO="${2:-}"; ROSTER="${3:-}"
if [ -z "$MODE" ] || [ -z "$REPO" ] || [ -z "$ROSTER" ]; then
    sed -n '2,14p' "$0"; exit 1
fi
if [ "$MODE" != "status" ] && [ "$MODE" != "invite" ]; then
    echo "Error: mode must be 'status' or 'invite'"; exit 1
fi
[ -f "$ROSTER" ] || { echo "Error: roster file not found: $ROSTER"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "Error: GitHub CLI (gh) not installed"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Error: run 'gh auth login' first"; exit 1; }

lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

# Current state of the repo, fetched once. Usernames compared case-insensitively.
COLLABORATORS="$(gh api "repos/$REPO/collaborators" --paginate --jq '.[].login' | tr '[:upper:]' '[:lower:]')" \
    || { echo "Error: cannot read collaborators of $REPO (wrong name, or you are not the owner?)"; exit 1; }
# One line per pending invitation: "<id> <login> <expired true|false>"
INVITATIONS="$(gh api "repos/$REPO/invitations" --paginate --jq '.[] | "\(.id) \(.invitee.login | ascii_downcase) \(.expired)"')"

ROWS="$(mktemp)"
printf "%-28s %-24s %s\n" "NAME" "GITHUB" "STATUS"

# tail -n +2 skips the header; the final 'echo' lets a last line without newline through.
{ tail -n +2 "$ROSTER"; echo; } | while IFS=, read -r NAME HANDLE _rest; do
    case "$NAME" in ''|\#*) continue ;; esac
    # Normalise: strip spaces, CR (Excel-saved CSVs), @, and github.com URLs.
    USER="$(echo "$HANDLE" | tr -d ' \r' | sed -e 's|^https\{0,1\}://github.com/||' -e 's|/.*$||' -e 's|^@||')"
    USER_LC="$(lower "$USER")"

    if [ -z "$USER" ]; then
        STATUS="NO USERNAME IN ROSTER"
    elif echo "$COLLABORATORS" | grep -qx "$USER_LC"; then
        STATUS="accepted"
    else
        INV_LINE="$(echo "$INVITATIONS" | awk -v u="$USER_LC" '$2 == u')"
        if [ -n "$INV_LINE" ] && [ "$(echo "$INV_LINE" | awk '{print $3}')" = "false" ]; then
            STATUS="pending (not accepted yet)"
        elif [ "$MODE" = "status" ]; then
            if [ -n "$INV_LINE" ]; then STATUS="EXPIRED invitation"; else STATUS="NOT INVITED"; fi
        else
            # invite mode: verify the account exists before inviting
            if ! gh api "users/$USER" >/dev/null 2>&1; then
                STATUS="BAD USERNAME (no such GitHub account)"
            else
                if [ -n "$INV_LINE" ]; then
                    gh api -X DELETE "repos/$REPO/invitations/$(echo "$INV_LINE" | awk '{print $1}')" >/dev/null 2>&1
                fi
                if gh api -X PUT "repos/$REPO/collaborators/$USER" -f permission=push >/dev/null 2>&1; then
                    if [ -n "$INV_LINE" ]; then STATUS="re-invited (old one expired)"; else STATUS="invited"; fi
                else
                    STATUS="INVITE FAILED (rate limit or permissions; re-run later)"
                fi
            fi
        fi
    fi
    printf "%-28s %-24s %s\n" "$NAME" "${USER:--}" "$STATUS"
done > "$ROWS"

cat "$ROWS"
echo ""
echo "Summary (status: count):"
# Status starts at character 55 (28 + 1 + 24 + 1 + 1); group "re-invited (...)" etc. by text before " (".
cut -c55- "$ROWS" | sed 's/ (.*//' | sort | uniq -c | sort -rn
rm -f "$ROWS"
