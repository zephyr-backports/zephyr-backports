# WASM rebuilt on the published commits, and harness results, 2026-11-07

Builds of the webwallet project's `tools/wasm/build.sh` on the commits now published: **sec1** =
zephyr `e9cf10f796a6053280110dbe453dcd4e4344c8e8` (`security/v2.3.0` before sec.2 landed) and **sec2** =
zephyr `1c1982aa7237ef753f49b0b0cb4863f8c3461f03` (`security/v2.3.0` now). Both use zephyr-cpp
`56abaf9488dce0f6acb04673a9a737e390663b6a` and zephyr-javascript `9d022ded`. Then the smoke test
`tools/wasm/test/core-test.cjs` and cross-open, as in `../2026-11-05/harness-results.md`. The home directory of the
build machine is written as `~`.

## Builds
Copies `~/tmp/zeph-r3/webwallet-sec1` and `-sec2` of the webwallet project (`b9ded11`). Each `build.sh` differs from
`b9ded11` only in lines 28 and 29, the pins (`git diff`, verbatim):
```
-ZEPHYR_CPP_COMMIT=4a99272f       # ZephyrProtocol/zephyr-cpp
-ZEPHYR_COMMIT=67c5f53b           # ZephyrProtocol/zephyr, tag v2.3.0
+ZEPHYR_CPP_COMMIT=56abaf9488dce0f6acb04673a9a737e390663b6a       # ZephyrProtocol/zephyr-cpp
+ZEPHYR_COMMIT=e9cf10f796a6053280110dbe453dcd4e4344c8e8           # ZephyrProtocol/zephyr, tag v2.3.0
```
(sec2: `+ZEPHYR_COMMIT=1c1982aa7237ef753f49b0b0cb4863f8c3461f03`; the comments are left as they were).
`sha256sum`: sec1 `build.sh` `384ede236107e776df532faf9140ab289db7f2a498ca6c2ab14062792f7bb5cc`, sec2 `build.sh`
`e92d4ef75ccacc6943c8166178ed0552dba4a218c0f6667ec7ef1bb3bfd68a19`. Sources were cloned from local
mirrors of the forks (`git -C ~/tmp/zeph-r3/src/zephyr fetch` first). The build log confirms the pins:
```
  src @ 9d022ded2a8d188127173aa7cf79fdd5ee006353
  zephyr-cpp @ 56abaf9488dce0f6acb04673a9a737e390663b6a
  zephyr @ e9cf10f796a6053280110dbe453dcd4e4344c8e8
```
| build | `WASM_BUILD` | start | end | exit | manifest |
|---|---|---|---|---|---|
| sec1 | `~/tmp/zeph-r3/build-sec1-pub` | 2026-11-07T00:33:57Z | 00:38:02Z | 0 | `sec1-build-manifest.json` |
| sec2 | `~/tmp/zeph-r3/build-sec2-pub` | 00:38:02Z | 00:42:23Z | 0 | `sec2-build-manifest.json` |

The source trees differ from the round-7 builds (zephyr `54aa43b12` and `16018bb0b`, zephyr-cpp `ac3bb4de3`)
only outside the WASM inputs (`git diff --stat` in the mirrors). zephyr `54aa43b12..e9cf10f79`:
`.github/workflows/tests.yml`, `SECURITY-BACKPORTS.md`. `16018bb0b..1c1982aa7`: the same two files.
zephyr-cpp `ac3bb4de3..56abaf948`: `SECURITY-BACKPORTS.md`.

