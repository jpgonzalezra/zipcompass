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

revision_status() { # "<index status>" <revision number> -> that revision's status
  grep -oE '\[[^]]*\] [A-Za-z]+' <<<"$1" |
    grep -E "(\[|, )Revision $2(:|\])" |
    awk '{ print $NF }' | head -n 1 | grep .
}

network_label() {
  printf '%s' "${1^}"
}

# (c) the index comes from the commit the checkout is at
header_commit=$(head -n 1 "$index" | grep -oE '\b[0-9a-f]{40}\b') ||
  fail "index.md has no commit in its header"
checkout=$(git -C "$zips_dir" rev-parse HEAD)
[ "$header_commit" = "$checkout" ] ||
  fail "index.md was generated from zips@${header_commit:0:8} and the checkout is at ${checkout:0:8}; run make index"

# (a) and (b): every ZIP in by-area.tsv is in the index with the status the row claims
while IFS="$unit" read -r surface zip revision status where caveat; do
  index_status=$(index_lookup "$zip" 3) || fail "by-area.tsv: ZIP $zip is not in the index"
  if [ -n "$revision" ] && ! [[ $revision =~ ^R[0-9]+$ ]]; then
    fail "by-area.tsv: ZIP $zip has the revision '$revision', expected R<n>"
  fi
  case $index_status in
    "[Revision"*)
      [ -n "$revision" ] || fail "by-area.tsv: ZIP $zip has one status per revision, the row needs one"
      expected=$(revision_status "$index_status" "${revision#R}") ||
        fail "by-area.tsv: ZIP $zip has no Revision ${revision#R} in the index"
      ;;
    *)
      [ -z "$revision" ] || fail "by-area.tsv: ZIP $zip has one status, the row must not name a revision"
      expected=$index_status
      ;;
  esac
  [ "$status" = "$expected" ] ||
    fail "by-area.tsv: ZIP $zip${revision:+ $revision} is $expected in the index, the row says $status"
done < <(tsv_rows "$references/by-area.tsv")

# (d) every deployment row matches a '<Network> ...: <height>' line under the
# ACTIVATION_HEIGHT heading of its ZIP, and a pending row has none there. The
# window closes at the next line that starts at column 0 (the next constant or
# paragraph), which keeps the protocol version numbers out of it.
while IFS="$unit" read -r upgrade zip network height; do
  file=$(index_lookup "$zip" 7) || fail "deployments.tsv: ZIP $zip is not in the index"
  label=$(network_label "$network")
  if [ "$height" = pending ]; then
    pattern="$label[^0-9]*: *[0-9]+"
  else
    pattern="$label[^0-9]*: *$height([^0-9]|$)"
  fi
  if awk -v pattern="$pattern" '
      /^ACTIVATION_HEIGHT/ { open = 1; next }
      open && /^[^ :]/ { open = 0 }
      open && $0 ~ pattern { found = 1 }
      END { exit !found }' "$zips_dir/$file"; then
    [ "$height" != pending ] ||
      fail "deployments.tsv: $upgrade $network is pending but $file carries a height"
  else
    [ "$height" = pending ] ||
      fail "deployments.tsv: no '$label ...: $height' under ACTIVATION_HEIGHT in $file"
  fi
done < <(tsv_rows "$references/deployments.tsv")

# (e) every ZIP the skill text cites is in the index
for zip in $(grep -oE 'ZIPs? [0-9]+((,| and| or) [0-9]+)*' "$skill_dir/SKILL.md" | grep -oE '[0-9]+' | sort -un); do
  index_lookup "$zip" 1 >/dev/null || fail "SKILL.md cites ZIP $zip, which is not in the index"
done

# (f) the skill is named after its directory
name=$(sed -n '2,/^---$/p' "$skill_dir/SKILL.md" | awk -F': ' '$1 == "name" { print $2 }')
[ "$name" = "$(basename "$skill_dir")" ] ||
  fail "SKILL.md is named '$name', its directory is $(basename "$skill_dir")"

# (g) the generated files are what the generator produces today
python3 -I "$project/scripts/index.py" --check "$zips_dir"

echo "check: ok at zips@${checkout:0:8}"
