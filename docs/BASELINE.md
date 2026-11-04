# Baseline: how Zephyr relates to Monero

*Measured 2026-11-04 (originally in the webwallet's private work repo, `docs/ANALYSE.md` §3.1).*

- `ZephyrProtocol/zephyr` v2.3.0 (`67c5f53b878fef41fb5e74c4382d5b7a2f37fd8a`, 2025-06-11) contains Monero's merge commit `15a4ff66f751cdf8037873cc63f24e486de22b67` (master, 2024-03-12, between v0.18.3.2 and v0.18.3.3) literally in its history.
- Tree diff from that Monero commit to v2.3.0: ≈ 2,600 added and ≈ 550 removed lines on ~240,000 (≈ 1 %), almost all in `cryptonote_core` (tx construction with assets/conversions), `ringct`, `oracle` (new), `wallet2` (+165/−46), `simplewallet`. `crypto/*`, epee, mnemonics and the keys serialisation are unchanged.
- Consequence: Monero commits on `release-v0.18` usually apply directly (12 of 31 prioritised picks clean; the rest 1–2 context hunks, except in `cryptonote_tx_utils.cpp`).
- Monero since that base: v0.18.3.3 … v0.18.5.4 (2026-10-14). Zephyr's own release builds pin boost 1.64, OpenSSL 3.0.13, unbound 1.19.1 (`contrib/depends`); the developer built the WASM with boost 1.76.

```bash
cd ~/github/zephyr-backports/zephyr
git merge-base --is-ancestor 15a4ff66f HEAD && echo "Monero base is in the history"
git diff --numstat 15a4ff66f v2.3.0 -- src contrib/epee | awk '{split($3,p,"/"); d=p[1]"/"p[2]; a[d]+=$1; r[d]+=$2} END {for (d in a) print d, a[d], r[d]}' | sort -k2 -nr
```

Reproducing the inventory: `tools/inventory.sh 2024-03-12` (fetches all `release-v0.18` commits since that date per directory, strikes out what is already in Zephyr's history, and marks which files are part of the WASM build).
