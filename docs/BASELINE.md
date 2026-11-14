# Baseline: how Zephyr relates to Monero

*Measured 2026-11-04 (originally in the webwallet's private work repo, `docs/ANALYSE.md` §3.1).*

- `ZephyrProtocol/zephyr` v2.3.0 (`67c5f53b878fef41fb5e74c4382d5b7a2f37fd8a`, 2025-06-11) carries Monero master up to the merge of pull request #9243 (2024-03-12, between v0.18.3.2 and v0.18.3.3). Corrected 2026-11-14: `15a4ff66f751cdf8037873cc63f24e486de22b67` is **Zephyr's replayed copy** of that merge (committer ZephyrProtocol, 2024-04-08, one parent), not a Monero commit; Monero's own is `c8214782f`. The last commit the two histories share is `a2e8d1d42` (Monero master, 2023-04-26); on top of it Zephyr has 245 commits, 139 of them replayed Monero merges. At `15a4ff66f` the tree differs from Monero's `c8214782f` only in files Zephyr's own commits touch (and two files under `utils/gpg_keys`), so "Monero master of 2024-03-12" holds for the content.
- Tree diff from Monero's `c8214782f` to v2.3.0, `src` and `contrib/epee`: 10,386 added and 4,050 removed lines in 112 files, on about 237,000 lines (≈ 4 %, rename noise included). By directory: `cryptonote_core` +3,290, `blockchain_db` +1,601, `wallet` +1,592, `simplewallet` +977, `oracle` +719 (new), `ringct` +710, `rpc` +516, `cryptonote_basic` +316, `serialization` +310. `crypto/*` (one line), epee and mnemonics are unchanged. The earlier figure here (≈ 2,600 added, ≈ 1 %) was the diff from `15a4ff66f` and so covered only Zephyr's last 20 commits.
- The asset code is not written from scratch: Zephyr's first own commit (`1f3b2f496`, 2023-05-26) takes the multi-asset mechanics from Haven Protocol (`haven-main` v3.1.9e; 44 % of its non-Monero lines verbatim, measured 2026-11-14) and puts the Djed rules on top. Haven is closed since 2024-12; no fixes will come from there.
- Consequence: Monero commits on `release-v0.18` usually apply directly (12 of 31 prioritised picks clean; the rest 1–2 context hunks, except in `cryptonote_tx_utils.cpp`).
- Monero since that base: v0.18.3.3 … v0.18.5.4 (2026-10-14). Zephyr's own release builds pin boost 1.64, OpenSSL 3.0.13, unbound 1.19.1 (`contrib/depends`); the developer built the WASM with boost 1.76.

```bash
cd ~/github/zephyr-backports/zephyr
git merge-base monero/master v2.3.0                      # a2e8d1d42, the last shared commit
git log -1 --format='%H %cn %cd' 15a4ff66f             # Zephyr's copy of Monero's merge of #9243
git diff --stat c8214782f 15a4ff66f | tail -1            # only files Zephyr changed
git diff --numstat c8214782f v2.3.0 -- src contrib/epee | awk '{split($3,p,"/"); d=p[1]"/"p[2]; a[d]+=$1; r[d]+=$2} END {for (d in a) print d, a[d], r[d]}' | sort -k2 -nr
```

Reproducing the inventory: `tools/inventory.sh 2024-03-12` (fetches all `release-v0.18` commits since that date per directory, strikes out what is already in Zephyr's history, and marks which files are part of the WASM build).
