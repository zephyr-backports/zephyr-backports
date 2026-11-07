# zephyr-cpp v2.3.0-sec.2 picks (round 16, 2026-11-07)

Fork `~/github/zephyr-backports/zephyr-cpp`, branch `wip/sec.2` created from `origin/security/v2.3.0`
(`3a2ee602e`). List `backports/zephyr-cpp-686fbdc.txt`, `tools/backport.sh ... --only sec.2`, upstream
`monero-cpp/master` (local clone `~/github/clones/woodser/monero-cpp`).

**Result: no pick landed.** Every one of the nine picks stopped on a conflict whose pre-image is not in
the fork (POLICY §5: semantic conflict). Each pick was aborted with `git cherry-pick --abort` and marked
`conflict` in the list. `wip/sec.2` is still at `3a2ee602e`, with 0 commits above the base.

"Upstream hunks" counts the `@@` hunks of `git show <sha>`; "conflict hunks" counts the conflict markers
`tools/backport.sh` reported (the number in the list's description). The conflict diffs, as git left
them before the abort, are in `zephyr-cpp-sec2-conflicts/<sha>.diff`.

| monero-cpp sha | date | PR | upstream hunks | conflict hunks | what is missing in the fork | resolution | identical |
|---|---|---|---|---|---|---|---|
| `6f1b95645d4472ecb5bb2a46f3d496877dc5ae93` | 2026-07-22 | #114 | 2 | 1 | The conflict in `close()` could be resolved context-only, but the clean second hunk adds `assert_not_closed();` to `lock_and_sync()`, and the context needs `m_is_closed`. Neither symbol exists anywhere in the fork (`git grep` empty); both come from `2ff66be` (#106), which the list skips as semantic. As picked, it would not compile. | aborted, `conflict` | n/a |
| `3c80e5b0ccb75f5078fbe9285a63461352dac2f9` | 2026-11-02 | #182 | 1 | 1 | The removed line `m_num_blocks_to_unlock = iter1 == balance_per_subaddress.end() ? 0 : iter2->second.second.first;` is commented out in the fork, which sets `m_num_blocks_to_unlock = 0` (Zephyr adaptation `071604a`). In the fork `iter2->second` is a `std::map<std::string, uint64_t>` (per asset), so upstream's added line would not compile. | aborted, `conflict` | n/a |
| `069027d45a87cca3865434b00baa83dfc03214cf` | 2026-08-24 | none in subject | 1 | 1 | The fork's `monero_wallet_keys::create_wallet_from_keys` takes `(network_type, address, view_key, spend_key, language)`; there is no `monero_wallet_config` overload and no `config_normalized`, which the added line assigns to. | aborted, `conflict` | n/a |
| `90995d8774fac499a47539887c445052ea0feaf2` | 2026-08-26 | #153 | 1 | 1 | The removed line `return *(m_block->m_height);` reads `return *((*m_block)->m_height);` in the fork, where `m_block` is `boost::optional<std::shared_ptr<monero_block>>` (`monero_daemon_model.h:172`). The guard line is `m_block == boost::none`, not `nullptr`. | aborted, `conflict` | n/a |
| `a199e46f34584c32837745402180cf11cc0f159c` | 2026-08-25 | #149 | 3 | 1 | The removed condition in `merge_incoming_transfer` has an extra `&& aTransfer->m_asset_type == transfer->m_asset_type` in the fork. Upstream's replacement drops that condition: more than context. The other two hunks (daemon `merge_tx`, destinations) applied cleanly. | aborted, `conflict` | n/a |
| `1440bb3dfdb3d04ee1ae7310845c4341802b9e2d` | 2026-08-06 | none in subject | 6 | 2 | The fork's `get_txs(query)` delegates to a `get_txs(query, missing_tx_hashes)` overload, and its re-fetch block differs (`m_block == boost::none`, `std::cout` warning, recursive call with `missing_tx_hashes`); the removed `MWARNING` and `txs = get_txs(*_query);` lines are not there. `monero_wallet_rpc.cpp/.h` do not exist in the fork (modify/delete). | aborted, `conflict` | n/a |
| `65bd8bb5e553d48f8317a5c9b3135f1e04ce53b2` | 2026-08-21 | #137 | 4 | 2 | Three of the four hunks change `get_blocks_from_transfers`, `get_blocks_from_outputs` and `free(std::shared_ptr<monero_tx>)`, none of which exist in the fork (`git grep` empty). Only the `free(std::shared_ptr<monero_block>)` hunk has its pre-image. | aborted, `conflict` | n/a |
| `6da75ce8f0473eceedde6cf5425642f6645cefcd` | 2026-08-27 | #158 | 2 | 2 | Neither `monero_check_tx::from_property_tree` nor `monero_decoded_address` exists in the fork (`git grep` empty). | aborted, `conflict` | n/a |
| `d31c128353c65caf15a89963e72faecb83d2f3ec` | 2026-07-23 | none in subject | 3 | 4 | `create_txs` in the fork has no `tx_amounts_by_dest`, `destinations` or `destinations_iter`. It has the Zephyr-specific `tx_dest_amounts` / `tx_change_amounts` iterators, a `tx_type` branch that builds incoming transfers, and "copy destinations if single tx" after the loop. The per-destination loop that upstream replaces does not exist. Skipped as a whole, per the work order. | aborted, `conflict` | n/a |

## Checks
- `git rev-list --count origin/security/v2.3.0..wip/sec.2` → `0`.
- `tools/check-hygiene.sh --base origin/security/v2.3.0 wip/sec.2` → `hygiene: checked 0 commit(s)`,
  `hygiene OK` (empty range; nothing to check).
- `+0000` and `G`: no commits to check.
- `tools/check-provenance.sh ~/github/zephyr-backports/zephyr-cpp 4a99272` with `wip/sec.2` checked out: the
  unchanged sec.1 range (4 picks `[ok]`, 3 own commits `(allowed files)`), `provenance OK`.
