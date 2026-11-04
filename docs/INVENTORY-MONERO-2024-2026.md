# Inventory: Monero fixes that Zephyr lacks (March 2024 → v0.18.5.4)

*Taken over from the webwallet's private work repo (2026-11-04). Note: §1 step 4 strikes out p2p/ZMQ/RPC server as "browser-irrelevant"; under POLICY §3 they do count. See PLAN-v2.3.0.md, daemon pass.*

*Date: 2026-11-04 · Originally written for the webwallet project ("we backport nothing"). Under `POLICY.md` this organisation does backport, but only clear security issues (§2) without breaking compatibility (§4); the selection is in `PLAN-v2.3.0.md` and `backports/v2.3.0.txt`.*

## 1. Why and how
Zephyr v2.3.0 is Monero master of 2024-03-12 (`15a4ff66f`) plus ~1 % own code (webwallet ANALYSE §3.1). Monero has since moved on to v0.18.5.4 (2026-10-14). Everything Monero repaired in those 2.5 years in `wallet2`, epee and the cryptonote serialisation is **not** in the core our wallet runs. This document says what that is and what it means for us.

Method (reproducible, §8):
1. All commits on Monero's `release-v0.18` since 2024-03-12 that touch a directory in our WASM build (`src/wallet`, `contrib/epee`, `cryptonote_basic`, `cryptonote_core`, `ringct`, `crypto`, `common`, `device`, `multisig`, `serialization`, `net`, `mnemonics`, `rpc`, `checkpoints`): **377**.
2. Merges out, and everything out whose subject is already in Zephyr's git history (came along via Monero master): **253** left.
3. Only commits that touch a file we compile or a header in those directories: **184** (appendix).
4. From those, manually struck out the commits that are browser-irrelevant (p2p, ZMQ, TCP/HTTP *server*, wallet-rpc server endpoints, Ledger/Trezor, SOCKS, Windows/ARM, build prep, CLI): **69** that touch paths our wallet actually runs. Those are grouped below.

Context for severity: the wallet runs in a WASM sandbox. A memory error in parsing cannot escape the sandbox, but it can corrupt the wallet's own linear memory, where the keys and the tx under construction also live. "Just a crash" is therefore not guaranteed. That weighs more heavily the less trusted the node is (modes C/D).

