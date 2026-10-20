---
name: zips
description: Map Zcash code under review to the ZIP, section and revision that governs it, from a local zcash/zips checkout. Use when reviewing or writing Zcash code that rests on a ZIP (fees, addresses and keys, transaction formats and txids, the light-client protocol, pool migration, network upgrades, funding streams, payment URIs, PCZT), and before stating what a ZIP requires or which status it has.
---

# ZIPs for a review

The ZIPs move faster than any model's training, and most of what a wallet or node review
cites is Draft or carries one status per revision. This skill is a map from the code under
review to the ZIP file to open, plus the traps. It never replaces reading the ZIP: quote the
section.

## Status is not deployment

`Status` says where a ZIP is in the ZIP process, nothing more. What is live comes from the
deployment ZIP of the upgrade and from the node (`getblockchaininfo`, `consensus.nextblock`),
which outranks the crate. ZIP 258, the deployment ZIP of NU6.3, is Draft while NU6.3 has
been active on mainnet since 3,428,143. ZIP 229 (v6 transactions) and ZIP 307 (light-client
protocol) are Draft and live. ZIP 2005 is Proposed and live. The ladder is in
`references/deployments.md`: NU5 through NU6.3 on both networks, NU7 with its testnet height
and mainnet pending. ZIP 256 (consensus bug fixes between NU6.1 and NU6.2) has no activation
height of its own.

## One status per revision

ZIPs 207, 214, 316, 317 and 374 carry one status per revision. ZIP 317 reads "[Revision 0]
Active, [Revision 1: NU6.3] Draft, [Revision 2] Draft". A citation of one of these names the
revision, and the rows for them in `references/by-area.md` carry it.

## Who decides what

| Claim | Authority |
|---|---|
| A ZIP status or a normative rule | the `zips` checkout at the index's commit |
| A consensus rule | `protocol/protocol.tex` at the index's commit, read at the anchor with the macro around the sentence; the ZIP that introduced the rule for the rationale |
| An encoding or a constant a program produces | the crate at its pinned version |
| A proto field name or number | the vendored `lightwallet-protocol` |
| What is active now, an activation height | the node, which outranks the crate |
| An RPC contract: field, type, error behavior | zebra's source at the tag the node runs |

When two sources disagree and both are right in their own terms, say both, with versions.
Standing example: ZIP 316 Revision 2 (Draft) defines `zu`, `tu`, `uvf` and `uvi`.
`zcash_address 0.13.0` (2026-07-09, the last release before the 0.14.0 pre-releases)
encodes Revision 0 only (`uview`). `zcash_address 0.14.0-pre.1` on librustzcash `main`
encodes both, and `zcash_keys` picks Revision 0 when the key is representable there and
Revision 2 otherwise (`zcash_keys/src/keys.rs`, `encode`). A caveat without a version number
is wrong somewhere.

## The protocol specification

For consensus rules the contract is the Zcash Protocol Specification, `protocol/protocol.tex`
in the same checkout: one LaTeX source, built once per network upgrade. Three things to know
before citing it.

`protocol.pdf` on zips.z.cash is the NU6.2 build (`protocol/Makefile`, the `nu6_2` target),
while NU6.3 is active on both networks. Text the source wraps in `\nusixthree{...}`,
`\nusixthreeonwarditem{...}` or `\notbeforenusixthree{...}` is absent from it and present in
`nu6_3.pdf`. Text that only carries `\setnusixthree` (a colour) prints in both builds: the
Ironwood rows of the transaction field table are one case. So Ironwood text in `protocol.pdf`
does not mean the NU6.3 rules are there.

ZIPs 229, 235, 237, 258, 259 and 326 link `protocol.pdf` for the NU6.3 specification, and
the latest tag of the specification is `v2026.7.0`. Read the source at the label, not a
PDF: `grep -n '{txnconsensus}' protocol/protocol.tex` finds the heading, and the macro
around a sentence says which upgrade it belongs to.

Cite by anchor, never by section number: `Protocol specification, "Transaction Consensus
Rules" (#txnconsensus), protocol.tex line <n>, zips@<short commit>` plus the quoted sentence
and the macro that gates it, or "ungated". The anchor is the LaTeX label and survives
rebuilds. The section number does not. The version a ZIP names in its own citation is the one
of the day it was written.

`references/spec-anchors.md` maps the implementation surfaces our reviews touch to the
anchors to open, with one trap per row.

## How to cite

`ZIP 317, "Fee calculation", Revision 1, zips@<short commit>` plus the quoted sentence, the
commit being the one in the first line of `references/index.md`. Open the file in the
checkout. Do not restate it from memory. Before citing, compare
`git -C <zips-dir> rev-parse --short HEAD` with the commit in the first line of
`references/index.md`, and run `make update` in the zipcompass project when they differ.

## Briefs for other reviewers

A brief that goes to another reviewer pastes the sections it relies on. codex runs with
`--cd` and sees nothing outside that directory, so a skill in `.claude/` reaches one reviewer
of the two.

## References

- `references/index.md`: every ZIP and draft with its status, category, creation date, last
  change and file, generated from the checkout at the commit in its first line.
- `references/by-area.md`: the ZIPs each implementation surface rests on, one trap per row.
- `references/deployments.md`: the activation ladder on both networks.
- `references/spec-anchors.md`: the anchors of the protocol specification each implementation
  surface rests on, with the heading's line at the index's commit and one trap per row.