### Outputs against the round-7 manifests
| output | sec1 round 7 | sec1 now | sec2 round 7 | sec2 now |
|---|---|---|---|---|
| `monero_wallet_keys.wasm` | `d73e9dbc78bd0b48…` | `d73e9dbc78bd0b48…` equal | `fc630b04d52dc500…` | `fc630b04d52dc500…` equal |
| `monero_wallet_keys.js` | `69b02e1e9f12064b…` | equal | `69b02e1e9f12064b…` | equal |
| `monero_wallet_full.js` | `5cd17d48e821f606…` | equal | `5cd17d48e821f606…` | equal |
| `monero_wallet_full.symbols.txt` | `a3d8df1e546cd1a1…` | equal | `134c63075540c2c1…` | equal |
| `monero_wallet_full.wasm` | `e35b58433dfdfe90…` (5369820 B) | **`c9d4b136e4d70708…` (5369831 B), different** | `2ba10e6fc8bf1c06…` (5371458 B) | **`91e7a0868dce6cde…` (5371461 B), different** |

The patches, toolchain, dependencies and flags in the manifests are equal.
**Not as expected: `monero_wallet_full.wasm` differs, in both builds.** The cause is the one found on
2026-11-05 (`full.wasm` carries the absolute build path in the `__PRETTY_FUNCTION__` text of two lambdas, so
the bytes depend on `WASM_BUILD`). The round-7 builds ran in `build-sec1`/`build-sec2`, these in
`build-sec1-pub`/`build-sec2-pub`. `diff <(strings -n 8 build-sec1/out/monero_wallet_full.wasm | sort -u)
<(strings -n 8 build-sec1-pub/out/monero_wallet_full.wasm | sort -u)`, verbatim apart from the home directory:
```
9430,9431c9430,9431
< void tools::apply_permutation(std::vector<size_t>, const F &) [F = (lambda at ~/tmp/zeph-r3/build-sec1/src/external/zephyr-cpp/external/zephyr/src/common/apply_permutation.h:67:34)]
< void tools::apply_permutation(std::vector<size_t>, const F &) [F = (lambda at ~/tmp/zeph-r3/build-sec1/src/external/zephyr-cpp/external/zephyr/src/cryptonote_core/cryptonote_tx_utils.cpp:1622:41)]
---
> void tools::apply_permutation(std::vector<size_t>, const F &) [F = (lambda at ~/tmp/zeph-r3/build-sec1-pub/src/external/zephyr-cpp/external/zephyr/src/common/apply_permutation.h:67:34)]
> void tools::apply_permutation(std::vector<size_t>, const F &) [F = (lambda at ~/tmp/zeph-r3/build-sec1-pub/src/external/zephyr-cpp/external/zephyr/src/cryptonote_core/cryptonote_tx_utils.cpp:1622:41)]
```
The same for sec2 (`build-sec2` against `build-sec2-pub`, lines 9435 and 9436). No other string differs. The size
differences (11 and 3 bytes) are recorded as seen. A byte comparison at the same path was not
made (question R12-3).

## Harness
`core-test.cjs` copies the four files of `--dist` into `<harness>/dist` and loads them from there. "upstream" is therefore
upstream's prebuilt dist exported unchanged from zephyr-javascript `9d022ded`
(`git archive 9d022ded dist` into `~/tmp/zeph-r3/upstream-dist-9d022ded`: `monero_wallet_keys.wasm`
`a541c83c…`, `monero_wallet_full.wasm` `b4d7413e…`, the same hashes as in the repository). It is not
`<harness>/dist`, which holds whatever was tested last (question R12-2). Runner `~/tmp/zeph-r3/run-harness-r12.sh`; node
`http://remote-node.zephyrprotocol.com:17767` (the harness default), 40-block sync, Node v22.
A first batch at 00:49:50Z failed in every run before any test: `EACCES` when copying into
`<harness>/dist`, because the exported upstream files had been made read-only and the copy carries
the mode along. The write bit was restored and the hashes of the four upstream files checked against
`git show 9d022ded:dist/<file>` (equal). The batch below is the second run.

### RESULT lines, verbatim

