# zipcompass

A skill for coding agents that review or write Zcash code. It maps the code under review to
the ZIP, section and revision that governs it, and keeps that map current with
[zcash/zips](https://github.com/zcash/zips). The skill carries pointers into a local checkout
of the ZIPs, never ZIP text. It also names the traps a reader meets today: a `Status` field
that says nothing about deployment, ZIPs with one status per revision, and crates that
encode a different revision than the one the ZIP describes. The generated index records the
`zcash/zips` commit it came from, and `make check` fails when the checkout and the index
disagree.

The skill also maps consensus code to the protocol specification, `protocol/protocol.tex` in
the same checkout. The unit is the anchor (the LaTeX label a heading carries, and the fragment
the code and the ZIPs link), never a section number. The map carries pointers into the source,
not its text: `references/spec-anchors.md` lists the anchors each implementation surface rests
on, with the line of the heading at the index's commit and the trap to know. `make check`
verifies every anchor the skill names against the labels in the source.

Install it in Claude Code with `/plugin install zipcompass --marketplace jpgonzalezra/zipcompass`,
load it from a clone with `claude --plugin-dir <path to this repository>`, or link `skills/zips`
into a project's `.claude/skills/`. The skill expects a checkout of
`zcash/zips` next to this repository, or wherever `ZIPS_DIR` points. `make index`
regenerates the index from that checkout and `make check` verifies the hand-written tables
and the skill text against the index and the checkout.

`make update` fetches `zcash/zips`, fast-forwards the checkout, regenerates the index on the
`update` branch and writes a report under `reports/`. `make publish` pushes that branch and
opens or refreshes its pull request. It needs an SSH agent and an authenticated `gh`, so run
it from a session. A scheduler runs `scripts/update.sh` directly: it needs no credential, its
last line of output summarizes the run, and it exits 0 when it completed, 75 when it skipped
and 1 when it failed.
