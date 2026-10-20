#!/usr/bin/env bash
# One sentence on what changed under protocol/ in a range of the zips
# checkout, for the weekly report.
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: protocol-changes.sh <zips-dir> <range>" >&2; exit 1; }
zips_dir=$1
range=$2

count=$(git -C "$zips_dir" rev-list --count "$range" -- protocol/)
if [ "$count" = 0 ]; then
  echo "protocol/ did not change in this range."
  exit 0
fi
noun=commits
if [ "$count" = 1 ]; then noun=commit; fi
added=0
removed=0
numstat=$(git -C "$zips_dir" diff --numstat "$range" -- protocol/protocol.tex)
if [ -n "$numstat" ]; then
  added=$(cut -f1 <<<"$numstat")
  removed=$(cut -f2 <<<"$numstat")
fi
echo "protocol/ changed in $count $noun in this range (protocol.tex: $added lines added, $removed removed)."
