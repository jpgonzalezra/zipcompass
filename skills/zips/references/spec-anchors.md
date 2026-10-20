Rendered from spec-anchors.tsv by scripts/index.py, with the titles and lines of protocol/protocol.tex at zips@a34cfc091434275120ff017c92c3b50d3cef623a (2026-10-16). Do not edit.

## Transaction consensus rules

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| txnconsensus | Transaction Consensus Rules | subsubsection | 13620 | zebra-chain src/transaction.rs, zebra-consensus src/transaction/check.rs, zebra-state src/service/check/utxo.rs; zcash_protocol src/consensus.rs, zcash_primitives src/transaction/builder.rs, zcash_transparent src/bundle.rs | the v6 and Ironwood rules are `\nusixthreeonwarditem` and `\nusixthree` text, absent from protocol.pdf |

## Transaction encoding

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| txnencoding | Transaction Encoding and Consensus | subsection | 13336 | zebra-chain src/transaction/serialize.rs; zcash_primitives src/transaction/mod.rs, zcash_protocol src/constants.rs | the Ironwood rows of the v5/v6 field table carry only `\setnusixthree` and print in protocol.pdf; the presence footnote is `\notbeforenusixthree` |

## Transaction identifiers

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| txnidentifiers | Transaction Identifiers | subsubsection | 13608 | zebra-chain src/transaction/hash.rs; zcash_client_backend src/proto/compact_formats.rs | v5 txid per ZIP 244, v6 per ZIP 229, which adds the Ironwood digest to the ZIP 244 tree; the range cites each |

## Block header

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| blockheader | Block Header Encoding and Consensus | subsection | 14172 | zebra-chain src/block/serialize.rs, src/block/commitment.rs, src/parameters/network_upgrade.rs; zcash_protocol src/constants.rs | hashBlockCommitments per ZIP 221 and ZIP 244 |

## Spend, Output and Action encodings

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| spendencodingandconsensus, outputencodingandconsensus, actionencodingandconsensus | Spend Description Encoding and Consensus; Output Description Encoding and Consensus; Action Description Encoding and Consensus | subsection, subsection, subsection | 13958, 14022, 14087 | zebra-chain src/sapling/spend.rs, src/sapling/output.rs, src/orchard/action.rs; zcash_client_backend src/proto/compact_formats.rs | the compact form is ZIP 307; the Ironwood bundle reuses the Action encoding |

## Funding streams and subsidies

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| fundingstreams, zip214fundingstreams, subsidies | Payment of Funding Streams\notbeforenusix{,\notnusixone{ and} Deferred Lockbox}\notbeforenusixone{, and Lockbox Disbursement}; ZIP 214 Funding Streams; Calculating Block Subsidy\notbeforecanopy{, Funding Streams,}\notbeforenusixone{ Lockbox Disbursement,} and Founders' Reward | subsection, subsubsection, subsection | 14884, 15011, 14657 | zebra-chain src/parameters/network/subsidy.rs, src/parameters/network/subsidy/constants/mainnet.rs; zebra-consensus src/block/subsidy.rs | the heading titles themselves are gated (`\notbeforenusix`, `\notbeforenusixone`); the NU7 rows of by-area.md apply |

## Key components

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| saplingkeycomponents, orchardkeycomponents | Sapling Key Components; Orchard Key Components | subsubsection, subsubsection | 5581, 5750 | zebra-chain src/sapling/keys.rs, src/orchard/keys.rs; nothing in librustzcash links them, the surface is zcash_keys src/keys.rs | ZIP 32 for derivation, ZIP 316 for unified keys |

## Address encodings

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| transparentaddrencoding, saplingpaymentaddrencoding, orchardpaymentaddrencoding | Transparent Addresses; Sapling Payment Addresses; Orchard Raw Payment Addresses | subsubsubsection, subsubsubsection, subsubsubsection | 12558, 12762, 12994 | zebra-chain src/transparent/address.rs, src/orchard/address.rs; pczt src/sapling.rs, src/orchard.rs; nothing in zcash_address links them, and it is the surface | unified encodings are ZIP 316, per revision (by-area.md) |

## Networks

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| networks | Mainnet and Testnet | subsection | 4412 | nothing in the checkouts links it; the surface is zcash_protocol src/consensus.rs and zebra-chain src/parameters/network_upgrade.rs | activation block hashes up to NU6.2, no heights, no NU6.3 block at this commit; its one `\nusixthree` span is about zcashd; the ladder is deployments.md and the node outranks both |

## Note commitment trees

| Anchor | Title | Level | Line | Where | Caveat |
|---|---|---|---|---|---|
| merkletree (alias of notecommitmenttrees), notecommitmenttrees | Note Commitment Trees; Note Commitment Trees | subsection, subsection | 4313, 4313 | zebra-chain src/sapling/tree.rs, src/orchard/tree.rs | `merkletree` is the `\extralabel` alias the code links; the heading is `notecommitmenttrees` |
