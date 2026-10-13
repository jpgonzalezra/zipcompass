#!/usr/bin/env bash
# Rebuilds the update branch: the index regenerated from upstream zcash/zips
# on top of the published baseline, plus a report of what changed since the
# published index. Exit 0 when the run completed (no change upstream, or the
# branch was rebuilt), 75 when it skipped for a reason the next run resolves
# on its own, 1 when the operator has to look.
set -euo pipefail

project=$(cd "$(dirname "$0")/.." && pwd)
zips_dir=${ZIPS_DIR:-$project/../zips}
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/zipcompass
references=skills/zips/references
index=$references/index.md
today=$(date -u +%F)
report=reports/$today.md
fetch=1

for argument in "$@"; do
  case $argument in
    --no-fetch) fetch=0 ;;
    *) echo "usage: update.sh [--no-fetch]" >&2; exit 1 ;;
  esac
done

export GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND='ssh -o BatchMode=yes'

summary=
start_ref=
building=0
work=$(mktemp -d)
build_log=$work/build.log
changes=$work/changes.tsv
old_index=$work/baseline-index.md
tab=$(printf '\t')

skip() {
  summary="zipcompass: skipped, $*"
  exit 75
}

fail() {
  summary="zipcompass: failed, $*"
  exit 1
}

# What a failed build leaves for the operator: the end of the build output and
# the report, when the run got that far.
keep_failure() {
  local kept=$state_dir/failed-$today.md
  {
    echo "# zipcompass run of $today: $summary"
    echo
    if [ -s "$build_log" ]; then
      echo "## Last lines of the build"
      echo
      echo '```'
      tail -n 40 "$build_log"
      echo '```'
      echo
    fi
    if [ -f "$project/$report" ]; then
      echo "## The report built before the failure"
      echo
      cat "$project/$report"
    fi
  } > "$kept"
  summary="$summary, see $kept"
}

finish() {
  local status=$?
  if [ "$status" -ne 0 ] && [ -z "$summary" ]; then
    summary="zipcompass: failed, unexpected error (exit $status)"
    status=1
  fi
  if [ "$building" = 1 ]; then
    [ "$status" -eq 0 ] || keep_failure
    git -C "$project" checkout -q -f "$start_ref" ||
      echo "zipcompass: could not return to $start_ref" >&2
    git -C "$project" clean -q -f -- "$report" || true
    rmdir "$project/reports" 2>/dev/null || true
  fi
  rm -rf "$work"
  echo "$summary"
  exit "$status"
}
trap finish EXIT
trap 'fail "interrupted by a signal"' TERM INT HUP

mkdir -p "$state_dir"
if command -v flock >/dev/null 2>&1; then
  exec 9>"$state_dir/lock"
  flock -n 9 || skip "another run holds the lock"
else
  echo "zipcompass: flock is not installed, running without a lock" >&2
fi

[ -d "$zips_dir/zips" ] && git -C "$zips_dir" rev-parse --show-toplevel >/dev/null 2>&1 ||
  fail "$zips_dir is not a zips checkout"
zips_dir=$(cd "$zips_dir" && pwd)
[ -z "$(git -C "$project" status --porcelain)" ] || skip "uncommitted changes in $project"
[ "$(git -C "$zips_dir" symbolic-ref --short -q HEAD || true)" = main ] || skip "the zips checkout is not on main"
[ -z "$(git -C "$zips_dir" status --porcelain)" ] || skip "the zips checkout has local changes"
start_ref=$(git -C "$project" symbolic-ref --short -q HEAD || git -C "$project" rev-parse HEAD)

baseline=main
baseline_note='the local `main` (`--no-fetch`)'
if [ "$fetch" = 1 ]; then
  if git -C "$project" fetch -q origin; then
    baseline=origin/main
    baseline_note='`origin/main`'
  else
    echo "zipcompass: cannot fetch origin, using the local main as the baseline" >&2
    baseline_note='the local `main`, since `origin` could not be fetched'
  fi
fi
git -C "$project" show "$baseline:$index" > "$old_index" || fail "no index on $baseline"
source_old=$(head -n 1 "$old_index" | grep -oE '\b[0-9a-f]{40}\b') ||
  fail "no zips commit in the index header on $baseline"

if [ "$fetch" = 1 ]; then
  git -c url.https://github.com/.insteadOf=git@github.com: -C "$zips_dir" fetch -q origin ||
    skip "the zips fetch failed"
  git -C "$zips_dir" merge -q --ff-only origin/main ||
    fail "the zips checkout cannot fast-forward to origin/main"
  [ "$(git -C "$zips_dir" rev-parse HEAD)" = "$(git -C "$zips_dir" rev-parse origin/main)" ] ||
    fail "the zips checkout is ahead of origin/main: it carries commits upstream does not have"
fi
source_new=$(git -C "$zips_dir" rev-parse HEAD)
git -C "$zips_dir" merge-base --is-ancestor "$source_old" "$source_new" ||
  fail "zips@${source_old:0:8}, the index commit, is not an ancestor of zips@${source_new:0:8}: upstream rewrote history, or the checkout lacks it"

if [ "$source_old" = "$source_new" ]; then
  summary="zipcompass: no change"
  exit 0
fi
range=$source_old..$source_new

commit_date() {
  git -C "$zips_dir" log -1 --format=%cs "$1"
}

