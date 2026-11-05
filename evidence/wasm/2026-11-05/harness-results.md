# Harness results, WASM builds of 2026-11-05

Smoke test `tools/wasm/test/core-test.cjs` of the webwallet project (upstream zephyr-javascript JS
layer at `9d022ded` in Node v22, keys from a fixed throwaway seed, 40-block sync from
`http://remote-node.zephyrprotocol.com:17767`, reserve info, balance, keys/cache serialisation,
reopen) against four builds: upstream's prebuilt dist at `9d022ded`, and the local builds `base`
(upstream v2.3.0 sources), `sec1` (zephyr `20d689be7` + zephyr-cpp `ac3bb4de3`) and `sec2` (zephyr
`7ba805e61` + zephyr-cpp `ac3bb4de3`); then cross-open of saved wallet data in both directions
between upstream and each fork build. Build manifests: `sec1-build-manifest.json`,
`sec2-build-manifest.json` in this directory.

The `~/tmp/zeph-r3/...` paths in the RESULT lines below are the local run's working
directories on the build machine, with its home directory written as `~` (`dist` = which build was loaded, `openedFrom` = which build saved
the data that was opened); they carry no meaning beyond identifying the run.

## RESULT lines, verbatim

`upstream` (2026-11-05T09:06:50Z … 2026-11-05T09:07:34Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/cache/harness/dist","distSha":{"monero_wallet_keys.wasm":"a541c83c2efdeb39","monero_wallet_full.wasm":"b4d7413ef80f3e59"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":900875,"fullAddressMatches":true,"isSynced":true,"walletHeight":900875,"syncSeconds":31.89,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1694,"cacheBytes":29238287,"reopenAddressMatches":true,"reopenHeight":900875,"wrongPassword":"invalid password"}
```
`base` (2026-11-05T09:07:34Z … 2026-11-05T09:08:12Z exit=0):
```
RESULT {"dist":"~/tmp/zeph-r3/build-base/out","distSha":{"monero_wallet_keys.wasm":"7283e5bd0dead72b","monero_wallet_full.wasm":"613cc65f82efe36d"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":900875,"fullAddressMatches":true,"isSynced":true,"walletHeight":900876,"syncSeconds":27.57,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1669,"cacheBytes":29238287,"reopenAddressMatches":true,"reopenHeight":900876,"wrongPassword":"invalid password"}
```
`sec1` (2026-11-05T12:41:58Z … 2026-11-05T12:42:40Z exit=0; **re-run on the rewritten branches**, zephyr `54aa43b12`):
```
RESULT {"dist":"~/tmp/zeph-r3/build-sec1/out","distSha":{"monero_wallet_keys.wasm":"d73e9dbc78bd0b48","monero_wallet_full.wasm":"e35b58433dfdfe90"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":900974,"fullAddressMatches":true,"isSynced":true,"walletHeight":900974,"syncSeconds":32.39,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1678,"cacheBytes":29241391,"reopenAddressMatches":true,"reopenHeight":900974,"wrongPassword":"invalid password"}
```
`sec2` (2026-11-05T12:42:40Z … 2026-11-05T12:43:18Z exit=0; **re-run on the rewritten branches**, zephyr `16018bb0b`):
```
RESULT {"dist":"~/tmp/zeph-r3/build-sec2/out","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"2ba10e6fc8bf1c06"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":900974,"fullAddressMatches":true,"isSynced":true,"walletHeight":900974,"syncSeconds":27.76,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1669,"cacheBytes":29241391,"reopenAddressMatches":true,"reopenHeight":900974,"wrongPassword":"invalid password"}
```
`sec1-opens-upstream` (2026-11-05T12:43:18Z … 2026-11-05T12:43:33Z exit=0; **re-run on the rewritten branches**, zephyr `54aa43b12`):
```
RESULT {"dist":"~/tmp/zeph-r3/build-sec1/out","distSha":{"monero_wallet_keys.wasm":"d73e9dbc78bd0b48","monero_wallet_full.wasm":"e35b58433dfdfe90"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":900974,"openedFrom":"~/tmp/zeph-r3/cache/harness/dist","fullAddressMatches":true,"isSynced":true,"walletHeight":900974,"syncSeconds":5.38,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1669,"cacheBytes":29241455,"reopenAddressMatches":true,"reopenHeight":900974,"wrongPassword":"invalid password"}
```
`upstream-opens-sec1` (2026-11-05T12:43:33Z … 2026-11-05T12:43:47Z exit=0; **re-run on the rewritten branches**, zephyr `54aa43b12`):
```
RESULT {"dist":"~/tmp/zeph-r3/cache/harness/dist","distSha":{"monero_wallet_keys.wasm":"d73e9dbc78bd0b48","monero_wallet_full.wasm":"e35b58433dfdfe90"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":900974,"openedFrom":"~/tmp/zeph-r3/build-sec1/out","fullAddressMatches":true,"isSynced":true,"walletHeight":900974,"syncSeconds":4.34,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1684,"cacheBytes":29241391,"reopenAddressMatches":true,"reopenHeight":900974,"wrongPassword":"invalid password"}
```
`sec2-opens-upstream` (2026-11-05T12:43:47Z … 2026-11-05T12:44:09Z exit=0; **re-run on the rewritten branches**, zephyr `16018bb0b`):
```
RESULT {"dist":"~/tmp/zeph-r3/build-sec2/out","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"2ba10e6fc8bf1c06"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":900974,"openedFrom":"~/tmp/zeph-r3/cache/harness/dist","fullAddressMatches":true,"isSynced":true,"walletHeight":900974,"syncSeconds":7.54,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1650,"cacheBytes":29241455,"reopenAddressMatches":true,"reopenHeight":900974,"wrongPassword":"invalid password"}
```
`upstream-opens-sec2` (2026-11-05T12:44:09Z … 2026-11-05T12:44:26Z exit=0; **re-run on the rewritten branches**, zephyr `16018bb0b`):
```
RESULT {"dist":"~/tmp/zeph-r3/cache/harness/dist","distSha":{"monero_wallet_keys.wasm":"fc630b04d52dc500","monero_wallet_full.wasm":"2ba10e6fc8bf1c06"},"address":"ZEPHYR2wfJQJuhE9sRQmaRPHPHiYmNpUAcuZubuuHxB3PncwWegLGQTTN5Ziipp1Z9Qt9Ydp8trYGSvWsNy7NrtVA9gUMUGdySS4T","viewKey":"06d996b1d949efe9fe855747e043864a53e22c4d64f80b2578e3616c5ba21601","spendPub":"8641896b116768cbed249a8537e1ca15f2886bd6ab816efaec8dc2883b5ae76d","subaddr01":"ZEPHsBi67Ge57EhkV9xAkPKWs9bFgru2EaP8b4Kvx842jhZVaByJ8E4L3JUaNJmdrv9W9RPqEi2dT8CmFAtHPFyx2PMoj5mqLyB","seedRoundtrip":true,"validGood":true,"validBad":false,"daemonHeight":900974,"openedFrom":"~/tmp/zeph-r3/build-sec2/out","fullAddressMatches":true,"isSynced":true,"walletHeight":900974,"syncSeconds":7.16,"reserveInfoKeys":"assets,assets_ma,equity,equity_ma,hf_version,liabilities,num_reserves,num_stables,reserve_ratio,reserve_ratio_ma,zeph_reserve,zyield_circ,zyield_rsv","hfVersion":"11","balance":{"ZEPH":"0","ZEPHRSV":"0","ZEPHUSD":"0","ZPH":"0","ZRS":"0","ZSD":"0","ZYIELD":"0","ZYS":"0"},"keysBytes":1649,"cacheBytes":29241391,"reopenAddressMatches":true,"reopenHeight":900974,"wrongPassword":"invalid password"}
```

**Re-run 2026-11-05 (round 7).** The `sec1`, `sec2` and four cross-open lines above are from a re-run on the
rewritten branches (sec.1 now carries Monero master `0b7967907` in place of release-v0.18 `7507aed69`; tips
`54aa43b12` and `16018bb0b`), because the builds they tested changed commit. The rebuilt WASM outputs are
byte-identical to the first builds (the replaced pick differs only in a unit-test file, which the WASM does not
contain); the manifests in this directory are those of the re-run. The `upstream` and `base` lines and the
summary table below are from the first run; the re-run's six lines show the same keys, sync to the tip and
successful cross-open.

## Summary

| run | dist | same keys from the seed as upstream | sync reached the tip | cross-open ok |
|---|---|---|---|---|
| `upstream` | `~/tmp/zeph-r3/cache/harness/dist` | yes | yes (900875/900875) | — (saves data) |
| `base` | `~/tmp/zeph-r3/build-base/out` | yes | yes (900876/900875) | — (saves data) |
| `sec1` | `~/tmp/zeph-r3/build-sec1/out` | yes | yes (900877/900876) | — (saves data) |
| `sec2` | `~/tmp/zeph-r3/build-sec2/out` | yes | yes (900880/900877) | — (saves data) |
| `sec1-opens-upstream` | `~/tmp/zeph-r3/build-sec1/out` | yes | yes (900880/900880) | yes (opened data saved by `~/tmp/zeph-r3/cache/harness/dist`) |
| `upstream-opens-sec1` | `~/tmp/zeph-r3/cache/harness/dist` | yes | yes (900880/900880) | yes (opened data saved by `~/tmp/zeph-r3/build-sec1/out`) |
| `sec2-opens-upstream` | `~/tmp/zeph-r3/build-sec2/out` | yes | yes (900880/900880) | yes (opened data saved by `~/tmp/zeph-r3/cache/harness/dist`) |
| `upstream-opens-sec2` | `~/tmp/zeph-r3/cache/harness/dist` | yes | yes (900880/900880) | yes (opened data saved by `~/tmp/zeph-r3/build-sec2/out`) |

Fields identical in all eight runs: `address`, `viewKey`, `spendPub`, `subaddr01`, `seedRoundtrip`,
`validGood`, `validBad`, `fullAddressMatches`, `isSynced`, `reserveInfoKeys`, `hfVersion`, `balance`,
`reopenAddressMatches`, `wrongPassword`. Differing per run: heights, `syncSeconds`, `dist`/`distSha`,
`openedFrom` (by design), `cacheBytes`, and **`keysBytes`** (finding, quoted, not interpreted):

| run | `keysBytes` | `cacheBytes` |
|---|---|---|
| `upstream` | 1694 | 29238287 |
| `base` | 1669 | 29238287 |
| `sec1` | 1670 | 29238287 |
| `sec2` | 1654 | 29238383 |
| `sec1-opens-upstream` | 1679 | 29238447 |
| `upstream-opens-sec1` | 1672 | 29238383 |
| `sec2-opens-upstream` | 1708 | 29238447 |
| `upstream-opens-sec2` | 1663 | 29238479 |

The same upstream dist gave `keysBytes` 1679 in the first run (2026-11-05T03:36Z, kept in
the local log of that run) and 1694 in this one.
