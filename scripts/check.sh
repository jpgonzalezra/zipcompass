#!/usr/bin/env bash
# Verifies the hand-written tables and the skill text against the generated
# index and the zips checkout. Exits non-zero on the first failure.
set -euo pipefail

project=$(cd "$(dirname "$0")/.." && pwd)
zips_dir=${ZIPS_DIR:-$project/../zips}
skill_dir=$project/skills/zips
references=$skill_dir/references
index=$references/index.md
unit=$'\x1f'

fail() {
  echo "check: $*" >&2
  exit 1
}

[ -f "$index" ] || fail "$index is missing; run make index"
[ -d "$zips_dir/zips" ] || fail "$zips_dir is not a zips checkout"

# The index is a Markdown table whose cells never contain '|'; the generator
# refuses to write one that does.
index_lookup() { # <zip> <column> -> the cell, non-zero when the ZIP is absent
  awk -F' \\| ' -v zip="$1" -v column="$2" '
    /^\| / { sub(/^\| /, "", $1); sub(/ \|$/, "", $NF) }
    $1 == zip { print $column; found = 1 }
    END { exit !found }' "$index"
}

# Rows of a TSV joined with the unit separator, which `read` does not collapse
# the way it collapses consecutive tabs.
tsv_rows() {
  awk -F'\t' -v OFS="$unit" 'NR > 1 && NF { $1 = $1; print }' "$1"
}

# (c) the index comes from the commit the checkout is at
header_commit=$(head -n 1 "$index" | grep -oE '\b[0-9a-f]{40}\b') ||
  fail "index.md has no commit in its header"
checkout=$(git -C "$zips_dir" rev-parse HEAD)
[ "$header_commit" = "$checkout" ] ||
  fail "index.md was generated from zips@${header_commit:0:8} and the checkout is at ${checkout:0:8}; run make index"

# (e) every ZIP the skill text cites is in the index
for zip in $(grep -oE 'ZIPs? [0-9]+((,| and| or) [0-9]+)*' "$skill_dir/SKILL.md" | grep -oE '[0-9]+' | sort -un); do
  index_lookup "$zip" 1 >/dev/null || fail "SKILL.md cites ZIP $zip, which is not in the index"
done

# (f) the skill is named after its directory
name=$(sed -n '2,/^---$/p' "$skill_dir/SKILL.md" | awk -F': ' '$1 == "name" { print $2 }')
[ "$name" = "$(basename "$skill_dir")" ] ||
  fail "SKILL.md is named '$name', its directory is $(basename "$skill_dir")"

# (h) every anchor the spec table and the skill text name is the label of a
# heading in protocol.tex, or an alias of one
anchors=$(python3 -I "$project/scripts/index.py" --anchors "$zips_dir")
has_anchor() {
  grep -qxF "$1" <<<"$anchors"
}
while IFS="$unit" read -r surface anchor where caveat; do
  for name in ${anchor//, / }; do
    has_anchor "$name" || fail "spec-anchors.tsv: anchor $name is not a label in protocol/protocol.tex"
  done
done < <(tsv_rows "$references/spec-anchors.tsv")
for name in $(grep -oE '\(#[A-Za-z0-9]+\)' "$skill_dir/SKILL.md" | tr -d '(#)' | sort -u); do
  has_anchor "$name" || fail "SKILL.md: anchor $name is not a label in protocol/protocol.tex"
done

# (g) the generated files are what the generator produces today
python3 -I "$project/scripts/index.py" --check "$zips_dir"

echo "check: ok at zips@${checkout:0:8}"
