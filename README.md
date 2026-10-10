# zipcompass

A skill for coding agents that review or write Zcash code. It maps the code under review to
the ZIP, section and revision that governs it, and keeps that map current with
[zcash/zips](https://github.com/zcash/zips). The skill carries pointers into a local checkout
of the ZIPs, never ZIP text. It also names the traps a reader meets today: a `Status` field
that says nothing about deployment, ZIPs with one status per revision, and crates that
encode a different revision than the one the ZIP describes. The generated index records the
`zcash/zips` commit it came from, and `make check` fails when the checkout and the index
disagree.

Install it in Claude Code with `/plugin install zipcompass --marketplace jpgonzalezra/zipcompass`,
load it from a clone with `claude --plugin-dir <path to this repository>`, or link `skills/zips`
into a project's `.claude/skills/`. The skill expects a checkout of
`zcash/zips` next to this repository, or wherever `ZIPS_DIR` points. `make index`
regenerates the index from that checkout and `make check` verifies the hand-written tables
and the skill text against the index and the checkout.
