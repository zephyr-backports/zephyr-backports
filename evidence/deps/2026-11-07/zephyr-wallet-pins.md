# zephyr-wallet dependency pins, measured (round 19, 2026-11-07)

Work clone `~/tmp/zeph-r6/zw` of the zephyr-wallet fork at `3b982332c` (branch `security/v2.3.0`, commit 2: the
artefact). Node v22.23.4, npm 10.9.9. Git URL rewrite only in the environment of the npm commands
(`GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=url.https://github.com/.insteadOf GIT_CONFIG_VALUE_0=ssh://git@github.com/`); no
global git config. **No pin commit was made** (question R19-1); the lockfiles are kept in `~/tmp/zeph-r6/`.

## `package.json` (both directories, the only change)
```
-    "zephyr-javascript": "github:ZephyrProtocol/zephyr-javascript"
+    "zephyr-javascript": "github:ZephyrProtocol/zephyr-javascript#55c7db9f2d265a996505dfc9b527e980355a99ba"
```
(`zephyr-desktop-app/package.json`: the same line with its trailing comma.) `npm audit fix` changed nothing else in
`package.json`. In both directories `zephyr-javascript` stays `0.7.11` at `55c7db9f2d265a996505dfc9b527e980355a99ba`,
lockfileVersion stays 3.

## Two commands, two results
The work order's command is `npm audit fix --package-lock-only --ignore-scripts`; the 2026-11-05 measurement
(the measurement of 2026-11-05, private work notes) used `npm audit fix --package-lock-only --omit=dev --ignore-scripts`. Both were run on the
same starting point (the spec change above). Production entries = lockfile entries without `dev`/`devOptional`.

### `client/`
| | work order (no `--omit=dev`) | `--omit=dev` (as measured 2026-11-05) |
|---|---|---|
| `git diff --stat` of the lockfile | 2652 lines (1434+, 1220−) | 275 lines (155+, 120−) |
| entries | 1905 → 1893 | 1905 → 1905 |
| production changed / added / removed | 24 / 1 / 4 | 23 / 1 / 1 |
| dev changed / added / removed | 116 / 39 / 48 | 0 / 0 / 0 |
| entries switching prod ↔ dev, same version | 13 | 15 |
| lockfile sha256 | `99da81a821ed6e14…` | `ad92dffa6852d81d…` |
| `npm ci --ignore-scripts` | exit 0, 1890 packages | exit 0, 1902 packages |
| production audit before → after | 18 → 11 | 18 → 11 |

Production changes with `--omit=dev`, exactly the measured list minus `zephyr-javascript` (which stays, as
intended): `@babel/code-frame` 7.18.6 → 7.29.7, `@babel/generator` 7.20.5 → 7.29.13,
`@babel/generator/node_modules/@jridgewell/gen-mapping` 0.3.2 → 0.3.13, `@babel/helper-string-parser` 7.19.4 →
7.29.13, `@babel/helper-validator-identifier` 7.19.1 → 7.29.7, `@babel/parser` 7.20.5 → 7.29.13, `@babel/runtime`
7.20.6 → 7.29.13, `@babel/template` 7.18.10 → 7.29.7, `@babel/traverse` 7.20.5 → 7.29.13, `@babel/types` 7.20.5 →
7.29.11, `@jridgewell/sourcemap-codec` 1.4.14 → 1.6.0, `@jridgewell/trace-mapping` 0.3.17 → 0.3.31,
`@remix-run/router` 1.0.4 → 1.23.4, `ajv` 6.12.6 → 6.15.0, `crypto-js` 4.1.1 → 4.2.0, `jsesc` 2.5.2 → 3.1.0, `lodash`
4.17.21 → 4.18.1, `picocolors` 1.0.0 → 1.1.1, `picomatch` 2.3.1 → 2.3.2, `qs` 6.5.3 → 6.5.5, `react-router` 6.4.4 →
6.30.6, `react-router-dom` 6.4.4 → 6.30.6, `uuid` 3.3.2 → 3.4.0; added `@babel/helper-globals` 7.29.7; removed
`to-fast-properties` 2.0.0.
The work-order command moves, in addition to the dev tree: `@babel/helper-module-imports` 7.18.6 → 7.29.7;
`@jridgewell/gen-mapping` hoisted (0.1.1 → 0.3.13, previously dev) instead of the nested copy; removed
`@babel/helper-hoist-variables`, `@jridgewell/set-array` and the nested `gen-mapping`.

