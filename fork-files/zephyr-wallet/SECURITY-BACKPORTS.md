# Security backports

Base: `ZephyrProtocol/zephyr-wallet` commit `a63147fd` ("Fix price history graph", 2025-06-16; the
state of the v2.3.0 web and desktop wallets), itself on `haven-protocol-org/haven-web-app` `aa21b2c6`
(2023-02-12). Policy: https://github.com/zephyr-backports/zephyr-backports (docs/POLICY.md). Each entry
is one dependency pin (trailer `Advisory:`) or one artefact rebuild (trailers `Built-From:`). Builds
are not platform-signed (POLICY §7); verify them by the GPG-signed `SHA256SUMS`.

**v2.3.0-sec.1** (draft, not tagged)

| # | Tag | Type | Advisory / source | Component | Summary |
|---|---|---|---|---|---|
| SB-036 | v2.3.0-sec.1 | artefact | zephyr-javascript `v2.3.0-sec.1` | `client/public/` (WASM, glue, worker bundle) | the wallet core of the web wallet from the security forks |
| SB-037 | v2.3.0-sec.1 | pin | library + 10 GHSAs | `client/` | the wallet library at the zephyr-javascript fork tag; `react-router`, `@remix-run/router` and others with fixed advisories |
| SB-038 | v2.3.0-sec.1 | pin | library + 38 GHSAs | `zephyr-desktop-app/` | the wallet library at the zephyr-javascript fork tag (the desktop wallet core); `axios`, `follow-redirects` and others |

## Advisories

<!-- One section per change; template: docs/ADVISORY-TEMPLATE.md in zephyr-backports/zephyr-backports -->

### SB-036 — The wallet WASM from zephyr-javascript v2.3.0-sec.1

- **Tag:** v2.3.0-sec.1
- **Type:** artefact
- **Origin:** the seven files of `dist/` of zephyr-backports/zephyr-javascript `v2.3.0-sec.1`
  (`7b17a14280bd84ca783287f4640b3c744d25319f`, advisory SB-035 there), byte-equal (`sha256sum -c` against that tag's
  `dist/SHA256SUMS`), built from zephyr-backports/zephyr `v2.3.0-sec.2` (`8c6a120256b4bd887d6e7167d929d76e3507e0e5`) and
  zephyr-backports/zephyr-cpp `v2.3.0-sec.1` (`3a2ee602ee28e6b7941b617ad4706349ad992641`); build manifest:
  `dist/build-manifest.json` at that tag.
- **Class:** the classes of the advisories it carries: memory, dos, funds, privacy
- **Component:** `client/public/monero_wallet_{full,keys}.{wasm,js}`, `client/public/monero_web_worker.js` and its
  source map (the `.LICENSE.txt` is unchanged)
- **Affects:** users of the web and the desktop wallet. The web wallet creates and opens wallets with
  `proxyToWorker: true`; the library starts the worker from `/monero_web_worker.js`, i.e. these files, which CRA copies
  into the build unchanged. The desktop wallet runs the wallet core in the Electron main process with the library from
  `node_modules`, which loads the WASM from its own `dist/`; with SB-038 that library is the zephyr-javascript fork tag,
  whose `dist/` holds the same files. Upstream's `client/public/` at `a63147fd` is byte-equal to zephyr-javascript
  `9d022ded` `dist/` (built from zephyr v2.3.0 without the backports); upstream's desktop app loaded the 2023 build of
  library 0.7.11 (`monero_wallet_full.wasm` `5dd69ec92e1f3639…`).
- **Impact:** the wallet core carries the 19 advisories of the release set whose changed files are compiled into the
  WASM: zephyr SB-001 to SB-009 and SB-015 to SB-019, zephyr-cpp SB-011 to SB-014 (see SB-035 of zephyr-javascript).
- **Compatibility statement:** POLICY §4: as SB-035 of zephyr-javascript (same files): no JavaScript API change, the
  unresolved imports match the pinned sets, wallet data opens both ways with upstream's WASM (harness cross-open,
  2026-11-07). Nothing else in `client/public/` and no application code changes.
- **Conflict resolution:** none (no cherry-pick)
- **Test evidence:** done 2026-11-07 (local run; files in evidence/wallet/2026-11-07/ and evidence/wasm/2026-11-07/):
  byte equality with the zephyr-javascript tag's `dist/`; for those files, the WASM build, guards, harness and
  cross-open of zephyr-javascript SB-035; web build of this branch (Node 16, `react-scripts build`, exit 0) with
  `build/monero_*` byte-equal to the tag's `dist/` (`web-build.md`); headless smoke test: the start screen renders, no
  console error (the start screen does not load the worker or the WASM); in the desktop app the library's `dist/`
  holds the artefact (`monero_wallet_full.wasm` `c984b999…`, `desktop-build.md`). Pending: fork CI provenance; the
  wallet flows past the start screen in a browser and in Electron (create, restore, sync, send).
