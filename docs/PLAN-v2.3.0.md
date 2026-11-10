# Plan for base v2.3.0 (`67c5f53b`)

*2026-11-04; closed 2026-11-10: `v2.3.0-sec.2` is the last zephyr tag on this base (see "Closed at `-sec.2`" below). Measured with a dry `cherry-pick -x` run of 31 prioritised Monero commits on v2.3.0 (`tools/backport.sh --dry-run`). List with status: `backports/v2.3.0.txt`.*

## `v2.3.0-sec.1`: the picks that apply cleanly and fall under POLICY §2 (9 + the DNSSEC key)

| Monero commit | Class | What | For |
|---|---|---|---|
| `74c313420` | memory | `byte_slice` memcpy | both |
| `1d3d30c50` | memory/DoS | Cryptonight v1: catch invalid input | both |
| `7a7c42ffb` | memory | serialization: EOF at varint boundary | both |
| `dedae5272` | memory | epee JSON: off-by-one over-read in unicode escape (every RPC response) | both |
| `0b7967907` | DoS/privacy | gamma picker against empty output windows (Monero master counterpart of `7507aed69`, decided 2026-11-05: it also fixes the master-only unit test Zephyr carries) | wallet |
| `72d91039e` | memory | validate cached transfer indices | wallet |
| `987a2a77d` | memory | bounds check on additional derivations in `is_out_to_acc` (on-chain `tx_extra`) | wallet |
| `ef7bdda92` | funds/privacy | validate block hash when repairing the hashchain | wallet |
| `d9236332a` | DoS | data races in refresh error handlers | wallet (native) |
| `e62963ceb` | DoS/availability | DNSSEC root trust anchor KSK-2024 (root signing switched 2026-10-11; v2.3.0 validates nothing since) | both |

Dropped under §2 (correctness): `8703b8a4c` fee consistency, `34c7d31ef` shortchain base block, `357b446a1` scan status.

## `-sec.2`: wallet2 fixes with 1–2 context hunks (8), 5 clean daemon fixes, and the dependency pins (12), each verified separately

| Monero commit | Class | Hunks | What |
|---|---|---|---|
| `b99d15f08` | privacy/DoS | 1 | reject non-monotonic output distributions |
| `ac37e75df` | DoS | 1 | infinite loop in `estimate_tx_size_and_weight` |
| `bbd635075` | DoS | 1 (`wallet2.h`) | `max_blocks` in fast_refresh |
| `ef7a86c99` | DoS | 1 | coinbase refresh against empty `vout` |
| `a09eb5cf4` | memory | 2 | use-after-free in parsed-block processing |
| `c86fd739d` | funds | 1 | filter unchecked RPC error statuses |
| `144b3f9e6` | funds | 1 | untrusted daemon status in sweep_unmixable |
| `4b00f47d4` | secrets | 1 | clear additional tx keys |

Not (correctness): `c147e2dfe` key images unspent, `9239d3669` pool spends.

**Dependency pins** (POLICY §2 last row; `contrib/depends` builds the release binaries; all clean, see `ANALYSIS-REPOS.md` §1.4): unbound 1.19.1 → 1.26.1 in three commits (CVE-2026-33278, CVE-2026-81642 among ~40 advisories), OpenSSL 3.0.13 → 3.0.22 in three, RandomX 1.2.1 → v1.2.3 in two, the autoconf cross-compile fix (hidapi 0.15.0 dropped at review 2026-11-05: no advisory), plus `52b33f4fb` (console output sanitising) and `342c3a0fd` (Windows UB). Boost and libusb bumps conflict and wait. Evidence: the `depends` CI job of the fork; the WASM is unaffected (own OpenSSL and boost, no resolver).