subjects() { # <path>... -> the commits in the range that touched them, renames followed for one path
  if [ $# -eq 1 ]; then
    git -C "$zips_dir" -c core.abbrev=8 log --follow --format='  - `%h` %s' "$range" -- "$1"
  else
    git -C "$zips_dir" -c core.abbrev=8 log --format='  - `%h` %s' "$range" -- "$@"
  fi
}

status_word() {
  case $1 in
    A*) echo added ;;
    M*) echo modified ;;
    D*) echo deleted ;;
    *) echo "$1" ;;
  esac
}

file_section() { # <title> <status letters> <drafts: yes|no>
  local title=$1 letters=$2 drafts=$3 rows status path
  rows=$(awk -F'\t' -v letters="$letters" -v drafts="$drafts" '
    index(letters, substr($1, 1, 1)) && (($2 ~ /^zips\/draft-/) == (drafts == "yes"))' "$changes")
  [ -n "$rows" ] || return 0
  echo "## $title"
  echo
  while IFS=$tab read -r status path; do
    if [ "$drafts" = yes ]; then
      echo "- \`$path\`, $(status_word "$status")"
    else
      echo "- \`$path\`"
    fi
    subjects "$path"
  done <<<"$rows"
  echo
}

renamed_section() {
  local rows old new
  rows=$(awk -F'\t' '$1 ~ /^R/' "$changes")
  [ -n "$rows" ] || return 0
  echo "## Renamed"
  echo
  while IFS=$tab read -r _ old new; do
    echo "- \`$old\` to \`$new\`"
    subjects "$old" "$new"
  done <<<"$rows"
  echo
}

index_statuses() { # <index file> -> "zip<TAB>status", sorted for join
  awk -F' \\| ' '/^\| / { sub(/^\| /, "", $1); if ($1 != "ZIP") print $1 "\t" $3 }' "$1" | LC_ALL=C sort
}

transitions_section() {
  local rows
  rows=$(LC_ALL=C join -t "$tab" -a 1 -a 2 -e absent -o 0,1.2,2.2 \
    <(index_statuses "$old_index") <(index_statuses "$project/$index") | awk -F'\t' '$2 != $3')
  echo "## Status transitions"
  echo
  if [ -n "$rows" ]; then
    echo "| ZIP | Before | After |"
    echo "|---|---|---|"
    awk -F'\t' '{ print "| " $1 " | " $2 " | " $3 " |" }' <<<"$rows"
  else
    echo "No status changed."
  fi
  echo
}

# The ZIP column of the index for each changed path: the number without
# leading zeros, or the draft's file stem.
changed_zips() {
  awk -F'\t' '{
    for (i = 2; i <= NF; i++) {
      p = $i
      sub(/^zips\//, "", p)
      sub(/\.(rst|md|svg)$/, "", p)
      if (p ~ /^zip-[0-9]+(-.*)?$/) { sub(/^zip-/, "", p); sub(/-.*$/, "", p); p = p + 0 }
      print p
    }
  }' "$changes" | LC_ALL=C sort -u
}

rows_section() {
  local rows
  rows=$(awk -F'\t' -v OFS=' | ' '
    NR == FNR { changed[$1] = 1; next }
    FNR > 1 && NF && ($2 in changed) { gsub(/\|/, "\\|"); $1 = $1; print "| " $0 " |" }' \
    <(changed_zips) "$project/$references/by-area.tsv")
  echo "## Rows to look at"
  echo
  if [ -n "$rows" ]; then
    echo 'Lines of `by-area.tsv` whose ZIP changed in this range. The statuses passed `check.sh`. Whether each caveat still holds is for a reader to check.'
    echo
    echo "| Surface | ZIP | Revision | Status | Where | Caveat |"
    echo "|---|---|---|---|---|---|"
    echo "$rows"
  else
    echo 'No line of `by-area.tsv` cites a ZIP that changed.'
  fi
}

write_report() {
  local count noun=commits
  git -C "$zips_dir" diff --name-status --find-renames "$range" -- zips/ > "$changes"
  count=$(git -C "$zips_dir" rev-list --count "$range" -- zips/)
  if [ "$count" = 1 ]; then noun=commit; fi
  mkdir -p "$project/reports"
  {
    echo "# ZIP index update to zips@${source_new:0:8}"
    echo
    echo "\`zcash/zips\` moved from \`${source_old:0:8}\` ($(commit_date "$source_old")) to \`${source_new:0:8}\` ($(commit_date "$source_new")): $count $noun touched \`zips/\`. The baseline is $baseline_note. Built by \`scripts/update.sh\` on $today."
    echo
    file_section Added A no
    file_section Modified M no
    file_section Deleted D no
    renamed_section
    file_section "Drafts" AMD yes
    file_section "Other changes" CTUX no
    transitions_section
    rows_section
  } > "$project/$report"
}

building=1
git -C "$project" checkout -q -B update "$baseline"
python3 -I "$project/scripts/index.py" "$zips_dir" 2>&1 | tee -a "$build_log" || fail "index.py failed"
write_report
ZIPS_DIR=$zips_dir "$project/scripts/check.sh" 2>&1 | tee -a "$build_log" || fail "check.sh failed"
git -C "$project" add "$references" "$report"
git -C "$project" -c commit.gpgsign=false commit -q -m "chore: update the ZIP index to zips@${source_new:0:8}"
summary="zipcompass: update at zips@${source_new:0:8}, $report"