### `zephyr-desktop-app/`
| | work order (no `--omit=dev`) | `--omit=dev` (as measured 2026-11-05) |
|---|---|---|
| `git diff --stat` of the lockfile | 2732 lines (1287+, 1445−) | 257 lines (206+, 51−) |
| entries | 1042 → 1004 | 1042 → 1053 |
| production changed / added / removed | 12 / 11 / 1 | 11 / 11 / 0 |
| dev changed / added / removed | 107 / 29 / 77 | 0 / 0 / 0 |
| lockfile sha256 | `4869d72674df9d26…` | `928b18b15f84b459…` |
| `npm ci --ignore-scripts` | exit 0, 975 packages | exit 0, 1024 packages |
| production audit before → after | 14 → 9 | 14 → 9 |

Production changes with `--omit=dev`, the measured list minus `zephyr-javascript`: `ajv` 6.15.0, `axios` 1.2.3 →
1.21.0, `crypto-js` 4.2.0, `follow-redirects` 1.15.2 → 1.16.2, `form-data` 4.0.0 → 4.0.6, `function-bind` 1.1.2,
`get-intrinsic` 1.3.0, `has-symbols` 1.1.0, `lodash` 4.18.1, `proxy-from-env` 1.1.0 → 2.1.0, `qs` 6.5.5; added
`call-bind-apply-helpers`, `dunder-proto`, `es-define-property`, `es-errors`, `es-object-atoms`, `es-set-tostringtag`,
`get-proto`, `gopd`, `has-tostringtag`, `hasown`, `math-intrinsics`.
The work-order command moves, in addition to the dev tree: the hoisted `serialize-javascript` **6.0.1 → 3.1.0**
(a downgrade; the 6.0.1 copy was dev) and removes `zephyr-javascript/node_modules/serialize-javascript` 3.1.0.

## Advisories closed (production audit, `npm audit --omit=dev`): identical for both commands
`client/` closes 10: GHSA-968p-4wvh-cqc8 (`@babel/runtime`), GHSA-67hx-6x53-jw92 (`@babel/traverse`, critical),
GHSA-2w69-qvjg-hvjx (`@remix-run/router`, high), GHSA-2g4f-4pwh-qvx6 (`ajv`), GHSA-xwcq-pm8m-c4vf (`crypto-js`,
critical), GHSA-r5fr-rjxr-66jc and GHSA-xxjr-mmjv-4gpg (`lodash`), GHSA-3v7f-55p6-f55p and GHSA-c2c7-rcm5-vvqj
(`picomatch`), GHSA-9jcx-v3wj-wh4m (`react-router`). Left 11: `form-data` (GHSA-fjxv-7rqg-78g4, GHSA-hmw2-7cc7-3qxx),
`qs` (GHSA-4mjr-xmp4-gh2g, GHSA-6rw7-vpxm-498p), `react-router` (GHSA-337j-9hxr-rhxg, GHSA-wrjc-x8rr-h8h6),
`request` (GHSA-p8p7-x288-28g6), `serialize-javascript` (GHSA-5c6j-r48x-rmvq, GHSA-m5mm-p8h7-m29v), `tough-cookie`
(GHSA-72xf-g2v4-qvf3), `uuid` (GHSA-w5hq-g745-h8pq).
`zephyr-desktop-app/` closes 38: `ajv` (1), `axios` (31), `crypto-js` (1), `follow-redirects` (3), `lodash` (2); the
ids are the measured list of 2026-11-05. Left 9: `form-data` (2), `qs` (2), `request`, `serialize-javascript` (2),
`tough-cookie`, `uuid`.

Why `@babel/traverse` and `picomatch` count as production: `@babel/traverse` through `styled-components` →
`babel-plugin-styled-components` (a production dependency of `styled-components`; a Babel plugin, run at build
time); `picomatch` through `@rollup/pluginutils`. The work order expected `@babel/traverse` to be dev-only.