## 2. Summary
| Group | Count | Severity for us | Our mitigation (outside upstream) |
|---|---|---|---|
| A. Parsing of node data (epee JSON/binary, tx deserialisation) | 9 | **high** with foreign nodes, low with our own node | mode B (own node) by default; hash cross-check; C off in v1; fail-closed on every parse error |
| B. Scan/sync correctness (balance, key images, hashchain) | 17 | **medium–high**: wrong balance, missed spends | harness + stagenet tests on exactly these scenarios; "balance not current" when in doubt (§18) |
| C. Tx construction, fee, decoys, sanity checks | 10 | **high**: a wrong tx is irreversible | own JS sanity check before relay (`describe_tx_set`: destinations, amounts, fee, change) |
| D. Proof verification (reserve/spend proofs) | 5 | low (only for those who check others' proofs) | no proof checking in v1, or only with a warning |
| E. Multisig | 9 | none in v1 | do not offer multisig |
| F. Secrets and logging | 4 | low at the default log level (measured, §6) | log level 0, no persistent console logs, no debug in production |
| G. Other (checkpoints, approximate height, small fixes) | 15 | low | — |

**The five that matter most**, if only five were allowed: `4eae97404` sanity_check_pending_tx, `0125cf269` tx pubkey handling, `c147e2dfe` key images that stay unspent, `b99d15f08` reject non-monotonic output distribution, and the serialisation checks `d869dc098`/`214328387`.

## 3. Group A: parsing of node data
Everything the node sends back (`get_blocks.bin`, `get_outs`, `get_transactions`, JSON-RPC) goes through epee's portable-storage parser and the cryptonote deserialisation. That is the attack surface of a malicious or compromised node.

| Commit | Date | What | Relevance |
|---|---|---|---|
| `d869dc098` | 2026-09-04 | `cryptonote_basic`: serialisation checks (4 compiled files) | tx/block deserialisation from `get_blocks.bin`; hardening against malformed blobs |
| `214328387` | 2026-08-28 | checks in the cryptonote serialisation routine | same |
| `b66e2227c` | 2026-08-07 | `parse_and_validate_tx`: max-size parameter | bounds what a node can make us parse |
| `71e3be0e4` | 2026-09-22 | stricter validation of pruned tx blobs | the wallet fetches pruned txs |
| `7a7c42ffb` | 2026-05-21 | serialization: EOF at varint boundary | over-read on malformed input |
| `dedae5272` | 2026-06-01 | off-by-one over-read in epee's JSON unicode-escape parsing | **every JSON-RPC response passes through this** |
| `1b82d32a2` | 2026-07-26 | epee JSON parser: log injection | low (logs) |
| `74c313420` | 2024-11-19 | memcpy in `byte_slice` constructor | basic building block of the binary parser |
| `1d3d30c50` | 2025-07-11 | Cryptonight v1: catch invalid input | keys KDF; input is our own data |

What we do: own node as the default, hash cross-check against a second node, no mode C in v1, and **every parse exception in the worker = closed** (webwallet plan §18.5). That removes the opportunity, not the bug.

## 4. Group B: scan and sync correctness
| Commit | Date | What | Relevance |
|---|---|---|---|
| `0125cf269` | 2026-10-01 | inconsistent tx pubkey handling (6 compiled files) | outputs are recognised through the tx pubkey; a bug = missed or wrong receipts |
| `c147e2dfe` | 2025-12-12 | key images that wrongly stay unspent | **balance too high**; a send can fail on already-spent inputs |
| `9239d3669` | 2025-09-15 | recognise spends in the pool while scanning | balance is only right after confirmation; UI shows double available |
| `357b446a1` | 2026-09-21 | reset scan status for already processed outputs | rescan correctness |
| `72d91039e` | 2026-07-21 | validate cached transfer indices | corrupt cache → wrong state instead of an error |
| `987a2a77d` | 2026-07-22 | bounds check on additional derivations in `is_out_to_acc` | OOB read on malformed tx extra |
| `a09eb5cf4` | 2026-07-22 | task lifetime during parsed-block processing | use-after-free in the scan pipeline |
| `ef7bdda92` | 2026-09-19 | validate block hash when repairing an empty hashchain | otherwise a node can inject a false chain start |
| `d9236332a` | 2026-08-21 | data races in refresh error handlers | single-threaded in the WASM, low |
| `ef7a86c99` | 2026-05-22 | coinbase refresh against empty `vout` | crash on a malformed block |
| `839dba22c` | 2026-05-21 | avoid linear scans in pool state | performance |
| `0810f48a2` | 2026-09-13 | received-amount breakdown consistent | UI amounts |
| `c86fd739d` | 2026-09-13 | filter unchecked RPC error statuses | **fail-closed-relevant**: do not blindly trust the node's answer |
| `144b3f9e6` | 2026-09-30 | untrusted daemon status in sweep_unmixable | same |
| `34c7d31ef` | 2024-12-04 | shortchain history must include the base block | sync gap on reorg |
| `bbd635075` | 2026-08-05 | honour `max_blocks` in fast_refresh hash pulls | otherwise a node can push unbounded data |
| `a928cbc20` | 2024-10-06 | correct error on an unloadable cache | error handling |

What we do: these scenarios as stagenet tests in the harness (receive → spend → pool → confirmed; rescan; reorg simulation with a mocked node) and show "balance not current" as soon as there is doubt.

## 5. Group C: tx construction, fee, decoys, sanity
| Commit | Date | What | Relevance |
|---|---|---|---|
| `4eae97404` | 2026-08-26 | **`sanity_check_pending_tx`** (+1127): checks the constructed tx before signing/relay | line of defence against bugs and against a node that manipulates the input data; **we do not have that layer** |
| `b09e9bfe5` | 2026-09-06 | tx/partial-tx validation | same |
| `44412d357` | 2026-04-21 | change-address sanity check | otherwise change can go to a wrong address |
| `b99d15f08` | 2026-06-02 | **reject non-monotonic rct output distributions** | a node can steer decoy selection via `get_output_distribution` (privacy) or crash the wallet |
| `7507aed69` | 2026-07-10 | gamma picker against empty output windows | decoy selection; crash/loop |
| `ac37e75df` | 2026-08-25 | infinite loop in `estimate_tx_size_and_weight` with many outputs | hang on large sends |
| `8703b8a4c` | 2024-03-22 | transfers and sweeps same fee logic | fee inconsistency |
| `1e6a55109` | 2025-11-21 | `add_extra_nonce_to_tx_extra()` length | payment ID/extra nonce |
| `2de5e8227` | 2026-06-04 | check the result of `generate_output_ephemeral_keys` | output keys |
| `fbd80b3ca` | 2026-08-17 | concrete low priority when `adjust_priority` fails | fee choice |

What we do: **an own sanity check in the JS layer before `relayTxs`**: `describe_tx_set` on the signed set, compared with what the user entered (destinations, amounts per asset, fee within margin, change to own address, no unknown outputs). That is part of what `sanity_check_pending_tx` does, but on our side of the boundary; allowed under the policy, because it does not touch upstream. In addition a `get_output_distribution` monotonicity check in the health layer (cheap, pure JS).

## 6. Groups D–G, briefly
- **D. Proofs** (`2827d7fe8`, `11543143b`, `f855ffe87`, `04eeb3ba1`, `1bb17925f`): hardening of reserve/spend-proof verification; only relevant if the wallet checks *other people's* proofs. Not in v1.
- **E. Multisig** (`5550c0a87`, `7b1e9ca29`, `2094d38c8`, `00a444b11`, `d6f0a4d21`, `fe744ac31`, `b2cd62754`, `48053f75d`, `7d7a74848`): not offered in the webwallet.
- **F. Secrets and logging**: `65568d3a8` (view key out of the logs), `4b00f47d4` (clear additional tx keys), `00a444b11` (memory wipe), `cf9349e74` (device locking). **Measured 2026-11-04:** a full harness run at the default log level puts no view key, spend key or seed in the console. The risk exists only at a raised log level; production runs at 0 and does not log persistently.
- **G. Other**: Monero checkpoints for fast_refresh (`e5c424b38`, `eba42d6ad`, `3b268ae28`, `37202dfc5`; Zephyr has its own checkpoints), `get_approximate_blockchain_height` (`4634b8b53`, `afb9a1f15`; touches "date → height", which we do ourselves via headers, webwallet plan §6), lookahead/subaddress expansion (`e23d51bc1`, `1da19dac5`), `7e3edc29c` port parsing, `322953e62` default port.

**Features** that Zephyr also lacks but that are not fixes: background sync with only the view key (`e44e8b164`), SOCKS5 (`ce5437f06`), FCMP++ work on master. Not needed.

## 7. What this means
1. **For the threat model:** the core has known, repaired weak spots in parsing and tx construction. That is why "own node as default + hash cross-check + fail-closed" is not a luxury but the compensation for a 2.5-year-old wallet2. Mode C (foreign nodes) belongs in the wallet only once Zephyr has rebased.
2. **For our JS layer:** two concrete measures we can take ourselves without touching upstream: the sanity check before relay (§5) and the monotonicity check on `get_output_distribution`. Both go into the plan (§18.5).
3. **For upstream:** the list below goes to ZephyrProtocol as an issue, ordered by what we consider most serious. A rebase onto v0.18.5.x takes everything along at once (webwallet ANALYSE §3.1: ~2,600 lines of own code to rebase).
4. **Do not (webwallet context):** backport in the wallet repo ourselves. In this organisation it does happen, but only as a Monero cherry-pick with provenance, context-only conflict resolution and the compatibility tests from POLICY §6, precisely because one wrongly cherry-picked hunk in `wallet2.cpp` is worse than the bug it repairs.

**List for the Zephyr team (priority):** `4eae97404`, `b09e9bfe5`, `44412d357` (tx sanity); `d869dc098`, `214328387`, `b66e2227c`, `71e3be0e4`, `7a7c42ffb`, `dedae5272` (parsing); `0125cf269`, `c147e2dfe`, `9239d3669`, `ef7bdda92`, `987a2a77d`, `a09eb5cf4` (scanning); `b99d15f08`, `7507aed69`, `ac37e75df` (decoys/fees); `c86fd739d`, `144b3f9e6`, `bbd635075` (do not blindly trust node answers); `65568d3a8` (view key out of logs).

## 8. Reproducing
```bash
BASE=$(git -C <zephyr-clone> rev-parse 15a4ff66f)
for p in src/wallet contrib/epee src/cryptonote_basic src/cryptonote_core src/ringct src/crypto src/common \
         src/device src/multisig src/serialization src/net src/mnemonics src/rpc src/checkpoints; do
  gh api --paginate "repos/monero-project/monero/commits?sha=release-v0.18&since=2024-03-12T00:00:00Z&path=$p&per_page=100" \
    --jq '.[] | [.sha, .commit.author.date[:10], (.commit.message|split("\n")[0])] | @tsv'
done | sort -u -k1,1 > commits.tsv
git -C <zephyr-clone> log --format=%s > zephyr-subjects.txt   # strike out by subject
# per commit: gh api repos/monero-project/monero/commits/<sha> --jq '.files[].filename'  → filter on our source list
```

## Appendix: all 184 commits that touch our source files or headers
| Date | Commit | Subject | Touched files in our build |
|---|---|---|---|
| 2022-10-14 | `e44e8b164` | wallet: background sync with just the view key | account.cpp, account.h, cryptonote_config.h, wallet.h, wallet2.cpp, wallet2.h, wallet2_api |
| 2023-04-14 | `528cbac17` | Show IPv6 addresses in connection list | core_rpc_server_commands_defs.h |
| 2023-05-21 | `3f3229a9a` | Add byte_stream `value_type` and `data()` | byte_stream.h |
| 2023-11-03 | `678f5dab3` | wallet: create set_subaddress_lookahead wallet rpc endpoint | wallet_rpc_server.h, wallet_rpc_server_commands_defs.h |
| 2023-11-03 | `8f5a7b0f1` | wallet: ensure subaddress keys table is at least size of requested lookahead | wallet2.cpp |
| 2024-01-17 | `008ba966d` | blockchain sync: reduce disk writes from 2 to 1 per tx | blockchain.h, core_rpc_server_commands_defs.h, cryptonote_core.h, cryptonote_format_utils. |
| 2024-02-04 | `dd47d03cf` | Enforce Tx unlock_time is Zero by Relay Rule [RELEASE] | core_rpc_server_commands_defs.h, cryptonote_tx_utils.cpp, cryptonote_tx_utils.h, multisig_ |
| 2024-02-18 | `cd1c06038` | Daemon-specific proxy for the wallet-rpc. | wallet2.cpp, wallet2.h, wallet_rpc_server_commands_defs.h |
| 2024-03-12 | `31a7f12d5` | ringct: fix trunc_amount field name change | rctTypes.h |
| 2024-03-15 | `d6b35e97b` | Cleanup string_tools. | string_tools.cpp, string_tools.h |
| 2024-03-22 | `8703b8a4c` | wallet2: ensure transfers and sweeps use same fee calc logic rnd2 | wallet2.cpp |
| 2024-04-22 | `100a7d06e` | Add drop_and_recreate in privatefile class. | util.cpp, util.h |
| 2024-04-28 | `4634b8b53` | wallet2: fix stagenet get_approximate_blockchain_height | wallet2.cpp |
| 2024-04-30 | `755dddd2b` | common: support boost filesystem copy_options. | boost_serialization_helper.h, util.cpp, util.h, wallet2.cpp |
| 2024-05-01 | `738f5038b` | contrib: fix compilation error for boost 1.85 | portable_storage_val_converters.h |
| 2024-05-28 | `8dfb3661e` | epee: partially revert c56ee140 to fix linking errors | string_tools.cpp, string_tools.h |
| 2024-05-29 | `956d55c35` | build: prepare v0.18.3.4 | checkpoints.cpp |
| 2024-06-01 | `8c254e42e` | wallet: fetch pool txs in pruned form [RELEASE] | wallet2.cpp |
| 2024-06-19 | `e875a587e` | Fix ZMQ Tx Pruning | json_object.h |
| 2024-06-24 | `9a4520814` | Daemon RPC: add max_block_count field to /getblocks.bin | core_rpc_server_commands_defs.h, daemon_messages.h |
| 2024-06-24 | `c5ad937cc` | Fix ZMQ DaemonInfo: | message_data_structs.h |
| 2024-08-07 | `1f733fb86` | Make wallet2::estimate_fee static | wallet2.cpp, wallet2.h |
| 2024-08-14 | `7cb69fa6b` | epee: string_tools: keep full path in cut_off_extension | string_tools.cpp |
| 2024-08-14 | `c7d4bf491` | epee: string_tools: remove dot from get_extension | string_tools.cpp |
| 2024-08-17 | `ce5437f06` | Add Socks v5 support to daemon and wallet | error.h, fwd.h, parse.h, socks.h, socks_connect.h, wallet2.cpp |
| 2024-08-23 | `65568d3a8` | build: fix build with Boost 1.85 and remove instances of viewkey logging [RELEASE] | crypto.h, cryptonote_format_utils.cpp, cryptonote_tx_utils.cpp, device_default.cpp, keyval |
| 2024-08-27 | `0cd74568d` | Cleanup TCP throttling code (performance) + move connection checks | abstract_tcp_server2.h, abstract_tcp_server2.inl, network_throttle-detail.hpp |
| 2024-10-06 | `a928cbc20` | wallet2: fix error throw if unable to load cache | wallet2.cpp |
| 2024-10-09 | `ed70c1622` | Some cleanup in span/connection_context + few more checks | connection_context.h |
| 2024-11-19 | `74c313420` | Fix memcpy in byte_slice constructor | byte_slice.cpp |
| 2024-11-20 | `33e7943df` | epee: Drop unused in-tree MD5 | md5_l.h, md5_l.inl, md5global.h |
| 2024-12-04 | `34c7d31ef` | wallet: shortchain history should include base block | wallet2.cpp |
| 2024-12-13 | `13df86253` | contrib: force (de)serialization to create params section incase there is none. | http_server_handlers_map2.h |
| 2024-12-17 | `01bcd5292` | Fix build with boost ASIO 0.87. Support boost 1.66+ | abstract_tcp_server2.h, abstract_tcp_server2.inl, blockchain.h, connection_basic.hpp, http |
| 2024-12-28 | `36c598715` | Fix get_database_size on Windows | file_io_utils.cpp, file_io_utils.h |
| 2025-01-06 | `322953e62` | assign default port for http and https clients | abstract_http_client.cpp |
| 2025-01-09 | `27858049d` | crypto: make CRYPTO_DEFINE_HASH_FUNCTIONS adhere strict aliasing | generic-ops.h |
| 2025-01-18 | `f00ce66d4` | wallet: fix signed_tx_set RangeProofType serialization | wallet2.h |
| 2025-01-21 | `13ff355cf` | Set response limits on http server connections | abstract_tcp_server2.h, abstract_tcp_server2.inl, core_rpc_server.h, cryptonote_config.h,  |
| 2025-01-25 | `3fef29608` | build: prepare v0.18.4.0 | checkpoints.cpp |
| 2025-02-15 | `d14c3ca3d` | add wallet rpc call to get default fee priority | wallet_rpc_server.h, wallet_rpc_server_commands_defs.h |
| 2025-02-25 | `4acc0ea41` | Limit scope of TCP checks to incoming only | abstract_tcp_server2.inl |
| 2025-03-17 | `ba2dadb0d` | Correct Max / Min Block Waiting Periods | wallet2.cpp |
| 2025-03-20 | `5550c0a87` | fix: multisig stale data after failed refresh | wallet2.cpp, wallet2.h |
| 2025-03-25 | `97e1a49dd` | checkpoints: update to a recent block height | checkpoints.cpp |
| 2025-03-29 | `22d2d53af` | wallet: fix monero-wallet-rpc ignoring calls during sync | wallet_rpc_server.h |
| 2025-04-22 | `f96815084` | epee: fix string_tools on Windows | string_tools.cpp |
| 2025-04-28 | `e458bc0fa` | msys2 build: include int headers | keyvalue_serialization_overloads.h, perf_timer.h |
| 2025-05-20 | `e5c424b38` | checkpoints: support nearest lower checkpoint lookup | checkpoints.cpp, checkpoints.h |
| 2025-05-20 | `eba42d6ad` | wallet2: use nearest checkpoint to allow fast_refresh on old accounts | wallet2.cpp |
| 2025-05-28 | `8375edfc3` | wallet:set refresh interval to default when hitting tip of chain | wallet_rpc_server.h |
| 2025-06-07 | `b96af8e17` | build: prepare v0.18.4.1 | checkpoints.cpp |
| 2025-06-12 | `9f3d96eba` | Add check for exception in tcp accept handler | abstract_tcp_server2.inl |
| 2025-06-13 | `9002681c1` | Add new dynamic fees to ZMQ | daemon_messages.h |
| 2025-06-21 | `e23b759b3` | Skip ping connections in outgoing count | abstract_tcp_server2.h, abstract_tcp_server2.inl |
| 2025-06-26 | `3b268ae28` | wallet2: ignore checkpoints in fast_refresh when height < 1000 | wallet2.cpp |
| 2025-06-26 | `e23d51bc1` | wallet: improve lookahead logic & make rpc persistent | wallet2.cpp, wallet_rpc_server_commands_defs.h |
| 2025-07-07 | `1da19dac5` | wallet: refactor subaddress expansion & add to transfer test | wallet2.cpp, wallet2.h |
| 2025-07-11 | `1d3d30c50` | crypto: check+throw for Cryptonight v1 invalid input | hash.h |
| 2025-07-29 | `8f98dac4f` | wallet: deprecate wallet2::find_and_save_rings() | wallet2.cpp, wallet2.h |
| 2025-08-01 | `32f701b0c` | build: prepare v0.18.4.2 | checkpoints.cpp |
| 2025-08-20 | `f921431f3` | checkpoints: update to a recent block height | checkpoints.cpp |
| 2025-08-20 | `e6f43df56` | epee: include math header for upcoming Boost 1.89 | abstract_http_client.cpp |
| 2025-08-24 | `7e3edc29c` | epee: only parse valid port | net_parse_helpers.cpp |
| 2025-09-15 | `9239d3669` | wallet: identify spends in pool when scanning | wallet2.cpp, wallet2.h |
| 2025-09-17 | `182999297` | wallet2: warn instead of throw when RingDB doesn't include spend | wallet2.cpp |
| 2025-09-24 | `09f5cbbb9` | build: prepare v0.18.4.3 | checkpoints.cpp |
| 2025-10-05 | `014f3cd0a` | cryptonote_basic: remove redundant call to get_transaction_hash() in overload | cryptonote_format_utils.cpp |
| 2025-10-12 | `48252dd6a` | add getter for daemon proxy | wallet2.h |
| 2025-10-13 | `afb9a1f15` | use latest hard fork block for get_approximate_blockchain_height & update approximate_rolled_ba | wallet2.cpp |
| 2025-11-03 | `0761024b3` | tx_memory_pool: speedup get_complement() for large requests | cryptonote_core.h, hash.h, tx_pool.h |
| 2025-11-08 | `a83a46d60` | Fix logging deadlock | misc_log_ex.h |
| 2025-11-10 | `64f2d8e45` | build: prepare v0.18.4.4 | checkpoints.cpp |
| 2025-11-11 | `26cf4f914` | ledger: throw on secret view key export rejection | device_ledger.hpp |
| 2025-11-21 | `1e6a55109` | cryptonote_basic: fix add_extra_nonce_to_tx_extra() length | cryptonote_format_utils.cpp, varint.h |
| 2025-12-11 | `7baf2bde6` | epee: add missing cstdint include | http_base.h |
| 2025-12-12 | `d8d3cf973` | p2p: fix race causing dropped connections during sync | blockchain.h, cryptonote_core.h |
| 2025-12-12 | `c147e2dfe` | wallet2: fix edge case where tx's ki's remain marked unspent | wallet2.cpp |
| 2025-12-17 | `ec34c5b93` | build: prepare v0.18.4.5 | checkpoints.cpp |
| 2026-01-09 | `ee9e4a49b` | p2p: connection patches | abstract_tcp_server2.h, abstract_tcp_server2.inl |
| 2026-01-12 | `482daa744` | Tweak command_line::add_arg for clang 21 | command_line.h |
| 2026-01-15 | `7a4825b06` | wallet: add source info to describe_transfer RPC | wallet_rpc_server_commands_defs.h |
| 2026-02-13 | `a1a106d65` | build: prepare v0.18.4.6 | checkpoints.cpp |
| 2026-03-06 | `73f1eaaed` | Fix ZMQ-PUB reporting of mempool txes that were initially in stem phase | tx_pool.h |
| 2026-03-10 | `017c9022d` | Cleanup some of the fragmented levin handling | levin_protocol_handler_async.h |
| 2026-03-14 | `54229196b` | Improve unpack reserve handling | container.h, containers.h |
| 2026-03-18 | `7bc2d5a42` | p2p: fix hanging shutdown | abstract_tcp_server2.h, abstract_tcp_server2.inl, levin_protocol_handler_async.h, net_util |
| 2026-03-25 | `7f2cfe929` | zmq: add restricted rpc mode | daemon_handler.h, zmq_restricted_methods.h |
| 2026-03-26 | `f60b40091` | abstract_tcp_server2: add missing return | abstract_tcp_server2.inl |
| 2026-04-06 | `e7b121ac1` | wallet2: fix background wallet detection in verify_password() | wallet2.cpp |
| 2026-04-08 | `1f1e74b39` | build: prepare v0.18.5.0 | checkpoints.cpp |
| 2026-04-08 | `7b1e9ca29` | multisig: add flag to skip refresh after multisig import | wallet2.cpp, wallet2.h, wallet_rpc_server_commands_defs.h |
| 2026-04-09 | `1d2ae2138` | p2p: isolate regtest from mainnet bootstrap state | cryptonote_core.h |
| 2026-04-19 | `2094d38c8` | wallet2: add parse multisig tx sanity checks | wallet2.cpp |
| 2026-04-21 | `44412d357` | cryptonote_core: add change address sanity check | cryptonote_tx_utils.cpp |
| 2026-04-21 | `874c77197` | cryptonote_basic: pruned hash return bool | cryptonote_format_utils.cpp, cryptonote_format_utils.h, wallet2.cpp |
| 2026-04-21 | `14e333217` | connection: try-catch handles | abstract_tcp_server2.inl, misc_log_ex.h |
| 2026-04-22 | `8a20fd2bc` | blockchain_utilities: fix --data-dir option | cryptonote_core.h |
| 2026-04-24 | `54abe12f9` | wallet2: remove deprecated txs_as_hex | wallet2.cpp |
| 2026-04-27 | `2827d7fe8` | wallet2: reject duplicate outputs in reserve proofs | wallet2.cpp |
| 2026-04-27 | `11543143b` | wallet2: use decodeRct for reserve proof amount validation | wallet2.cpp |
| 2026-04-28 | `bf314b7ab` | p2p: wait_for on shutdown instead of indefinite wait | abstract_tcp_server2.inl |
| 2026-04-28 | `f855ffe87` | wallet2: throw if reserve proof can't be parsed | wallet2.cpp |
| 2026-04-28 | `04eeb3ba1` | wallet2: ensure daemon returns correct tx for spend proof | wallet2.cpp |
| 2026-04-29 | `c5c9420d8` | p2p: cleaner connection close() | abstract_tcp_server2.inl |
| 2026-05-08 | `878c78176` | zmq: apply restricted-mode privacy filtering to get_transaction_pool | cryptonote_core.h, tx_pool.h |
| 2026-05-08 | `dede3a5d7` | crypto: implement CTHR_THREAD_CLOSE to avoid leaking memory | c_threads.h |
| 2026-05-09 | `2a6f64d8f` | epee: skip IPv4 TOS option for non-IPv4 peers | abstract_tcp_server2.inl |
| 2026-05-15 | `7de175802` | rpc: restrict get_alt_blocks_hashes | core_rpc_server.h |
| 2026-05-17 | `6d36b1980` | wallet_rpc_server: remove unused finalize_multisig endpoint | wallet_rpc_server.h, wallet_rpc_server_commands_defs.h |
| 2026-05-19 | `d2e4cbcda` | http: share deterministic header field parser | http_base.h, http_client.h, http_protocol_handler.inl |
| 2026-05-20 | `98b350f7a` | contrib: fix unaligned&aliased levin buffer reads | levin_protocol_handler_async.h |
| 2026-05-20 | `4b00f47d4` | wallet2: clear m_additional_tx_keys during bg sync | wallet2.cpp |
| 2026-05-21 | `7d3397781` | net: canonicalize Tor and I2P hostnames | host.h |
| 2026-05-21 | `7a7c42ffb` | serialization: handle EOF at varint boundary | binary_archive.h |
| 2026-05-21 | `839dba22c` | wallet2: avoid linear scans in pool state updates | wallet2.cpp, wallet2.h |
| 2026-05-22 | `ef7a86c99` | wallet2: guard optimized coinbase refresh against empty vout | wallet2.cpp |
| 2026-05-31 | `b7ca9e73f` | p2p: close zone connections before stopping net servers | abstract_tcp_server2.h, abstract_tcp_server2.inl |
| 2026-05-31 | `ec60113e0` | p2p: make stop signal idempotent | abstract_tcp_server2.inl |
| 2026-06-01 | `dedae5272` | fix off-by-one over-read in match_string2 unicode escape parsing | parserse_base_utils.cpp |
| 2026-06-02 | `b99d15f08` | wallet2: reject non-monotonic rct output distributions | wallet2.cpp |
| 2026-06-03 | `00a444b11` | Multisig tx builder: fix incomplete memory wipe | multisig_tx_builder_ringct.cpp |
| 2026-06-03 | `2b97e3ae0` | wallet2: fix double unlock of a lock | wallet2.cpp |
| 2026-06-04 | `2de5e8227` | Fix: check hwdev.generate_output_ephemeral_keys result | cryptonote_tx_utils.cpp |
| 2026-06-08 | `0859397f2` | Miner: fixed thread 0 always mining with secure JIT (worse performance) | miner.cpp |
| 2026-06-08 | `ad72a6c25` | fix typo in hashchain bounds error | wallet_errors.h |
| 2026-06-09 | `4f6652f35` | net: cap aggregate ZMQ receive size | zmq.h |
| 2026-06-09 | `d6f0a4d21` | wallet2: store multisig nonce erasure before returning signed txset | wallet2.cpp, wallet2.h |
| 2026-06-15 | `d67a8d8e9` | build: prepare v0.18.5.1 | checkpoints.cpp |
| 2026-06-22 | `f277d328c` | p2p, rpc: group public IPv6 connection limits by /64 | http_protocol_handler.h, http_protocol_handler.inl, http_server_impl_base.h, net_utils_bas |
| 2026-07-10 | `f618ee113` | Fix stall issues with p2p | abstract_tcp_server2.h, abstract_tcp_server2.inl |
| 2026-07-10 | `7507aed69` | wallet2: guard gamma picker against zero-output windows | wallet2.cpp |
| 2026-07-11 | `146f80106` | epee: avoid bad_weak_ptr during connection teardown | abstract_tcp_server2.inl |
| 2026-07-20 | `246d76f4f` | crypto: fix ARMv8 slow-hash inline assembly constraints | slow-hash.c |
| 2026-07-21 | `72d91039e` | wallet2: validate cached transfer indices | wallet2.cpp |
| 2026-07-22 | `a09eb5cf4` | wallet2: fix task lifetime during parsed block processing | wallet2.cpp |
| 2026-07-22 | `987a2a77d` | wallet2: bounds check additional derivations in is_out_to_acc | wallet2.cpp |
| 2026-07-23 | `d1508916b` | rpc: recover from oversized ZMQ requests | message.h |
| 2026-07-23 | `5eeff1d9c` | Optimize hashing of generic types | generic-ops.h, random.c, random.h, rctTypes.h |
| 2026-07-25 | `af88effd9` | rpc: disable get_transaction_pool in restricted mode | core_rpc_server.h |
| 2026-07-25 | `dfb85dde0` | rpc: hide ZMQ request contents in restricted mode | zmq_server.h |
| 2026-07-26 | `1b82d32a2` | epee: prevent JSON parser log injection | http_server_handlers_map2.h, parserse_base_utils.cpp, portable_storage_from_json.h |
| 2026-07-26 | `f397f3920` | p2p: stop buffered dispatch after fatal notifications | levin_abstract_invoke2.h, levin_protocol_handler_async.h |
| 2026-08-01 | `cf9349e74` | device: implement default device locking | device_default.cpp, device_default.hpp |
| 2026-08-03 | `1d45021cd` | rpc: hide sensitive txs from restricted block templates | blockchain.h, core_rpc_server.h, cryptonote_core.h, tx_pool.h |
| 2026-08-03 | `9bf193728` | p2p: use a bool for send() | levin_abstract_invoke2.h, levin_protocol_handler_async.h |
| 2026-08-03 | `1bb17925f` | wallet2: validate key image domain in reserve proofs | wallet2.cpp |
| 2026-08-04 | `017f3cf6b` | wallet_rpc_server: add weight to describe_transfer | wallet_rpc_server_commands_defs.h |
| 2026-08-05 | `bbd635075` | wallet2: honor max_blocks bound during fast_refresh hash pulls | wallet2.cpp, wallet2.h |
| 2026-08-07 | `b66e2227c` | cryptonote_basic: parse_and_validate_tx param to check max size | cryptonote_format_utils.cpp, cryptonote_format_utils.h, tx_sanity_check.cpp, wallet2.cpp |
| 2026-08-10 | `478df04f3` | Blockchain: improve check_block_timestamp() overloads | blockchain.h |
| 2026-08-10 | `b2cd62754` | wallet2: keep multisig import state consistent across failed refreshes | wallet2.cpp |
| 2026-08-11 | `37202dfc5` | checkpoints: exclude equal height in get_nearest_checkpoint_height | checkpoints.cpp |
| 2026-08-11 | `c7c436868` | p2p: don't reset timeout timer for handshakes | levin_protocol_handler_async.h |
| 2026-08-17 | `fbd80b3ca` | wallet2: return concrete low priority when adjust_priority fails | wallet2.cpp |
| 2026-08-18 | `8379bdfa2` | wallet_rpc_server: stop refresh on shutdown | wallet2.cpp, wallet2.h, wallet_rpc_server.h |
| 2026-08-19 | `8c4dfaefc` | build: prepare v0.18.5.3 | checkpoints.cpp |
| 2026-08-21 | `d9236332a` | wallet2: fix data races in refresh error handlers | wallet2.cpp |
| 2026-08-22 | `3c0980f59` | wallet2: abort in-flight daemon request on shutdown | abstract_http_client.h, http_client.h, net_helper.h, net_ssl.h, wallet2.h |
| 2026-08-25 | `ac37e75df` | wallet2: fix infinite loop in estimate_tx_size_and_weight on large n_outputs | wallet2.cpp |
| 2026-08-26 | `4eae97404` | add sanity_check_pending_tx | cryptonote_tx_utils.cpp, cryptonote_tx_utils.h, pending_tx_validation.h, wallet2.cpp, wall |
| 2026-08-28 | `214328387` | Add checks in cryptonote serialization routine | crypto.h, cryptonote_basic.h, rctTypes.h, serialization.h |
| 2026-09-01 | `281c1d41a` | epee: prevent log injection from malformed HTTP headers | http_client.h, http_protocol_handler.inl |
| 2026-09-01 | `525a6f0b6` | wallet_api: expose signed message verification details | wallet.h, wallet2.h, wallet2_api.h |
| 2026-09-04 | `d869dc098` | cryptonote_basic: serialization checks | container.h, containers.h, cryptonote_basic.h, cryptonote_basic_impl.cpp, cryptonote_basic |
| 2026-09-06 | `b09e9bfe5` | tx/partial tx validation improvements | pending_tx_validation.h, wallet2.cpp, wallet2.h |
| 2026-09-06 | `587315ce9` | wallet_rpc_server: reject --password with --wallet-dir | wallet2.cpp, wallet2.h |
| 2026-09-13 | `52b33f4fb` | common: sanitize message writer console output | scoped_message_writer.h |
| 2026-09-13 | `0810f48a2` | wallet2: keep received amount breakdown consistent | wallet2.cpp |
| 2026-09-13 | `c86fd739d` | wallet2: filter unchecked RPC error statuses | wallet2.cpp |
| 2026-09-13 | `c683bf088` | wallet2: validate public node addresses before display | wallet2.cpp |
| 2026-09-15 | `fe744ac31` | multisig: erase all copies of a nonce at the same time | wallet2.cpp |
| 2026-09-16 | `7ba5e2cca` | epee: remove obsolete MyMonero conversion | keyvalue_serialization_overloads.h, portable_storage_val_converters.h |
| 2026-09-16 | `57a37a156` | wallet2: preserve required SSL when allowing chained certificates | wallet2.cpp |
| 2026-09-19 | `ef7bdda92` | wallet2: validate block hash when repairing empty hashchain | wallet2.cpp |
| 2026-09-21 | `357b446a1` | wallet2: reset scan status for already processed outputs | wallet2.cpp |
| 2026-09-22 | `71e3be0e4` | cryptonote_protocol: tighten pruned transaction blob validation | cryptonote_format_utils.cpp, cryptonote_format_utils.h |
| 2026-09-22 | `096abdaa2` | net: detect half-closed sockets before connection reuse | net_helper.h |
| 2026-09-30 | `144b3f9e6` | wallet2: sanitize untrusted daemon status in sweep unmixable | wallet2.cpp |
| 2026-10-01 | `0125cf269` | wallet: fix inconsistent tx pubkey handling | crypto-ops-data.c, crypto-ops.c, crypto-ops.h, crypto.cpp, crypto.h, cryptonote_basic_impl |
| 2026-10-02 | `48053f75d` | wallet2: update multisig info for detached outputs | wallet2.cpp, wallet2.h |
| 2026-10-02 | `7d7a74848` | wallet2: trim stale transfer maps after output imports | wallet2.cpp, wallet2.h |
| 2026-10-14 | `69762b618` | build: prepare v0.18.5.4 | checkpoints.cpp |
| 2026-10-14 | `b97c1627b` | epee: allow decimal strings when converting to uint64 | portable_storage_val_converters.h |
