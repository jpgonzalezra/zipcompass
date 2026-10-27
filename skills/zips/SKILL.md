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
which outranks the crate. A ZIP can stay Draft or Proposed long after the upgrade that
carries it has a mainnet height. The Deployment column of `references/by-area.md` names the
upgrade each row ships with and the mainnet height its deployment ZIP sets.
`references/facts.md` lists the rows still Draft or Proposed at such a height. ZIP 307
(light-client protocol) ships through software rather than an upgrade, so no height applies
to it. ZIP 256 (consensus bug fixes between NU6.1 and NU6.2) has no activation height of its
own. The ladder is in `references/deployments.md`, with the heights the ZIPs set. Whether the
chain has reached them is the node's to say.

## One status per revision

ZIPs 207, 214, 316, 317 and 374 carry one status per revision. Their `Status` field lists
each revision in brackets with its own status, as in "[Revision 0] Active, [Revision 1:
NU6.3] Draft", and `references/index.md` copies it as written. A citation of one of these
ZIPs names the revision, and their rows in `references/by-area.md` carry it.

## Who decides what

| Claim | Authority |
|---|---|
| A ZIP status or a normative rule | the `zips` checkout at the index's commit |
| A consensus rule | `protocol/protocol.tex` at the index's commit, read at the anchor with the macro around the sentence; the ZIP that introduced the rule for the rationale |
| An encoding or a constant a program produces | the crate at its pinned version |
| A proto field name or number | the `lightwallet-protocol` revision the project's protos come from |
| What is active now, an activation height | the node, which outranks the crate |
| An RPC contract: field, type, error behavior | zebra's source at the tag the node runs |

When two sources disagree and both are right in their own terms, say both, with versions.
Standing example: ZIP 316 Revision 2 defines `zu`, `tu`, `uvf` and `uvi`.
`zcash_address 0.13.0` (2026-07-09, the last release before the 0.14.0 pre-releases)
encodes Revision 0 only (`uview`). `zcash_address 0.14.0-pre.1` on librustzcash `main`
encodes both, and `zcash_keys` picks Revision 0 when the key is representable there and
Revision 2 otherwise (`zcash_keys/src/keys.rs`, `encode`). A caveat without a version number
is wrong somewhere.

## The protocol specification

For consensus rules the contract is the Zcash Protocol Specification, `protocol/protocol.tex`
in the same checkout: one LaTeX source, built once per network upgrade. Three things to know
before citing it.

`protocol.pdf` on zips.z.cash is one build of that source, for the upgrade
`references/facts.md` names. Text wrapped in a later upgrade's macro is absent from that
build and present in the later upgrade's own. For NU6.3 the macros are `\nusixthree{...}`,
`\nusixthreeonwarditem{...}` and `\notbeforenusixthree{...}`, and the build is `nu6_3.pdf`.
Text that only carries a colour such as `\setnusixthree` prints in every build: the Ironwood
rows of the transaction field table are one case. So text about a later upgrade in
`protocol.pdf` does not mean its rules are in that build.

Several ZIPs link `protocol.pdf` for the rules of an upgrade later than the one it is built
for. `facts.md` lists them, along with the latest tag of the specification. Read the source
at the label, not a PDF: `grep -n '{txnconsensus}' protocol/protocol.tex` finds the heading,
and the macro around a sentence says which upgrade it belongs to.

Cite by anchor, never by section number: `Protocol specification, "Transaction Consensus
Rules" (#txnconsensus), protocol.tex line <n>, zips@<short commit>` plus the quoted sentence
and the macro that gates it, or "ungated". The anchor is the LaTeX label and survives
rebuilds. The section number does not. The version a ZIP names in its own citation is the one
of the day it was written.

`references/spec-anchors.md` maps implementation surfaces to the anchors to open, with one
caveat per row.

## How to cite

`ZIP 317, "Fee calculation", Revision 1, zips@<short commit>` plus the quoted sentence, the
commit being the one in the first line of `references/index.md`. Open the file in the
checkout. Do not restate it from memory. Before citing, compare
`git -C <zips-dir> rev-parse --short HEAD` with the commit in the first line of
`references/index.md`, and run `make update` in the zipcompass project when they differ.

## Briefs for other reviewers

A brief that goes to another reviewer pastes the sections it relies on: a reviewer confined
to one directory (codex with `--cd`, say) never sees a skill installed outside it.

## References

- `references/index.md`: every ZIP and draft with its status, category, creation date, last
  change and file, generated from the checkout at the commit in its first line.
- `references/by-area.md`: the ZIPs each implementation surface rests on, with each ZIP's
  status and the upgrade it deploys with, and one caveat per row.
- `references/deployments.md`: the activation ladder on both networks, with the heights the
  deployment ZIPs set.
- `references/facts.md`: generated from the checkout. It names the upgrade `protocol.pdf` is
  built for, the specification's latest tag, the ZIPs that link `protocol.pdf` for a later
  upgrade, and the rows of `by-area.md` still Draft or Proposed at a mainnet height.
- `references/spec-anchors.md`: the anchors of the protocol specification each implementation
  surface rests on, with the heading's line at the index's commit and one caveat per row.