## Where the wallet's core runs (relevant to the artefact and to the `zephyr-javascript` spec)
- **Web:** `client/src/shared/actions/walletCreation.ts` creates and opens wallets with `proxyToWorker: true`; library
  0.7.11 starts the worker from `LibraryUtils.WORKER_DIST_PATH_DEFAULT` = `"/monero_web_worker.js"` in a browser,
  i.e. `client/public/monero_web_worker.js`, which bundles its glue and loads the `.wasm` from `client/public/`. The
  web wallet's core is therefore the artefact of commit 2.
- **Desktop:** the Electron main process creates and opens wallets itself (`zephyr-desktop-app/src/shared/wallet.ts`:
  `core.createWalletFull`, `core.openWalletFull`, `core` = `zephyr-javascript`). In Node, library 0.7.11 loads
  `require("../../../../dist/monero_wallet_full")`, its own `dist/`: from the pinned `55c7db9f`,
  `monero_wallet_full.wasm` `5dd69ec92e1f3639…` (5260427 bytes), `monero_wallet_keys.wasm` `2a586072a7e76bbb…`. That is
  neither upstream's `client/public/` (`b4d7413e…`) nor the artefact (`c984b999…`). **The desktop wallet's core does
  not get the rebuilt WASM** as long as the library stays at `55c7db9f`.
- Upstream's disabled workflow `.github/workflows/web.build.yml-old` (last changed 2023-07-11, Node 14) ran
  `npm install zephyr-javascript@latest --save` and then `npm run copy-zephyr-core`, which copies the library's
  `dist/` over `client/public/`. A builder who follows it replaces the artefact with the library's files.
- `axios` in the desktop app: declared in `zephyr-desktop-app/package.json` (`"axios": "^1.2.0"`), but `grep -rln axios`
  outside `node_modules/` finds only `package.json` and `package-lock.json`; `npm explain axios` shows only the root
  project; library 0.7.11 does not import it. `follow-redirects` comes in only through `axios`. So the 34 `axios` and
  `follow-redirects` advisories are not reachable from the desktop app's code as measured (the work order expected
  them to be).

## Round 20: the library at the zephyr-javascript fork tag, `--omit=dev`, committed
Fresh checkout of `3b982332c` in `~/tmp/zeph-r6/zw`; Node v16.20.2 (`npx -y -p node@16`) with npm 10.9.9 (which warns
that it does not support Node 16 and runs). In both directories:
1. `package.json`: `zephyr-javascript` → `github:zephyr-backports/zephyr-javascript#v2.3.0-sec.1` (only change).
2. `npm install --package-lock-only --ignore-scripts`: exit 0; the lockfile changes only in the root spec and the
   library's entry: version `0.7.11` → `2.3.0`, `resolved`
   `git+ssh://git@github.com/zephyr-backports/zephyr-javascript.git#7b17a14280bd84ca783287f4640b3c744d25319f` (client 6
   lines, desktop 6 lines). The library's `dependencies`, `peerDependencies` and `optionalDependencies` are identical
   at `55c7db9f` and `7b17a1428`, so nothing else moves.
3. `npm audit fix --package-lock-only --omit=dev --ignore-scripts`: the production changes are exactly the round-19
   `--omit=dev` lists plus `zephyr-javascript` 0.7.11 → 2.3.0; 0 dev changes; lockfileVersion 3. The client lockfile is
   byte-equal to round 19's `--omit=dev` lockfile with the library's entry and root spec replaced.
   `client/`: 279 lines, entries 1905 → 1905, production 24 changed / 1 added / 1 removed. `zephyr-desktop-app/`: 261
   lines, entries 1042 → 1053, production 12 changed / 11 added / 0 removed.
4. Production audit: client 18 → 11 (10 closed), desktop 14 → 9 (38 closed): the same ids as round 19 and 2026-11-05.
5. `npm ci --ignore-scripts`: client exit 0 (1902 packages), desktop exit 0 (1024 packages); lockfiles unchanged.
Committed as `c4107de2c` (client) and `d89629070` (desktop) on `security/v2.3.0`, with 10 and 38 `Advisory:` lines.

`zephyr-javascript` in the npm registry: `npm view zephyr-javascript` → `E404 Not Found` (2026-11-07). What
`npm install zephyr-javascript@latest --save` in upstream's 2023 workflows resolved to is not verifiable from here.