- **Notes:** upstream's disabled build workflow copied the library's `dist/` over `client/public/`
  (`npm run copy-zephyr-core`); with SB-037 that `dist/` is the same files. The web page loads a font from
  `fonts.googleapis.com` (upstream's `index.html`, unchanged).

### SB-037 — Client: the wallet library at the fork tag, and dependency pins

- **Tag:** v2.3.0-sec.1
- **Type:** pin
- **Origin:** `client/package.json`: `zephyr-javascript` from `github:ZephyrProtocol/zephyr-javascript` (no ref; the
  lockfile held 0.7.11 at `55c7db9f`) to `github:zephyr-backports/zephyr-javascript#v2.3.0-sec.1` (the only
  `package.json` change); then `npm audit fix --package-lock-only --omit=dev` (npm 10.9.9), lockfile format 3 kept, no
  dev entry changed.
- **Class:** dependency
- **Component:** `client/package.json`, `client/package-lock.json`
- **Affects / Impact:**
  - The library: upstream's `package.json` names the library without a ref and its build workflows ran `npm install
    zephyr-javascript@latest`; the lockfile held a 2023 commit. The pin makes the dependency explicit at the security
    fork's tag (2.3.0, `7b17a1428`). Its dependencies are identical to those of 0.7.11, and its JavaScript in
    `src/main/js` differs in one line (the cache-buffer call of the 2.3.0 WASM); the app bundle carries the tag's form.
  - Reachable at runtime: GHSA-2w69-qvjg-hvjx (`@remix-run/router` <= 1.23.1, high: XSS via open redirects) and
    GHSA-9jcx-v3wj-wh4m (`react-router` < 6.30.2, moderate: external redirect via untrusted paths). The wallet routes
    with `react-router-dom` (`HashRouter`, `Navigate`, `useNavigate`); whether a path from outside the app reaches a
    redirect was not analysed. `react-router`/`react-router-dom` 6.4.4 → 6.30.6, `@remix-run/router` 1.0.4 → 1.23.4.
  - Built into the bundle: GHSA-968p-4wvh-cqc8 (`@babel/runtime` < 7.26.10: inefficient RegExp in code Babel generates
    for named capture groups); 7.20.6 → 7.29.13.
  - Build time only: GHSA-67hx-6x53-jw92 (`@babel/traverse` < 7.23.2, critical: code execution when compiling crafted
    code; through the `styled-components` Babel plugin) and GHSA-3v7f-55p6-f55p, GHSA-c2c7-rcm5-vvqj (`picomatch`
    < 2.3.2; through rollup utilities). npm counts them as production; they run on the build machine.
  - Not reachable through the library's own code as measured: GHSA-xwcq-pm8m-c4vf (`crypto-js` 4.2.0),
    GHSA-r5fr-rjxr-66jc and GHSA-xxjr-mmjv-4gpg (`lodash` 4.18.1), GHSA-2g4f-4pwh-qvx6 (`ajv` 6.15.0) (zephyr-javascript
    "Not applied"; files in evidence/deps/2026-11-07/: `zephyr-javascript-pins.md`).
- **Compatibility statement:** no application code; the web build passes with the pinned library; wallet files are
  handled by the WASM of SB-036 (cross-open both ways).
- **Conflict resolution:** none
- **Test evidence:** done 2026-11-07 (local run; files in evidence/deps/2026-11-07/ and evidence/wallet/2026-11-07/):
  `npm ci` exit 0; production audit 18 → 11; the changed production entries are the measured list plus the library
  (`zephyr-wallet-pins.md`); web build exit 0 and smoke test (`web-build.md`). Pending: fork CI provenance.

### SB-038 — Desktop: the wallet library at the fork tag, and dependency pins

- **Tag:** v2.3.0-sec.1
- **Type:** pin
- **Origin:** as SB-037, in `zephyr-desktop-app/`: the same `zephyr-javascript` spec, then `npm audit fix
  --package-lock-only --omit=dev`, lockfile format 3 kept, no dev entry changed.
- **Class:** dependency
- **Component:** `zephyr-desktop-app/package.json`, `zephyr-desktop-app/package-lock.json`
- **Affects / Impact:**
  - The library: the desktop app runs the wallet core in its main process with this library, which loads the WASM
    from its own `dist/`. With the pin that is the artefact of SB-036 instead of the 2023 build of 0.7.11, so the
    desktop wallet gets the 19 WASM backports. Upstream's desktop build workflow ran `npm install
    zephyr-javascript@latest` in this directory.
  - Not imported: `axios` 1.2.3 → 1.21.0 closes 31 advisories and `follow-redirects` 1.15.2 → 1.16.2 three (credential
    and header leaks across redirects and proxies, SSRF, prototype-pollution gadgets, DoS). `axios` is declared in
    `package.json` but no file of the app or of the library imports it; `follow-redirects` comes in only through it.
    The pin removes the flagged versions from what the desktop package installs.
  - Not reachable through the library's own code as measured: `crypto-js` 4.2.0, `lodash` 4.18.1 (two), `ajv` 6.15.0.
- **Compatibility statement:** no application code; `tsc` passes with the pinned library.
- **Conflict resolution:** none
- **Test evidence:** done 2026-11-07 (local run; files in evidence/deps/2026-11-07/ and evidence/wallet/2026-11-07/):
  `npm ci` exit 0; production audit 14 → 9; the changed production entries are the measured list plus the library;
  `tsc` exit 0; the library's `dist/` is the artefact (`desktop-build.md`). `jest` does not run at all, before and after
  the pin: its only suite imports two modules that do not exist in the app (an upstream defect since 2023). Pending:
  fork CI provenance; the app's flows in Electron.

## Not applied

- `react-router` GHSA-wrjc-x8rr-h8h6 and GHSA-337j-9hxr-rhxg: fixed only in v7, a major version outside the declared
  range (application code would change).
- `qs` GHSA-6rw7-vpxm-498p and GHSA-4mjr-xmp4-gh2g (through `request`): the in-range 6.5.5 closes neither.
- The `request` chain (`request` GHSA-p8p7-x288-28g6, `form-data` 2.x GHSA-fjxv-7rqg-78g4 and GHSA-hmw2-7cc7-3qxx,
  `tough-cookie` GHSA-72xf-g2v4-qvf3, `uuid` GHSA-w5hq-g745-h8pq) and `serialize-javascript` (GHSA-5c6j-r48x-rmvq,
  GHSA-m5mm-p8h7-m29v): no fix that npm can apply within the declared ranges; replacing `request` is a code change
  (upstream monero-ts did so), out of scope here.