## Closed at `-sec.2` (2026-11-10)
No `-sec.3` and no `-sec.4` are cut on v2.3.0. Measured 2026-11-10 on `security/v2.3.0` `9abdf5f98`:
- **Serialisation hardening** (`214328387`, `d869dc098`, `b66e2227c`, `71e3be0e4`, planned as `-sec.3`): all four conflict, 15 hunks. `d869dc098` is semantic: its new `deserialize_vin` requires `txin_to_key`, a type Zephyr does not have (`txin_zephyr_key`), and it adds count limits on `vin`, `vout` and key offsets, which is stricter parsing under POLICY §4.4. `71e3be0e4` is semantic: the function it changes (`make_pool_supplement_from_block_entry`) does not exist in Zephyr. The other two (1 and 6 hunks) were not classified; without `d869dc098` the set has no core, so all four are dropped. Only ZephyrProtocol can write this hardening for its own types.
- **Restricted-ZMQ trio** (`7f2cfe929`, `878c78176`, `dfb85dde0`, planned as `-sec.4` on 2026-11-05): the three apply cleanly, but the first adds a command-line flag and two source files, a feature under POLICY §1; it is opt-in, no public ZMQ-RPC node is known, and `878c78176` changes tx-pool code that also runs without the flag. Decision reversed: skipped.
- **The former "later" group** (`1d45021cd`, the p2p commits, the boost and libusb bumps): needs porting or is build-only; not for these forks.

From here the work on this base is maintenance: `tools/inventory.sh` against Monero `release-v0.18` for new fixes and for the next `contrib/depends` bump of unbound and OpenSSL, and a new branch when upstream releases (POLICY §5).

## Out of scope
- tx-sanity chain `44412d357` → `4eae97404` → `b09e9bfe5` → `0125cf269`: needs an asset-aware adaptation in `cryptonote_tx_utils.cpp` (own code). The webwallet compensates in the JS layer.
- `65568d3a8` view-key logging: entangled with boost-1.85 build changes; measured no leak at the default log level.
- `71e3be0e4` (protocol handler): semantic, see "Closed at `-sec.2`".

## Daemon pass (measured 2026-11-05, details in `ANALYSIS-REPOS.md` §1)
The inventory struck out p2p, ZMQ and the RPC server as "browser-irrelevant"; under POLICY §3 they do count: the community runs the nodes both wallets connect to (the desktop wallet's local-node code is disabled, see ANALYSIS-REPOS.md §4). 14 candidates, cumulative dry run on v2.3.0: 7 clean, 7 conflict.
- **Into `-sec.2`** (clean, small, clearly §2): `af88effd9`, `7de175802` (restricted-RPC privacy, 1 line each), `98b350f7a` (levin unaligned reads, memory), `4f6652f35`, `d1508916b` (ZMQ input caps, DoS).
- **Not picked (2026-11-10, see "Closed at `-sec.2`"):** the restricted-ZMQ trio `7f2cfe929`, `878c78176`, `dfb85dde0`; `71e3be0e4`; `1d45021cd` (touches files named in §4.1); `f277d328c`, `ee9e4a49b`, `f618ee113` (p2p/epee server, 3–6 hunks); `096abdaa2`.

## Order of work
1. Fork `zephyr` → `~/github/zephyr-backports/zephyr`, branch `security/v2.3.0`, remote `monero`.
2. `fork-files/zephyr/` into it: `README-SECURITY-SECTION.md` is **inserted** at the top of the existing `README.md` (not copied over it), `SECURITY-BACKPORTS.md` and `.github/workflows/provenance.yml` verbatim; one commit "security: policy, advisory log and provenance CI" with the trailer `Origin: zephyr-backports` (otherwise the provenance check fails).
3. `tools/backport.sh ~/github/zephyr-backports/zephyr backports/v2.3.0.txt --only sec.1` → 9 commits; fill in advisories SB-001…009; tag `v2.3.0-sec.1`.
4. Webwallet: `tools/wasm/build.sh` on the tag; guards; harness; cross-open; manifest with `upstream_base` + backports.
5. `-sec.2` per commit: pick, resolve conflict context-only, build, harness, advisory.
6. Closed at `-sec.2` on 2026-11-10: no `-sec.3`, no `-sec.4` (see above).
7. The other repos follow the release train in `ANALYSIS-REPOS.md` §6: zephyr-cpp picks, rebuilt WASM in zephyr-javascript, copied WASM and pins in zephyr-wallet (the last two need the POLICY §5 decision).
