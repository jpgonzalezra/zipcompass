Rendered from by-area.tsv by scripts/index.py, with the statuses of the index and the heights of deployments.md. Do not edit.

## Compact blocks and the light-client protocol

| ZIP | Title | Revision | Status | Deployment | Where | Caveat |
|---|---|---|---|---|---|---|
| 307 | Light Client Protocol for Payment Detection |  | Draft |  | zcash_client_backend::{proto, scanning}; lightwallet-protocol walletrpc/compact_formats.proto | deployed through software, not an upgrade: the protocol every light wallet speaks today |
| 225 | Version 5 Transaction Format |  | Final |  | zcash_primitives::transaction | v5 transaction format |
| 229 | Version 6 Transaction Format |  | Draft | Draft, and NU6.3 activates on mainnet at 3428143 | zcash_primitives::transaction | the v6 format NU6.3 introduced |
| 244 | Transaction Identifier Non-Malleability |  | Final |  | zcash_primitives::transaction::txid | txid and auth digests; v6 extends the digest tree |
| 224 | Orchard Shielded Protocol |  | Final |  | zcash_client_backend::proto (CompactOrchardAction conversions); lightwallet-protocol walletrpc/compact_formats.proto | Orchard actions in compact form |
| 258 | Deployment of the NU6.3 Network Upgrade |  | Draft | Draft, and NU6.3 activates on mainnet at 3428143 | zcash_protocol::consensus | the NU6.3 deployment ZIP |
| 2005 | Ironwood Quantum Recoverability |  | Proposed | Proposed, and NU6.3 activates on mainnet at 3428143 | zcash_client_backend::scanning (scanning/compact.rs) | Ironwood pool; recoverable notes carry lead byte 0x03 |
| 221 | FlyClient - Consensus-Layer Changes |  | Final |  | zcash_history; zebra-chain history_tree.rs, primitives/zcash_history.rs, block/commitment.rs | FlyClient commitments in the block header |
| 209 | Prohibit Out-of-Range Chain Value Pool Balances |  | Final |  | zebra-chain value_balance.rs | chain value pool balances |

## Transaction parsing and txids

| ZIP | Title | Revision | Status | Deployment | Where | Caveat |
|---|---|---|---|---|---|---|
| 225 | Version 5 Transaction Format |  | Final |  | zcash_primitives::transaction | v5 format |
| 229 | Version 6 Transaction Format |  | Draft | Draft, and NU6.3 activates on mainnet at 3428143 | zcash_primitives::transaction | v6, ungated in the crate |
| 244 | Transaction Identifier Non-Malleability |  | Final |  | zcash_primitives::transaction::txid | non-malleable txids; the crate computes the v6 extension |
| 2003 | Disallow version 4 transactions |  | Draft | NU7, mainnet height pending | zcash_primitives::transaction | the version number MUST be 5 or 6 from NU7 onward |

## Fees, input selection, dust

| ZIP | Title | Revision | Status | Deployment | Where | Caveat |
|---|---|---|---|---|---|---|
| 317 | Proportional Transfer Fee Mechanism | R0 | Active |  | zcash_primitives::transaction::fees::zip317; zcash_client_backend::fees::zip317 | the fee rule in force; marginal fee 5000 in the crate |
| 317 | Proportional Transfer Fee Mechanism | R1 | Draft | Draft, and NU6.3 activates on mainnet at 3428143 | zcash_client_backend::fees | adds Ironwood-pool actions to logical_actions |
| 317 | Proportional Transfer Fee Mechanism | R2 | Draft |  | zcash_client_backend::fees | adds fee handling for memo bundles (ZIP 231) |
| 2009 | Reduce Marginal Fee to 1000 Zatoshis and Raise the Weight Ratio Cap to 10 |  | Draft |  | zcash_primitives::transaction::fees::zip317 | wallets SHOULD adopt marginal_fee 1000 at mainnet 3590000; the crate still carries 5000 |
| 315 | Best Practices for Wallet Implementations |  | Draft |  | zcash_client_backend::data_api::wallet::input_selection (SpendPolicy, GreedyInputSelector) | "Information leakage for transfers between pools": wallets MUST NOT automatically combine funds across pools to satisfy a transfer. librustzcash main (3c76c2d822, 2026-10-09) leaves it to the caller: the default SpendPolicy permits every pool and the selector may combine them; restrict SpendPolicy to one pool, or use DustAction::AddDustToFee, to stay in one pool |

