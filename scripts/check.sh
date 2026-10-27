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
[ -f "$zips_dir/protocol/Makefile" ] || fail "$zips_dir has no protocol/Makefile"

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

# (i) the build protocol.pdf comes from, as the skill text states it
mv_lines=$(grep -E '^\s*mv -f aux/nu[0-9_]+\.pdf \$\(PDFDIR\)/protocol\.pdf$' "$zips_dir/protocol/Makefile" || true)
[ "$(grep -c . <<<"$mv_lines")" = 1 ] ||
  fail "protocol/Makefile no longer builds protocol.pdf with the mv line rule (i) reads; rewrite the rule"
build=$(sed -E 's/.*aux\/(nu[0-9_]+)\.pdf.*/\1/' <<<"$mv_lines")
upgrade=NU${build#nu}
upgrade=${upgrade//_/.}
sentence=$(grep -oE '`protocol\.pdf` on zips\.z\.cash is the NU[0-9.]+ build' "$skill_dir/SKILL.md" || true)
[ "$(grep -c . <<<"$sentence")" = 1 ] ||
  fail 'SKILL.md has no "protocol.pdf on zips.z.cash is the NU... build" sentence'
stated=$(grep -oE 'NU[0-9.]+' <<<"$sentence")
[ "$stated" = "$upgrade" ] ||
  fail "SKILL.md says protocol.pdf is the $stated build; protocol/Makefile builds it from $build"

# (j) the latest tag of the specification, as the skill text states it
latest=$(git -C "$zips_dir" describe --tags --abbrev=0 --match 'v20*' HEAD 2>/dev/null || true)
[ -n "$latest" ] || fail "the zips checkout has no v20* tag reachable from HEAD; run git fetch --tags"
sentence=$(grep -oE 'the latest tag of the specification is `v[0-9.]+`' "$skill_dir/SKILL.md" || true)
[ "$(grep -c . <<<"$sentence")" = 1 ] ||
  fail 'SKILL.md has no "the latest tag of the specification is" sentence'
stated=$(grep -oE 'v[0-9.]+' <<<"$sentence")
[ "$stated" = "$latest" ] || fail "SKILL.md names $stated as the latest tag; the checkout has $latest"

# (k) the ZIPs the skill text says link protocol.pdf for the NU6.3
# specification are exactly the numbered ZIP files that do
sentence=$(grep -oE 'ZIPs [0-9]+(, [0-9]+)* and [0-9]+ link `protocol\.pdf` for the NU6\.3 specification' "$skill_dir/SKILL.md" || true)
[ "$(grep -c . <<<"$sentence")" = 1 ] ||
  fail 'SKILL.md has no "ZIPs N, N and N link protocol.pdf for the NU6.3 specification" sentence'
stated=$(grep -oE '[0-9]+' <<<"${sentence%% link*}")
linking=
for file in $(grep -lE '\[NU6\.3\][^)]*\]\(protocol/protocol\.pdf\)' "$zips_dir"/zips/zip-[0-9]*.* || true); do
  file=${file#"$zips_dir"/}
  number=${file#zips/zip-}
  number=$((10#${number%%.*}))
  linking+="$number $file"$'\n'
done
for zip in $stated; do
  grep -qE "^$zip " <<<"$linking" ||
    fail "SKILL.md says ZIP $zip links protocol.pdf for the NU6.3 specification; $(index_lookup "$zip" 7) no longer does"
done
while read -r number file; do
  [ -n "$number" ] || continue
  grep -qx "$number" <<<"$stated" ||
    fail "$file links protocol.pdf for the NU6.3 specification and SKILL.md does not list ZIP $number"
done <<<"$linking"

# (g) the generated files are what the generator produces today
python3 -I "$project/scripts/index.py" --check "$zips_dir"

echo "check: ok at zips@${checkout:0:8}"
