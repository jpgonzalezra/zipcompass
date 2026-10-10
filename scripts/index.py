#!/usr/bin/env python3
"""Generate references/index.md from a zcash/zips checkout and render the
hand-written TSV tables next to it.

Usage: index.py [--check] <zips-dir>

With --check nothing is written: the files are built in memory and compared
with the ones on disk, and a difference is a failure.
"""

import csv
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
REFERENCES = PROJECT / "skills" / "zips" / "references"
EXCLUDED = {"zip-guide.rst", "zip-guide-markdown.md", "zip-template.md"}
NUMBERED = re.compile(r"^zip-(\d+)\.(rst|md)$")
DRAFT = re.compile(r"^draft-.+\.(rst|md)$")
FIELD = re.compile(r"^([A-Za-z-]+):\s*(.*)$")
REQUIRED = ("ZIP", "Title", "Status", "Category")
INDEX_COLUMNS = ("ZIP", "Title", "Status", "Category", "Created", "Last change", "File", "Relations")


def fail(message):
    print(f"index.py: {message}", file=sys.stderr)
    sys.exit(1)


def git(zips_dir, *args):
    result = subprocess.run(
        ["git", "-C", str(zips_dir), "-c", "core.abbrev=8", *args],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def take_indented(lines, minimum, path):
    """The block indented at least `minimum` spaces; its own indent is read
    from its first line, since the checkout is not uniform about it."""
    block = []
    indent = None
    for line in lines:
        if not line.strip():
            continue
        if indent is None:
            indent = line[: len(line) - len(line.lstrip(" "))]
            if len(indent) < minimum:
                fail(f"{path}: the preamble is indented {len(indent)} spaces, expected at least {minimum}")
        if not line.startswith(indent):
            break
        block.append(line[len(indent):])
    if not block:
        fail(f"{path}: no indented preamble block")
    return block


def take_fenced(lines, fence, path):
    block = []
    for line in lines:
        if line.strip() == fence:
            return block
        block.append(line)
    fail(f"{path}: the preamble fence {fence!r} never closes")


def preamble_block(lines, path):
    """The preamble lines without their indentation, in one of the four shapes
    the checkout uses: reStructuredText (`::` then a block indented two
    spaces), Markdown with a block indented four spaces, Markdown with the
    block inside a ``` fence, and YAML front matter between --- lines."""
    start = 0
    while start < len(lines) and not lines[start].strip():
        start += 1
    if start == len(lines):
        fail(f"{path}: empty file")
    first = lines[start]
    if first.strip() == "::":
        return take_indented(lines[start + 1:], 2, path)
    if first.strip() == "```":
        return take_fenced(lines[start + 1:], "```", path)
    if first.strip() == "---":
        return take_fenced(lines[start + 1:], "---", path)
    if first.startswith("    "):
        return take_indented(lines[start:], 4, path)
    fail(f"{path}: unknown preamble shape, first line {first!r}")


def parse_fields(block, path):
    fields = {}
    current = None
    for line in block:
        match = FIELD.match(line)
        if match:
            current = match.group(1)
            fields[current] = match.group(2).strip()
        elif line.strip() and current:
            fields[current] = f"{fields[current]} {line.strip()}".strip()
        elif line.strip():
            fail(f"{path}: preamble line before any field: {line!r}")
    missing = [name for name in REQUIRED if name not in fields]
    if missing:
        fail(f"{path}: the preamble lacks {', '.join(missing)}")
    return fields


def relations(fields):
    parts = []
    for name in ("Obsoletes", "Updates"):
        if fields.get(name):
            parts.append(f"{name} {fields[name]}")
    return "; ".join(parts)


def entries(zips_dir):
    folder = zips_dir / "zips"
    rows = []
    for path in sorted(folder.iterdir()):
        name = path.name
        if name in EXCLUDED:
            continue
        numbered = NUMBERED.match(name)
        if not numbered and not DRAFT.match(name):
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        fields = parse_fields(preamble_block(lines, path), path)
        if numbered:
            number = int(numbered.group(1))
            if not fields["ZIP"].isdigit() or int(fields["ZIP"]) != number:
                fail(f"{path}: the ZIP field {fields['ZIP']!r} does not match the file name")
            key = (0, number, "")
            label = str(number)
        else:
            key = (1, 0, path.stem)
            label = path.stem
        relative = f"zips/{name}"
        rows.append(
            {
                "key": key,
                "zip": label,
                "title": fields["Title"],
                "status": fields["Status"],
                "category": fields["Category"],
                "created": fields.get("Created", ""),
                "change": git(zips_dir, "log", "-1", "--follow", "--format=%cs %h", "--", relative),
                "file": relative,
                "relations": relations(fields),
                "draft": not numbered,
            }
        )
    rows.sort(key=lambda row: row["key"])
    return rows


def cell(text):
    if "|" in text:
        fail(f"a table cell contains '|': {text!r}")
    return text


def table(header, rows):
    lines = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    for row in rows:
        lines.append("| " + " | ".join(cell(value) for value in row) + " |")
    return lines


def status_bucket(status):
    return "per-revision" if status.startswith("[Revision") else status


def render_index(rows, commit, date):
    numbered = [row for row in rows if not row["draft"]]
    drafts = [row for row in rows if row["draft"]]
    counts = Counter(status_bucket(row["status"]) for row in numbered)
    summary = ", ".join(f"{count} {status}" for status, count in sorted(counts.items(), key=lambda item: (-item[1], item[0])))
    lines = [
        f"Generated from zcash/zips at {commit} ({date}) by scripts/index.py. Do not edit.",
        "",
        f"{len(numbered)} numbered ZIPs and {len(drafts)} drafts. Statuses of the numbered ZIPs: {summary}.",
        "",
    ]
    lines += table(
        INDEX_COLUMNS,
        [
            (row["zip"], row["title"], row["status"], row["category"], row["created"], row["change"], row["file"], row["relations"])
            for row in rows
        ],
    )
    return "\n".join(lines) + "\n"


def read_tsv(path, columns):
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE)
        if tuple(reader.fieldnames or ()) != columns:
            fail(f"{path}: expected the columns {columns}, found {reader.fieldnames}")
        rows = list(reader)
    for row in rows:
        if None in row:
            fail(f"{path}: a row has more columns than the header: {row}")
        if any(value is None for value in row.values()):
            fail(f"{path}: a row has fewer columns than the header: {row}")
    return rows