## Pool migration

| ZIP | Title | Revision | Status | Deployment | Where | Caveat |
|---|---|---|---|---|---|---|
| 318 | Orchard to Ironwood Migration |  | Draft | Draft, and NU6.3 activates on mainnet at 3428143 | zcash_pool_migration; zcash_protocol::zip318 | Orchard to Ironwood migration, not a payments ZIP |

## Addresses, keys, viewing keys

| ZIP | Title | Revision | Status | Deployment | Where | Caveat |
|---|---|---|---|---|---|---|
| 316 | Unified Addresses and Unified Viewing Keys | R0 | Active |  | zcash_address; zcash_keys::keys | what zcash_address 0.13.0 encodes (uview) |
| 316 | Unified Addresses and Unified Viewing Keys | R2 | Draft |  | zcash_address 0.14.0-pre.1; zcash_keys::keys | zu, tu, uvf, uvi; zcash_keys encodes Revision 0 when representable and Revision 2 otherwise |
| 32 | Shielded Hierarchical Deterministic Wallets |  | Final |  | zcash_keys::keys | shielded HD key derivation |
| 320 | Defining an Address Type to which funds can only be sent from Transparent Addresses |  | Active |  | zcash_address | TEX addresses: funds only from transparent sources |
| 173 | Bech32 Format |  | Final |  | zcash_address | Bech32 |

## Payment requests, PCZT

| ZIP | Title | Revision | Status | Deployment | Where | Caveat |
|---|---|---|---|---|---|---|
| 321 | Payment Request URIs |  | Active |  | zip321 (components/zip321) | payment request URIs |
| 374 | Partially Created Zcash Transaction Format | R0 | Draft |  | pczt | per-revision |

## Network upgrades

| ZIP | Title | Revision | Status | Deployment | Where | Caveat |
|---|---|---|---|---|---|---|
| 200 | Network Upgrade Mechanism |  | Final |  | zcash_protocol::consensus | the upgrade mechanism |
| 252 | Deployment of the NU5 Network Upgrade |  | Final | NU5 activates on mainnet at 1687104 | zcash_protocol::consensus | the NU5 deployment ZIP |
| 253 | Deployment of the NU6 Network Upgrade |  | Final | NU6 activates on mainnet at 2726400 | zcash_protocol::consensus | the NU6 deployment ZIP |
| 255 | Deployment of the NU6.1 Network Upgrade |  | Final | NU6.1 activates on mainnet at 3146400 | zcash_protocol::consensus | the NU6.1 deployment ZIP |
| 256 | Deployment of Consensus Bug Fixes Between NU6.1 and NU6.2 |  | Final |  | zcash_protocol::consensus | consensus bug fixes between NU6.1 and NU6.2; no activation height of its own |
| 257 | Deployment of the Orchard Temporary Vulnerability Mitigation and NU6.2 Network Upgrade |  | Final | NU6.2 activates on mainnet at 3364600 | zcash_protocol::consensus | the NU6.2 deployment ZIP |
| 258 | Deployment of the NU6.3 Network Upgrade |  | Draft | Draft, and NU6.3 activates on mainnet at 3428143 | zcash_protocol::consensus | the NU6.3 deployment ZIP |
| 259 | Deployment of the NU7 Network Upgrade |  | Draft | NU7, mainnet height pending | zcash_protocol::consensus | the NU7 deployment ZIP |

