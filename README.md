# zipcompass

A skill for coding agents that review or write Zcash code. It maps the code under review to
the ZIP, section and revision that governs it, maps consensus code to the anchor of the Zcash
protocol specification, and keeps both maps current with
[zcash/zips](https://github.com/zcash/zips). The skill carries pointers into a local checkout
of that repository, never ZIP text, and it names the traps a reader meets today: a `Status`
field that says nothing about deployment, ZIPs with one status per revision, and crates that
encode a different revision than the one the ZIP describes.

With the skill loaded, an agent opens each citation with a line like these, then quotes the
sentence it rests on and, for the specification, names the macro that gates it or says it is
ungated:

```
ZIP 317, "Fee calculation", Revision 1, zips@a34cfc09
Protocol specification, "Transaction Consensus Rules" (#txnconsensus), protocol.tex line 13620, zips@a34cfc09
```

## What it covers

`references/by-area.md` maps nine implementation surfaces to their ZIPs, one trap per row:
compact blocks and the light-client protocol; transaction parsing and txids; fees, input
selection and dust; pool migration; addresses, keys and viewing keys; payment requests and
PCZT; network upgrades; issuance, funding streams and NSM; the shielded protocols.
`references/spec-anchors.md` maps ten surfaces of consensus code to the anchors of
`protocol/protocol.tex`, with the line of each heading at the index's commit: transaction
consensus rules; transaction encoding; transaction identifiers; the block header; Spend,
Output and Action encodings; funding streams and subsidies; key components; address
encodings; networks; note commitment trees. `references/deployments.md` is the activation
ladder of both networks, and `references/index.md` lists every ZIP and draft with its
status. The index's first line names the `zcash/zips` commit it was generated from, with
that commit's date.

## Install

The skill needs a checkout of `zcash/zips`, anywhere on disk:

```
git clone https://github.com/zcash/zips.git
```

Tell the agent where it is, for example with a line in the project's `CLAUDE.md`: "The
`zcash/zips` checkout is at `../zips`." Before citing, the skill compares the checkout's
commit with the one the index came from. When they differ, check out that commit in the
clone, or wait for the index to catch up.

As a Claude Code plugin:

```
/plugin marketplace add jpgonzalezra/zipcompass
/plugin install zipcompass@zipcompass
```

The skill is then `/zipcompass:zips`. From a shell, `claude plugin marketplace add
jpgonzalezra/zipcompass` and `claude plugin install zipcompass@zipcompass` do the same. To
try a clone for one session, `claude --plugin-dir <path to the clone>`. To use the skill
without the plugin, link or copy `skills/zips` into the project's `.claude/skills/`, or into
the directory your agent reads skills from.

## Keeping the index current

The targets below run from a clone of this repository and need `git`, `bash`, `make` and
`python3` (standard library only). `ZIPS_DIR` names the checkout, `../zips` by default.

- `make index` regenerates `references/index.md` from the checkout and renders the
  hand-written tables next to it.
- `make check` verifies the tables and the skill text against the index and the checkout:
  every status and activation height the tables claim, every anchor they name, and that the
  index comes from the commit the checkout is at. It fails when they disagree.
- `make update` fetches `zcash/zips`, fast-forwards the checkout and, when the index is
  behind it, rebuilds the index on the `update` branch and writes a report of what changed
  under `reports/`. It skips when this repository has uncommitted changes or the checkout
  is dirty or off `main`.
- `make publish` pushes that branch and opens or refreshes its pull request. It needs an SSH
  agent and an authenticated `gh`, so run it by hand.

The index on `main` moves by pull request. A scheduler can run `scripts/update.sh` directly:
it needs no credential, its last line of output summarizes the run, and it exits 0 when it
completed, 75 when it skipped and 1 when it failed. With `flock` installed, a run that finds
the lock taken skips.

## Layout

- `skills/zips/SKILL.md`: the skill.
- `skills/zips/references/`: `by-area.tsv`, `deployments.tsv` and `spec-anchors.tsv` are
  hand-written; their `.md` renderings and `index.md` are generated.
- `scripts/`: `index.py` generates, `check.sh` verifies, `update.sh` and `publish.sh` run
  the update, and `protocol-changes.sh` summarizes what moved under `protocol/` for the
  report.
- `reports/`: one report per index update.
- `.claude-plugin/`: the plugin and marketplace manifests.

For a wrong row, a missing trap or a surface the tables do not cover, open an issue.

## License

MIT.
