# zephyr-wallet build evidence (round 19, 2026-11-07)

Work clone `~/tmp/zeph-r6/zw` of the zephyr-wallet fork at the branch tip `3b982332c` (commit 2, the artefact; no pin
commits, see `../../deps/2026-11-07/zephyr-wallet-pins.md`). Node v22.23.4, npm 10.9.9. Git URL rewrite only in the
environment of the npm commands.

## `client/` (web): the build fails
- `npm ci --ignore-scripts`: exit 0, "added 1902 packages, and audited 1903 packages in 18s"; lockfile unchanged.
- `npm run build:web:ci` (= `bash -ac ". ./env/.env.web; react-scripts build"`, react-scripts 4.0.3; `.env.web` sets
  `REACT_APP_PLATFORM=web`, `INLINE_RUNTIME_CHUNK=false`), run with `CI=false` in the environment (upstream's old
  workflow sets the same; no effect here, the error comes first): **exit 1 after 2 s**, before any module is built:
```
Error: error:0308010C:digital envelope routines::unsupported
    at new Hash (node:internal/crypto/hash:101:19)
    at Object.createHash (node:crypto:139:10)
    at module.exports (~/tmp/zeph-r6/zw/client/node_modules/webpack/lib/util/createHash.js:135:53)
    at NormalModule._initBuildHash (~/tmp/zeph-r6/zw/client/node_modules/webpack/lib/NormalModule.js:417:16)
  ...
  library: 'digital envelope routines',
  reason: 'unsupported',
  code: 'ERR_OSSL_EVP_UNSUPPORTED'
Node.js v22.23.4
```
  react-scripts 4 builds with webpack 4, which hashes with MD4; Node 17 and later ship OpenSSL 3, which no longer
  provides MD4 by default. No `build/` directory was produced. No workaround was tried (no
  `NODE_OPTIONS=--openssl-legacy-provider`, no other Node version): question R19-3.
- Upstream's own build workflow (`.github/workflows/web.build.yml-old`, disabled, last changed 2023-07-11) uses Node
  `14`; so does `desktop.build.yml-old`.
- Not possible without `build/`: the comparison of `build/monero_*` and `build/monero_web_worker*` with `client/public/`,
  the sizes of `build/static/js/*.js`, and the smoke test. `chromium` is installed (`/usr/bin/chromium`); it was not
  started.

## `zephyr-desktop-app/`
- `npm ci --ignore-scripts`: exit 0, "added 1013 packages, and audited 1014 packages in 9s".
- `npm run build` (`tsc`): **exit 0**, 3 s, no output besides the script header. No Electron packaging.

## What the artefact reaches
See `../../deps/2026-11-07/zephyr-wallet-pins.md`, section "Where the wallet's core runs": the web wallet runs its core
in `client/public/monero_web_worker.js` (the artefact); the desktop app runs it in the Electron main process from
`node_modules/zephyr-javascript/dist/` of the pinned library `55c7db9f` (`monero_wallet_full.wasm` `5dd69ec92e1f3639…`).

## Round 20: the branch with both pins (library at the zephyr-javascript fork tag), Node 16
Work clone `~/tmp/zeph-r6/zw` with the files of commits 3 and 4 (`c4107de2`, `d8962907`; lockfiles byte-equal to the
branch). Node v16.20.2 from `npx -y -p node@16` (the `node` package on npm), with the system npm 10.9.9, which prints
"npm v10.9.9 does not support Node.js v16.20.2" once per command and then runs. Git URL rewrite in the environment.

### `client/`
- `npm ci --ignore-scripts`: exit 0, "added 1902 packages, and audited 1903 packages"; lockfile unchanged;
  `node_modules/zephyr-javascript/package.json` version `2.3.0`.
- `npm run build:web:ci` with `CI=false` (as upstream's workflow): **exit 0**, 72 s, "Compiled with warnings": ESLint
  warnings in 50 source files (unused variables, unnecessary escapes and the like; no error). `build/` 31912379 bytes
  (31M).
- `build/monero_*` and `build/monero_web_worker*`: all seven byte-equal to `client/public/` and to the
  zephyr-javascript `v2.3.0-sec.1` `dist/SHA256SUMS` (`sha256sum -c` OK).
- `build/static/js/`:

| file | bytes | sha256 (prefix) |
|---|---|---|
| `0.21b121e2.chunk.js` | 2814771 | `ceefdd611e0e2888` |
| `1.dbf10dd7.chunk.js` | 435749 | `7e70ef3f2da5dc16` |
| `4.38c9e2ed.chunk.js` | 1934 | `f30fcef1200cc46c` |
| `5.0f90b7b3.chunk.js` | 1245 | `b93852d4b7620e12` |
| `main.75d545c1.chunk.js` | 1980 | `cecd1e8b9fc7066c` |
| `runtime-main.383ef7f3.js` | 2415 | `fddfab8a88cfdd87` |

- `grep -c "55c7db9f\|0\.7\.11"`: 1 in `0.21b121e2.chunk.js`, 0 elsewhere. The one hit is
  `getVersion(){return"0.7.11"}`: the library's version string, which is `"0.7.11"` at `55c7db9f` **and** at the tag
  (upstream never changed it). The string `2.3.0` occurs only as `REACT_APP_VERSION:"2.3.0"` (the wallet's own version).
  The library's JavaScript in `src/main/js` differs between `55c7db9f` and the tag in one line,
  `get_cache_file_buffer(that._cppAddress, that._password)` → `get_cache_file_buffer(that._cppAddress)`; the bundle
  contains the one-argument form (`get_cache_file_buffer(n._cppAddress)`), i.e. the tag's library.

### Smoke test
`python3 -m http.server 28681 --bind 127.0.0.1 --directory client/build`; Chromium 156.0.8078.79 `--headless=new
--disable-gpu --no-sandbox --virtual-time-budget=20000 --enable-logging=stderr --v=0 --dump-dom`, plus
`--log-net-log` to record every address contacted and a fresh `--user-data-dir`. Exit 0; server stopped afterwards.
- **Start screen renders.** Title "Zephyr Protocol – The Untraceable Stablecoin"; visible strings: "ZEPHYR", "Login",
  "Create a Wallet", "Privately store, exchange and transfer assets", "Create", "Restore", "Wallet Name", "Wallet
  Password", "Show", the wallet-creation help text, "Cancel", "Create", "Have a Wallet?", "Login".
- Console: two page messages, `"fin env"` (from `main.*.chunk.js`) and Chromium's "[DOM] Password field is not
  contained in a form"; no error, nothing about the WASM or the worker.
- **The start screen loads neither the worker nor the WASM**: the server log shows `/`, `manifest.json`, five
  `static/js` files, the logo and three fonts, no `monero_*` and no `nodes.json`. The worker starts when a wallet is
  created or opened, which this test does not do. So the smoke test shows the page renders with the pinned library;
  it does not exercise the WASM (the harness does, for the same files).
- Addresses the page contacts by itself: `127.0.0.1:28681` and `https://fonts.googleapis.com/css?family=Playfair+Display:400,900`
  (initiator `http://127.0.0.1:28681`; the `<link>` in upstream's `public/index.html`), then `fonts.gstatic.com` for the
  font files. No Zephyr node. The other requests in the net log are Chromium's own (`clients2.google.com` time,
  `update.googleapis.com` and `*.gvt1.com` component and dictionary downloads, `accounts.google.com`,
  `content-autofill.googleapis.com`).
