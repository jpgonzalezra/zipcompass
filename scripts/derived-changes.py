#!/usr/bin/env python3
"""Print the report section that lists every derived value that changed
between two renderings of the references: the statuses and deployments of
by-area.md, the heights of deployments.md and the rows of facts.md.

Usage: derived-changes.py <baseline-dir> <current-dir>

A file missing from the baseline counts as empty, so its rows show as added.
"""

import sys
from pathlib import Path

FILES = {
    "by-area.md": ("ZIP", "Revision"),
    "deployments.md": ("Upgrade", "Network"),
    "facts.md": ("Fact", "ZIP", "Revision"),
}
IGNORED = {"Title", "Where", "Caveat", "File", "Source", "ZIP status"}


def tables(path):
    """{(section, key): {column: value}} for the Markdown tables of a rendered
    file; the key is the values of the file's key columns that the table has."""
    if not path.is_file():
        return {}
    lines = path.read_text(encoding="utf-8").splitlines()
    rows = {}
    section = ""
    header = None
    for number, line in enumerate(lines):
        if line.startswith("## "):
            section = line[3:]
            header = None
        elif line.startswith("| ") and line.endswith(" |"):
            cells = line[2:-2].split(" | ")
            if header is None:
                if number + 1 < len(lines) and lines[number + 1].startswith("|---"):
                    header = cells
                continue
            row = dict(zip(header, cells))
            key = tuple(row[column] for column in FILES[path.name] if column in row)
            if (section, key) in rows:
                print(f"derived-changes.py: {path}: two rows for {' '.join(key)} under '{section}'", file=sys.stderr)
                sys.exit(1)
            rows[(section, key)] = row
        elif not line.startswith("|"):
            header = None
    return rows


def compared(row):
    return {column: value for column, value in row.items() if column not in IGNORED}


def changes(name, old_rows, new_rows):
    keys = FILES[name]
    found = []
    for section, key in list(dict.fromkeys([*old_rows, *new_rows])):
        old = old_rows.get((section, key))
        new = new_rows.get((section, key))
        label = " ".join(value for value in key if value)
        if old is None or new is None:
            present = compared(old or new)
            values = ", ".join(value for column, value in present.items() if column not in keys and value)
            before, after = ("absent", values) if old is None else (values, "absent")
            found.append((name, section, label, "", before, after))
            continue
        old_values, new_values = compared(old), compared(new)
        for column in new_values:
            if column in old_values and old_values[column] != new_values[column]:
                found.append((name, section, label, column, old_values[column] or "empty", new_values[column] or "empty"))
    return found


def main():
    if len(sys.argv) != 3:
        print("usage: derived-changes.py <baseline-dir> <current-dir>", file=sys.stderr)
        sys.exit(1)
    baseline, current = Path(sys.argv[1]), Path(sys.argv[2])
    found = []
    for name in FILES:
        found += changes(name, tables(baseline / name), tables(current / name))
    print("## Derived values that changed")
    print()
    if not found:
        print("No status, height or fact the references derive changed.")
        return
    print("Values the rendered references derive from the checkout, on the baseline and on this branch.")
    print()
    print("| File | Section | Row | Column | Before | After |")
    print("|---|---|---|---|---|---|")
    for row in found:
        print("| " + " | ".join(row) + " |")


if __name__ == "__main__":
    main()