def render_by_area(rows, index):
    source = REFERENCES / "by-area.tsv"
    lines = ["Rendered from by-area.tsv by scripts/index.py. Do not edit.", ""]
    surfaces = {}
    for row in read_tsv(source, ("surface", "zip", "revision", "status", "where", "caveat")):
        if row["zip"] not in index:
            fail(f"{source}: ZIP {row['zip']} is not in the index")
        surfaces.setdefault(row["surface"], []).append(row)
    for surface, surface_rows in surfaces.items():
        lines += [f"## {surface}", ""]
        lines += table(
            ("ZIP", "Title", "Revision", "Status", "Where", "Caveat"),
            [
                (row["zip"], index[row["zip"]]["title"], row["revision"], row["status"], row["where"], row["caveat"])
                for row in surface_rows
            ],
        )
        lines.append("")
    return "\n".join(lines)


def render_deployments(index):
    source = REFERENCES / "deployments.tsv"
    lines = ["Rendered from deployments.tsv by scripts/index.py. Do not edit.", ""]
    rows = read_tsv(source, ("upgrade", "zip", "network", "height"))
    for row in rows:
        if row["zip"] not in index:
            fail(f"{source}: ZIP {row['zip']} is not in the index")
    lines += table(
        ("Upgrade", "ZIP", "ZIP status", "Network", "Height"),
        [(row["upgrade"], row["zip"], index[row["zip"]]["status"], row["network"], row["height"]) for row in rows],
    )
    return "\n".join(lines) + "\n"


def main():
    args = sys.argv[1:]
    check = "--check" in args
    args = [arg for arg in args if arg != "--check"]
    if len(args) != 1:
        fail("usage: index.py [--check] <zips-dir>")
    zips_dir = Path(args[0]).resolve()
    if not (zips_dir / "zips").is_dir():
        fail(f"{zips_dir} has no zips/ folder")
    commit = git(zips_dir, "rev-parse", "HEAD")
    date = git(zips_dir, "log", "-1", "--format=%cs", "HEAD")
    rows = entries(zips_dir)
    index = {row["zip"]: row for row in rows}
    outputs = {
        REFERENCES / "index.md": render_index(rows, commit, date),
        REFERENCES / "by-area.md": render_by_area(rows, index),
        REFERENCES / "deployments.md": render_deployments(index),
    }
    if check:
        stale = [path.name for path, text in outputs.items() if not path.is_file() or path.read_text(encoding="utf-8") != text]
        if stale:
            fail(f"out of date: {', '.join(stale)}; run make index")
        print(f"index.py: {', '.join(path.name for path in outputs)} are current at zips@{commit[:8]}")
        return
    REFERENCES.mkdir(parents=True, exist_ok=True)
    for path, text in outputs.items():
        path.write_text(text, encoding="utf-8")
    print(f"index.py: wrote {', '.join(path.name for path in outputs)} from zips@{commit[:8]} ({date})")


if __name__ == "__main__":
    main()