`upstream` (2026-11-07T00:50:13Z … 2026-11-07T00:50:56Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/upstream-dist-9d022ded","distSha":{"monero_wallet_keys.wasm":"a541c83c2efdeb39","monero_wallet_full.wasm":"b4d7413ef80f3e59"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902059,"fullAddressMatches":true,"isSynced":true,"walletHeight":902059,"syncSeconds":33.03,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1669,"cacheBytes":29276111,"reopenAddressMatches":true,"reopenHeight":902059,"wrongPassword":"invalid password"}
```

`sec1` (2026-11-07T00:50:56Z … 2026-11-07T00:51:47Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/build-sec1-pub/out","distSha":{"monero_wallet_keys.wasm":"d73e9dbc78bd0b48","monero_wallet_full.wasm":"c9d4b136e4d70708"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902059,"fullAddressMatches":true,"isSynced":true,"walletHeight":902060,"syncSeconds":40.26,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1694,"cacheBytes":29276143,"reopenAddressMatches":true,"reopenHeight":902060,"wrongPassword":"invalid password"}
```

`sec2` (2026-11-07T00:51:47Z … 2026-11-07T00:52:19Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/build-sec2-pub/out","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"91e7a0868dce6cde"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902060,"fullAddressMatches":true,"isSynced":true,"walletHeight":902060,"syncSeconds":21.02,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1664,"cacheBytes":29276143,"reopenAddressMatches":true,"reopenHeight":902060,"wrongPassword":"invalid password"}
```

`sec1-opens-upstream` (2026-11-07T00:52:19Z … 2026-11-07T00:52:33Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/build-sec1-pub/out","distSha":{"monero_wallet_keys.wasm":"d73e9dbc78bd0b48","monero_wallet_full.wasm":"c9d4b136e4d70708"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902060,"openedFrom":"~/tmp/zeph-r3/upstream-dist-9d022ded","fullAddressMatches":true,"isSynced":true,"walletHeight":902060,"syncSeconds":4.38,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1654,"cacheBytes":29276143,"reopenAddressMatches":true,"reopenHeight":902060,"wrongPassword":"invalid password"}
```

`upstream-opens-sec1` (2026-11-07T00:52:33Z … 2026-11-07T00:52:51Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/upstream-dist-9d022ded","distSha":{"monero_wallet_keys.wasm":"a541c83c2efdeb39","monero_wallet_full.wasm":"b4d7413ef80f3e59"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902060,"openedFrom":"~/tmp/zeph-r3/build-sec1-pub/out","fullAddressMatches":true,"isSynced":true,"walletHeight":902060,"syncSeconds":7.37,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1684,"cacheBytes":29276143,"reopenAddressMatches":true,"reopenHeight":902060,"wrongPassword":"invalid password"}
```

`sec2-opens-upstream` (2026-11-07T00:52:51Z … 2026-11-07T00:53:09Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/build-sec2-pub/out","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"91e7a0868dce6cde"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902060,"openedFrom":"~/tmp/zeph-r3/upstream-dist-9d022ded","fullAddressMatches":true,"isSynced":true,"walletHeight":902060,"syncSeconds":5.38,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1683,"cacheBytes":29276143,"reopenAddressMatches":true,"reopenHeight":902060,"wrongPassword":"invalid password"}
```

`upstream-opens-sec2` (2026-11-07T00:53:09Z … 2026-11-07T00:53:29Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/upstream-dist-9d022ded","distSha":{"monero_wallet_keys.wasm":"a541c83c2efdeb39","monero_wallet_full.wasm":"b4d7413ef80f3e59"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902060,"openedFrom":"~/tmp/zeph-r3/build-sec2-pub/out","fullAddressMatches":true,"isSynced":true,"walletHeight":902060,"syncSeconds":5.77,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1684,"cacheBytes":29276143,"reopenAddressMatches":true,"reopenHeight":902060,"wrongPassword":"invalid password"}
```

### Summary
| run | WASM loaded (`distSha` keys / full) | same keys from the seed as upstream | sync reached the tip (wallet/daemon) | cross-open ok |
|---|---|---|---|---|
| `upstream` | upstream `a541c83c…` / `b4d7413e…` | yes | yes (902059/902059) | — (saves data) |
| `sec1` | sec1 `d73e9dbc…` / `c9d4b136…` | yes | yes (902060/902059) | — (saves data) |
| `sec2` | sec2 `fc630b04…` / `91e7a086…` | yes | yes (902060/902060) | — (saves data) |
| `sec1-opens-upstream` | sec1 | yes | yes (902060/902060) | yes (data saved by upstream's WASM) |
| `upstream-opens-sec1` | upstream `a541c83c…` / `b4d7413e…` | yes | yes (902060/902060) | yes (data saved by sec1) |
| `sec2-opens-upstream` | sec2 | yes | yes (902060/902060) | yes (data saved by upstream's WASM) |
| `upstream-opens-sec2` | upstream `a541c83c…` / `b4d7413e…` | yes | yes (902060/902060) | yes (data saved by sec2) |

Fields identical in all seven runs: `address`, `viewKey`, `spendPub`, `subaddr01`, `seedRoundtrip`,
`validGood`, `validBad`, `fullAddressMatches`, `isSynced`, `reserveInfoKeys`, `hfVersion`, `balance`,
`reopenAddressMatches`, `wrongPassword`. Fields that differ per run: heights, `syncSeconds`, `dist`/`distSha`, `openedFrom` (by
design), `cacheBytes`, `keysBytes`:

| run | `keysBytes` | `cacheBytes` |
|---|---|---|
| `upstream` | 1669 | 29276111 |
| `sec1` | 1694 | 29276143 |
| `sec2` | 1664 | 29276143 |
| `sec1-opens-upstream` | 1654 | 29276143 |
| `upstream-opens-sec1` | 1684 | 29276143 |
| `sec2-opens-upstream` | 1683 | 29276143 |
| `upstream-opens-sec2` | 1684 | 29276143 |

In both directions, upstream's own WASM opens wallet data saved by each fork build, and each fork build opens
data saved by upstream's WASM. (In `../2026-11-05/harness-results.md` the rows `upstream-opens-sec1` and
`upstream-opens-sec2` loaded a fork build instead of upstream's, as their `distSha` shows; see R12-2.)

## Rebuild at the round-7 paths (2026-11-07T01:34Z)
To separate the build-path dependence from the source, the round-7 build directories were moved aside
(`mv build-sec1 build-sec1-r7; mv build-sec2 build-sec2-r7` in `~/tmp/zeph-r3`, both kept) and the published pins
were built again into the round-7 paths. The same copies `webwallet-sec1`/`-sec2` were used (`build.sh` sha256 `384ede23…`/`e92d4ef7…`),
with `WASM_BUILD=~/tmp/zeph-r3/build-sec1` and `build-sec2`. Runner `~/tmp/zeph-r3/run-builds-r13.sh`, logs
`build-sec{1,2}-r7path.log`. Manifests: `sec1-build-manifest-r7path.json`, `sec2-build-manifest-r7path.json`.

| build | pins (from the log) | start | end | exit |
|---|---|---|---|---|
| sec1 | zephyr `e9cf10f796a6053280110dbe453dcd4e4344c8e8`, zephyr-cpp `56abaf9488dce0f6acb04673a9a737e390663b6a`, zephyr-javascript `9d022ded2a8d188127173aa7cf79fdd5ee006353` | 01:34:38Z | 01:38:58Z | 0 |
| sec2 | zephyr `1c1982aa7237ef753f49b0b0cb4863f8c3461f03`, zephyr-cpp `56abaf948…`, zephyr-javascript `9d022ded…` | 01:38:58Z | 01:43:19Z | 0 |

Against the round-7 manifests (zephyr `54aa43b12`/`16018bb0b`, zephyr-cpp `ac3bb4de3`):

| output | sec1 round 7 | sec1 now | sec2 round 7 | sec2 now |
|---|---|---|---|---|
| `monero_wallet_keys.wasm` | `d73e9dbc78bd0b48…` 1168469 B | equal | `fc630b04d52dc500…` 1168469 B | equal |
| `monero_wallet_keys.js` | `69b02e1e9f12064b…` 113330 B | equal | `69b02e1e9f12064b…` 113330 B | equal |
| `monero_wallet_full.wasm` | `e35b58433dfdfe90…` 5369820 B | **equal** | `2ba10e6fc8bf1c06…` 5371458 B | **equal** |
| `monero_wallet_full.js` | `5cd17d48e821f606…` 303000 B | equal | `5cd17d48e821f606…` 303000 B | equal |
| `monero_wallet_full.symbols.txt` | `a3d8df1e546cd1a1…` 3666784 B | equal | `134c63075540c2c1…` 3666784 B | equal |

`cmp build-sec1-r7/out/monero_wallet_full.wasm build-sec1/out/monero_wallet_full.wasm` and the same for sec2: no output,
exit 0. **All five outputs of both builds are byte-identical to the round-7 builds.** So the published commits
produce byte for byte the WASM that was built and tested on 2026-11-05. The `full.wasm` difference of the `-pub`
builds above is the build path alone, as the strings diff showed.

## Release set 2026-11-07 (round 17)
One build of the release set at the canonical path `/tmp/zeph-wasm/build` (no user name in the path): zephyr
`v2.3.0-sec.2` `8c6a120256b4bd887d6e7167d929d76e3507e0e5`, zephyr-cpp `v2.3.0-sec.1`
`3a2ee602ee28e6b7941b617ad4706349ad992641`, zephyr-javascript `9d022ded2a8d188127173aa7cf79fdd5ee006353`. Both
tags verified (`git tag -v`: good signature, release key, tagger `zephyr-backports`). Copy
`~/tmp/zeph-r5/webwallet-set` of the webwallet project (`b9ded11`, `tar` copy without `.wasm-work`, `diff -rq`
identical); `build.sh` differs only in lines 28 and 29 (the comments left as they were):
```
-ZEPHYR_CPP_COMMIT=4a99272f       # ZephyrProtocol/zephyr-cpp
-ZEPHYR_COMMIT=67c5f53b           # ZephyrProtocol/zephyr, tag v2.3.0
+ZEPHYR_CPP_COMMIT=3a2ee602ee28e6b7941b617ad4706349ad992641       # ZephyrProtocol/zephyr-cpp
+ZEPHYR_COMMIT=8c6a120256b4bd887d6e7167d929d76e3507e0e5           # ZephyrProtocol/zephyr, tag v2.3.0
```
`build.sh` sha256 `05ff98b3835515d82cac03b8f86ae740586c8f60a36badd15deda6041c8eefc5` (= `script_sha256` in the manifest).
`ZEPH_SRC` = symlinks to the fork clones (tags fetched first), `WASM_CACHE` = the webwallet project's `.wasm-work`,
`OMP_THREAD_LIMIT=6`. Build 2026-11-07T14:14:15Z to 14:18:54Z, exit 0; the log confirms the pins
(`src @ 9d022ded2a8d…`, `zephyr-cpp @ 3a2ee602ee28…`, `zephyr @ 8c6a120256b4…`). Guards: 1 OK; 2 OK (full 10, keys 3
symbols); 3 OK (595 paths under `/zeph`); 4 OK. Manifest: `set-2026-11-07-build-manifest.json`.

Path checks (`/usr/bin/grep -ao … | wc -l`, the shell's `grep` prints no count for binary files):
| output | `/tmp/zeph-wasm` | `/home/` |
|---|---|---|
| `monero_wallet_full.wasm` | 2 (the two `apply_permutation` lambda strings) | 0 |
| `monero_wallet_full.js` | 0 | 2, both `/home/web_user` |
| `monero_wallet_keys.wasm` | 0 | 0 |
| `monero_wallet_keys.js` | 0 | 2, both `/home/web_user` |
| `monero_wallet_full.symbols.txt` | 0 | 0 |
| `build-manifest.json` | 0 | 0 |
`/home/web_user` is the home directory of emscripten's virtual file system (`FS.mkdir("/home/web_user")`, `"HOME":"/home/web_user"`
in the glue), present in upstream's prebuilt glue as well; it is not a host path. No host path in any output.

### Outputs against `sec2-build-manifest-r7path.json`
| output | r7 path (`~/tmp/zeph-r3/build-sec2`) | release set (`/tmp/zeph-wasm/build`) | |
|---|---|---|---|
| `monero_wallet_keys.wasm` | `fc630b04d52dc500…` 1168469 B | `fc630b04d52dc500…` 1168469 B | equal |
| `monero_wallet_keys.js` | `69b02e1e9f12064b…` 113330 B | `69b02e1e9f12064b…` | equal |
| `monero_wallet_full.js` | `5cd17d48e821f606…` 303000 B | `5cd17d48e821f606…` | equal |
| `monero_wallet_full.symbols.txt` | `134c63075540c2c1…` | `134c63075540c2c1…` | equal |
| `monero_wallet_full.wasm` | `2ba10e6fc8bf1c06…` 5371458 B | `c984b999dd76550ab8135a0d7ddfd34b5fc7774200f8887aaa5f4984a7c7b1e4` 5371431 B | different |

Patches, toolchain, dependencies and flags in the two manifests are equal; the `modified_files` of all three sources
are equal; the zephyr and zephyr-cpp `diff_sha256` are equal. The zephyr-javascript `diff_sha256` differs because that
`git diff` includes `dist/monero_wallet_full.wasm`, whose blob differs. `full.wasm`:
`diff <(strings -n 8 <r7>/monero_wallet_full.wasm | sort -u) <(strings -n 8 <set>/monero_wallet_full.wasm | sort -u)`,
home directory written as `~`:
```
9435,9436c9435,9436
< void tools::apply_permutation(std::vector<size_t>, const F &) [F = (lambda at ~/tmp/zeph-r3/build-sec2/src/external/zephyr-cpp/external/zephyr/src/common/apply_permutation.h:67:34)]
< void tools::apply_permutation(std::vector<size_t>, const F &) [F = (lambda at ~/tmp/zeph-r3/build-sec2/src/external/zephyr-cpp/external/zephyr/src/cryptonote_core/cryptonote_tx_utils.cpp:1622:41)]
---
> void tools::apply_permutation(std::vector<size_t>, const F &) [F = (lambda at /tmp/zeph-wasm/build/src/external/zephyr-cpp/external/zephyr/src/common/apply_permutation.h:67:34)]
> void tools::apply_permutation(std::vector<size_t>, const F &) [F = (lambda at /tmp/zeph-wasm/build/src/external/zephyr-cpp/external/zephyr/src/cryptonote_core/cryptonote_tx_utils.cpp:1622:41)]
```
No other string differs. At byte level it is not a plain substitution: replacing the 33-byte path by the 20-byte one in
the r7 binary gives 5371432 bytes, one more than this build. Per wasm section: type, import, function, table, memory,
export and elem are identical; the data section is 27 bytes shorter (818180 → 818153), and the code section (same
size) and the global section differ. Assessment, not analysed further: the shorter strings shift the memory addresses
of the data placed after them, which changes address constants in the code and globals and one length byte in
the data section. The release-set build is what the fork's `dist/` gets.

### Harness
Runner `~/tmp/zeph-r5/run-harness.sh` (as `run-harness-r12.sh`, `core-test.cjs` of the copy, harness
`~/tmp/zeph-r3/cache/harness`); "upstream" is `~/tmp/zeph-r3/upstream-dist-9d022ded`, its seven files checked equal
to `git show 9d022ded:dist/<file>` before the run. Node v22.23.4, node `http://remote-node.zephyrprotocol.com:17767`,
40-block sync.

### RESULT lines, verbatim

`upstream` (2026-11-07T14:20:12Z … 2026-11-07T14:20:46Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/upstream-dist-9d022ded","distSha":{"monero_wallet_keys.wasm":"a541c83c2efdeb39","monero_wallet_full.wasm":"b4d7413ef80f3e59"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902467,"fullAddressMatches":true,"isSynced":true,"walletHeight":902467,"syncSeconds":23.98,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1709,"cacheBytes":29289199,"reopenAddressMatches":true,"reopenHeight":902467,"wrongPassword":"invalid password"}
```

`set` (2026-11-07T14:20:46Z … 2026-11-07T14:21:23Z exit=0):
```
RESULT {"dist":"/tmp/zeph-wasm/build/out","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"c984b999dd76550a"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902467,"fullAddressMatches":true,"isSynced":true,"walletHeight":902467,"syncSeconds":25.11,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1658,"cacheBytes":29289199,"reopenAddressMatches":true,"reopenHeight":902467,"wrongPassword":"invalid password"}
```

`set-opens-upstream` (2026-11-07T14:21:23Z … 2026-11-07T14:21:40Z exit=0):
```
RESULT {"dist":"/tmp/zeph-wasm/build/out","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"c984b999dd76550a"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902467,"openedFrom":"~/tmp/zeph-r3/upstream-dist-9d022ded","fullAddressMatches":true,"isSynced":true,"walletHeight":902467,"syncSeconds":3.5,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1654,"cacheBytes":29289199,"reopenAddressMatches":true,"reopenHeight":902467,"wrongPassword":"invalid password"}
```

`upstream-opens-set` (2026-11-07T14:21:40Z … 2026-11-07T14:21:55Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/upstream-dist-9d022ded","distSha":{"monero_wallet_keys.wasm":"a541c83c2efdeb39","monero_wallet_full.wasm":"b4d7413ef80f3e59"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902467,"openedFrom":"/tmp/zeph-wasm/build/out","fullAddressMatches":true,"isSynced":true,"walletHeight":902467,"syncSeconds":4.89,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1657,"cacheBytes":29289199,"reopenAddressMatches":true,"reopenHeight":902467,"wrongPassword":"invalid password"}
```

### Summary
| run | WASM loaded (`distSha` keys / full) | same keys from the seed as upstream | sync reached the tip (wallet/daemon) | cross-open ok |
|---|---|---|---|---|
| `upstream` | upstream `a541c83c…` / `b4d7413e…` | yes | yes (902467/902467) | — (saves data) |
| `set` | set `fc630b04…` / `c984b999…` | yes | yes (902467/902467) | — (saves data) |
| `set-opens-upstream` | set | yes | yes (902467/902467) | yes (data saved by upstream's WASM) |
| `upstream-opens-set` | upstream `a541c83c…` / `b4d7413e…` | yes | yes (902467/902467) | yes (data saved by the set build) |

Fields identical in all four runs: `address`, `viewKey`, `spendPub`, `subaddr01`, `seedRoundtrip`, `validGood`,
`validBad`, `fullAddressMatches`, `isSynced`, `reserveInfoKeys`, `hfVersion`, `balance`, `cacheBytes` (29289199),
`reopenAddressMatches`, `wrongPassword`. Per run: heights, `syncSeconds`, `dist`/`distSha`, `openedFrom` (by design),
`keysBytes` (upstream 1709, set 1658, set-opens-upstream 1654, upstream-opens-set 1657). Both directions open.

## Committed `dist/` of the zephyr-javascript branch tip (round 18)
The zephyr-javascript fork's `security/v2.3.0` at `7b17a1428` (commits `bbd4fad48` own files, `b8bf3c99f` artefact
rebuild, `7b17a1428` advisory SB-035; no dependency pin, see `../../deps/2026-11-07/zephyr-javascript-pins.md`). The
seven `dist/` files and `SHA256SUMS` exported from the commit (`git show 7b17a1428:dist/<file>`) into
`~/tmp/zeph-r5/tip-dist`; `sha256sum -c SHA256SUMS`: all seven OK. `core-test.cjs` loads only the four WASM/glue
files (`monero_wallet_{keys,full}.{js,wasm}`); the worker bundle `monero_web_worker.js` is not loaded by the harness.
The worker bundle built in round 18 from a fresh `npm ci` of the unpinned base lockfile is byte-identical to the one of
round 17 (same seven hashes). Runner `~/tmp/zeph-r5/run-harness-r18.sh` (as round 17, "upstream" =
`~/tmp/zeph-r3/upstream-dist-9d022ded`, a fresh upstream save for the cross-open).

### RESULT lines, verbatim

`upstream` (2026-11-07T14:44:04Z … 2026-11-07T14:44:51Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/upstream-dist-9d022ded","distSha":{"monero_wallet_keys.wasm":"a541c83c2efdeb39","monero_wallet_full.wasm":"b4d7413ef80f3e59"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902478,"fullAddressMatches":true,"isSynced":true,"walletHeight":902478,"syncSeconds":32.69,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1673,"cacheBytes":29289519,"reopenAddressMatches":true,"reopenHeight":902478,"wrongPassword":"invalid password"}
```

`tip` (2026-11-07T14:44:51Z … 2026-11-07T14:45:29Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r5/tip-dist","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"c984b999dd76550a"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902478,"fullAddressMatches":true,"isSynced":true,"walletHeight":902478,"syncSeconds":25.41,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1681,"cacheBytes":29289519,"reopenAddressMatches":true,"reopenHeight":902478,"wrongPassword":"invalid password"}
```

`tip-opens-upstream` (2026-11-07T14:45:29Z … 2026-11-07T14:45:47Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r5/tip-dist","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"c984b999dd76550a"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902478,"openedFrom":"~/tmp/zeph-r3/upstream-dist-9d022ded","fullAddressMatches":true,"isSynced":true,"walletHeight":902478,"syncSeconds":7.23,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1650,"cacheBytes":29289519,"reopenAddressMatches":true,"reopenHeight":902478,"wrongPassword":"invalid password"}
```

`upstream-opens-tip` (2026-11-07T14:45:47Z … 2026-11-07T14:46:14Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/upstream-dist-9d022ded","distSha":{"monero_wallet_keys.wasm":"a541c83c2efdeb39","monero_wallet_full.wasm":"b4d7413ef80f3e59"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":902478,"openedFrom":"~/tmp/zeph-r5/tip-dist","fullAddressMatches":true,"isSynced":true,"walletHeight":902478,"syncSeconds":5.65,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1675,"cacheBytes":29289519,"reopenAddressMatches":true,"reopenHeight":902478,"wrongPassword":"invalid password"}
```

### Summary
| run | WASM loaded (`distSha` keys / full) | sync (wallet/daemon) | cross-open ok |
|---|---|---|---|
| `upstream` | upstream `a541c83c…` / `b4d7413e…` | 902478/902478 | — (saves data) |
| `tip` | tip `fc630b04…` / `c984b999…` | 902478/902478 | — (saves data) |
| `tip-opens-upstream` | tip | 902478/902478 | yes (data saved by upstream's WASM) |
| `upstream-opens-tip` | upstream | 902478/902478 | yes (data saved by the tip's WASM) |

All four exit 0. The 14 non-volatile fields (`address`, `viewKey`, `spendPub`, `subaddr01`, `seedRoundtrip`, `validGood`,
`validBad`, `fullAddressMatches`, `isSynced`, `reserveInfoKeys`, `hfVersion`, `balance`, `reopenAddressMatches`,
`wrongPassword`) are identical in all four; `cacheBytes` 29289519 in all four; `keysBytes` 1673 / 1681 / 1650 / 1675.
