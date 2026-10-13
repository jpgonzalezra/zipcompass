#!/usr/bin/env bash
# Pushes the update branch and opens or refreshes its pull request. Runs in a
# session: the push needs an SSH agent and the pull request needs gh.
set -euo pipefail

project=$(cd "$(dirname "$0")/.." && pwd)
cd "$project"

ssh-add -l >/dev/null 2>&1 ||
  { echo "publish: no SSH agent with a key loaded; the push needs one" >&2; exit 1; }
gh auth status >/dev/null 2>&1 ||
  { echo "publish: gh is not authenticated; the pull request needs it" >&2; exit 1; }

git fetch -q origin
git checkout -q main
git merge -q --ff-only origin/main

log=$(mktemp)
body=$(mktemp)
trap 'rm -f "$log" "$body"' EXIT
set +e
ZIPS_DIR=${ZIPS_DIR:-$project/../zips} "$project/scripts/update.sh" | tee "$log"
status=${PIPESTATUS[0]}
set -e
[ "$status" -eq 0 ] || exit "$status"

summary=$(tail -n 1 "$log")
if [ "$summary" = "zipcompass: no change" ]; then
  echo "publish: nothing to publish, main carries the index of the current zips"
  exit 0
fi
if git merge-base --is-ancestor update main; then
  echo "publish: nothing to publish, update is not ahead of main"
  exit 0
fi

git push -q --force-with-lease origin update
short=${summary#*zips@}
short=${short%%,*}
report=${summary##*, }
open_prs=$(gh pr list --head update --state open --json number --jq '.[].number') ||
  { echo "publish: gh pr list failed; the branch is pushed, the pull request is not opened" >&2; exit 1; }
if [ -z "$open_prs" ]; then
  git show "update:$report" > "$body"
  gh pr create --base main --head update --title "Update the ZIP index to zips@$short" --body-file "$body"
else
  echo "publish: the push refreshed the open pull request"
fi