## Issuance, funding streams, NSM

| ZIP | Title | Revision | Status | Deployment | Where | Caveat |
|---|---|---|---|---|---|---|
| 207 | Funding Streams | R1 | Final | NU6 activates on mainnet at 2726400 | zcash_protocol; zebra-chain parameters/network/subsidy/ (constants/mainnet.rs) | the Canopy and NU6 streams |
| 207 | Funding Streams | R2 | Draft | NU7, mainnet height pending | none yet: zebra at v6.3.0-247 (2026-09-16) has no NU7 streams; the surface is zebra-chain parameters/network/subsidy/ (constants/mainnet.rs) | the NU7 streams |
| 214 | Consensus rules for a Zcash Development Fund | R1 | Final | NU6 activates on mainnet at 2726400 | zebra-consensus block/subsidy | the Canopy and NU6 rules |
| 214 | Consensus rules for a Zcash Development Fund | R2 | Proposed | Proposed, and NU6.1 activates on mainnet at 3146400 | zebra-chain parameters/network/subsidy/ (constants/mainnet.rs), POST_NU6_1_FUNDING_STREAMS; zebra-consensus block/subsidy | the NU6.1 streams of ZIP 1016 |
| 214 | Consensus rules for a Zcash Development Fund | R3 | Draft | NU7, mainnet height pending | none yet: zebra at v6.3.0-247 (2026-09-16) has no NU7 rules; the surface is zebra-consensus block/subsidy | the NU7 rules |
| 1015 | Block Subsidy Allocation for Non-Direct Development Funding |  | Final |  | zebra-chain parameters/network/subsidy/ (constants/mainnet.rs) | block subsidy allocation for non-direct development funding |
| 2001 | Lockbox Funding Streams |  | Final |  | zebra-chain parameters/network/subsidy/ (constants/mainnet.rs), NU6 lockbox | lockbox funding streams |
| 233 | Network Sustainability Mechanism: Removing Funds From Circulation |  | Draft |  | none: zebra at v6.3.0-247 (2026-09-16) does not implement it, and ZIP 233 was dropped from the v6 format (zebra-rpc methods/types/transaction.rs) | NSM: removing funds from circulation |
| 234 | Network Sustainability Mechanism: Issuance Smoothing |  | Draft |  | none: zebra at v6.3.0-247 (2026-09-16) does not implement it | NSM: issuance smoothing |
| 235 | Remove 60% of Transaction Fees From Circulation |  | Draft | NU7, mainnet height pending | none: zebra at v6.3.0-247 (2026-09-16) does not implement it | NSM: removing part of the transaction fees from circulation |
| 237 | Network Sustainability Mechanism: Halving-Preserving Issuance |  | Draft | NU7, mainnet height pending | none: zebra at v6.3.0-247 (2026-09-16) does not implement it | NSM: halving-preserving issuance |
| 2008 | Update to `FS_FPF_ZCG_H3` address list |  | Draft | NU7, mainnet height pending | none yet: zebra at v6.3.0-247 (2026-09-16) still carries the previous FS_FPF_ZCG_H3 address in zebra-chain parameters/network/subsidy/ (constants/mainnet.rs) | FS_FPF_ZCG_H3 address list |

## Shielded protocols

| ZIP | Title | Revision | Status | Deployment | Where | Caveat |
|---|---|---|---|---|---|---|
| 224 | Orchard Shielded Protocol |  | Final |  | orchard | Orchard |
| 212 | Allow Recipient to Derive Ephemeral Secret from Note Plaintext |  | Final |  | sapling-crypto | ephemeral secret derived from the note plaintext |
| 213 | Shielded Coinbase |  | Final |  | zebra-consensus; sapling-crypto, orchard | shielded coinbase |
| 216 | Require Canonical Jubjub Point Encodings |  | Final |  | sapling-crypto | canonical Jubjub point encodings |
