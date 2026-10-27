Derived from zcash/zips at a34cfc091434275120ff017c92c3b50d3cef623a (2026-10-16) by scripts/index.py. Do not edit.

## The protocol specification

| Fact | Value | Source |
|---|---|---|
| The upgrade that `protocol.pdf` on zips.z.cash is built for | NU6.2 | protocol/Makefile, the `nu6_2` target |
| The latest tag of the specification | v2026.7.0 | `git describe --tags --match 'v20*'` |

## ZIPs that link protocol.pdf for a later upgrade

`protocol.pdf` is the NU6.2 build, so the text these ZIPs expect under a later upgrade's macro is not in it. Read `protocol/protocol.tex` at the anchor instead.

| ZIP | Title | Upgrade in the link | File |
|---|---|---|---|
| 207 | Funding Streams | NU6.3 | zips/zip-0207.rst |
| 214 | Consensus rules for a Zcash Development Fund | NU6.3 | zips/zip-0214.rst |
| 229 | Version 6 Transaction Format | NU6.3 | zips/zip-0229.md |
| 235 | Remove 60% of Transaction Fees From Circulation | NU6.3 | zips/zip-0235.md |
| 237 | Network Sustainability Mechanism: Halving-Preserving Issuance | NU6.3 | zips/zip-0237.md |
| 258 | Deployment of the NU6.3 Network Upgrade | NU6.3 | zips/zip-0258.md |
| 259 | Deployment of the NU7 Network Upgrade | NU6.3 | zips/zip-0259.md |
| 326 | NU6.3 Consequences for Wallets | NU6.3 | zips/zip-0326.md |

## Traps

ZIPs and revisions in by-area.md still Draft or Proposed although the upgrade they deploy with has a mainnet activation height. Status says where a ZIP is in the ZIP process, not whether it is in force.

| ZIP | Revision | Status | Upgrade | Mainnet height |
|---|---|---|---|---|
| 229 |  | Draft | NU6.3 | 3428143 |
| 258 |  | Draft | NU6.3 | 3428143 |
| 2005 |  | Proposed | NU6.3 | 3428143 |
| 317 | R1 | Draft | NU6.3 | 3428143 |
| 318 |  | Draft | NU6.3 | 3428143 |
| 214 | R2 | Proposed | NU6.1 | 3146400 |
