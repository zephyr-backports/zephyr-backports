# Security backports

Base: `ZephyrProtocol/zephyr-javascript` commit `9d022ded` ("Updates for version 2.3.0", 2025-06-16;
the state the Zephyr v2.3.0 wallets were built from), itself on `woodser/monero-javascript` `1dd86702`
(2023-06-09). Policy: https://github.com/zephyr-backports/zephyr-backports (docs/POLICY.md). Each entry
is one cherry-picked monero-ts commit into the C++ bridge, one dependency pin (trailer `Advisory:`) or one
artefact rebuild (trailers `Built-From:`); the Type column is `pick`, `pin` or `artefact`.

**v2.3.0-sec.1** (draft, not tagged)

| # | Tag | Type | Advisory / source | Component | Summary |
|---|---|---|---|---|---|
| SB-035 | v2.3.0-sec.1 | artefact | zephyr `v2.3.0-sec.2`, zephyr-cpp `v2.3.0-sec.1` | `dist/` (WASM, glue, worker bundle) | the wallet WASM rebuilt from the security forks, so their backports reach the library |

## Advisories

<!-- One section per change; template: docs/ADVISORY-TEMPLATE.md in zephyr-backports/zephyr-backports -->

### SB-035 — The wallet WASM rebuilt from zephyr v2.3.0-sec.2 and zephyr-cpp v2.3.0-sec.1

- **Tag:** v2.3.0-sec.1
- **Type:** artefact
- **Origin:** built from the release set of 2026-11-07: zephyr-backports/zephyr `v2.3.0-sec.2`
  (`8c6a120256b4bd887d6e7167d929d76e3507e0e5`), zephyr-backports/zephyr-cpp `v2.3.0-sec.1`
  (`3a2ee602ee28e6b7941b617ad4706349ad992641`) and ZephyrProtocol/zephyr-javascript `9d022ded2a8d188127173aa7cf79fdd5ee006353`
  (this fork's base), with the webwallet project's reproducible WASM build (`tools/wasm/build.sh`, sha256
  `05ff98b3835515d82cac03b8f86ae740586c8f60a36badd15deda6041c8eefc5`: emsdk 3.1.10, boost 1.84.0, OpenSSL and
  unbound headers only) at the canonical build path `/tmp/zeph-wasm/build`. The commit carries one
  `Built-From:` trailer per source; `dist/build-manifest.json` records pins, patches, toolchain, flags and output hashes,
  `dist/SHA256SUMS` the hashes of the seven `dist/` files:
  `monero_wallet_full.wasm` `c984b999dd76550ab8135a0d7ddfd34b5fc7774200f8887aaa5f4984a7c7b1e4`,
  `monero_wallet_full.js` `5cd17d48e821f606fff603e9db4fd2a4aba8c8628a452d79ad73434c48ae32ad`,
  `monero_wallet_keys.wasm` `fc630b04d52dc500823c9d02383a317bd27e1946b7b20a9bdc141ef29216d13b`,
  `monero_wallet_keys.js` `69b02e1e9f12064b845a9d06ed3577a54eeedcafd679dbc283ae515470abe607`,
  `monero_web_worker.js` `923f551c9e27260bc1da63e97f335b96a3e8b2a7c4622bcb955ef8b0b6b0d7ac`,
  `monero_web_worker.js.map` `ae2b5afe453922aac8fc624fbe7765195e85d43bb23882cad3738da5c813d55e`,
  `monero_web_worker.js.LICENSE.txt` `5f4f84c2d4dd4507ea51b95cf42b500068e2b2307fbd0137f8db809c645d011b` (unchanged
  from upstream). The worker bundle is built with the package's own `npm run build_web_worker` (webpack 5.77.0) from
  the unpinned install of the base lockfile (`npm ci`, Node v22.23.4, npm 10.9.9).
- **Class:** the classes of the advisories it carries: memory, dos, funds, privacy
- **Component:** `dist/monero_wallet_full.{wasm,js}`, `dist/monero_wallet_keys.{wasm,js}` (the wallet core compiled
  to WebAssembly, with its emscripten glue) and `dist/monero_web_worker.js` with its source map (the web worker bundle,
  which includes both glue files)
- **Affects:** every user of this library's prebuilt `dist/`, which is what the Zephyr web and desktop wallets
  ship: the wallet core in upstream's `dist/` is built from zephyr v2.3.0 and zephyr-cpp `4a99272`, without the
  backports. The WASM scans on-chain data and talks to a remote node, so the untrusted input the backports guard
  against reaches it.
- **Impact:** the rebuilt WASM contains the backports whose changed files are compiled into it, 19 of the 34
  advisories of the release set: zephyr SB-001 to SB-009 and SB-015 to SB-019 (epee, crypto, serialization,
  wallet2, logging) and zephyr-cpp SB-011 to SB-014 (monero-cpp wallet and model). SB-010 and SB-020 to SB-034
  (DNSSEC anchor, depends, RandomX, Windows build, daemon RPC and ZMQ, levin) do not reach the WASM (file-level check
  against the build's compiler dependency files). Without the rebuild, those fixes exist in the forks but not in the
  library wallets run.
- **Compatibility statement:** POLICY §4 checked: the WASM is built from the release set, whose advisories each carry
  their own compatibility statement (rules 1 to 5); the rebuild adds no source change of its own beyond the webwallet
  project's build patches, which the manifest lists (guard 4: the modified upstream files are exactly those the
  patches touch). The JavaScript API is unchanged: zephyr-javascript's source is untouched, the C++ bridge is built
  from the base commit, and the unresolved imports match the pinned sets (guard 2: full 10, keys 3 symbols). Wallet files: the harness's cross-open
  passes both ways with upstream's prebuilt `dist/` (data saved by either opens in the other). The version string is
  the upstream one.
- **Conflict resolution:** none (no cherry-pick)
- **Test evidence:** done 2026-11-07 (local run; files in evidence/wasm/2026-11-07/): WASM build of the release set at
  `/tmp/zeph-wasm/build`, guards 1–4 OK, no host path in any output (`set-2026-11-07-build-manifest.json`,
  `harness-results.md`, section "Release set 2026-11-07"); `keys.wasm`, both `.js` and the symbol map byte-identical
  to the 2026-11-07 build of the published sec.2 commits, `full.wasm` different only by the build path in two strings;
  harness smoke test (keys from seed, 40-block sync to tip, reserve info, serialisation, reopen) OK and cross-open both
  ways with upstream's prebuilt dist (`9d022ded`, keys `a541c83c`) OK; worker bundle built with zephyr-javascript's own
  `npm run build_web_worker` (webpack 5.77.0), which on upstream's own `dist/` reproduces upstream's bundle
  byte-for-byte, and which gave the same seven hashes in two separate runs from a fresh `npm ci`
  (`set-2026-11-07-dist.md`); which advisories are compiled in: `set-2026-11-07-wasm-inputs.md`. Pending:
  fork CI provenance run on the published branch; the signature of the build manifest with the release key; the
  wallet flows the harness does not reach (sending, which needs funds or a mocked node).
- **Notes:** the worker bundle also contains third-party JavaScript (`crypto-js`, `ajv`, `lodash`, `qs`) at the
  versions of the base lockfile (`crypto-js` 4.1.1, `ajv` 6.12.6, `lodash` 4.17.21, `qs` 6.5.3); the dependency pins
  for these were not applied (see "Not applied" below). Byte identity with
  upstream's `dist/` is not a goal (upstream's build embeds paths of its build machine); byte identity between two
  builds at the same path is (2026-11-05, same inputs, same path: identical bytes).

## Not applied

### Dependency pins for `crypto-js`, `lodash`, `ajv` (and `qs`)

Four advisories against production dependencies have a fixed version inside the declared ranges:
GHSA-xwcq-pm8m-c4vf (`crypto-js` < 4.2.0, critical: PBKDF2 defaults far weaker than specified),
GHSA-r5fr-rjxr-66jc (`lodash` <= 4.17.23, high: code injection via `_.template` imports key names),
GHSA-xxjr-mmjv-4gpg (`lodash` <= 4.17.22, moderate: prototype pollution in `_.unset`, `_.omit`, `_.pullAt`) and
GHSA-2g4f-4pwh-qvx6 (`ajv` < 6.14.0, moderate: ReDoS with the `$data` option). They are not pinned on this branch:

- **Not reachable from the library's own code, as measured:** zephyr-javascript calls `crypto-js` only for `MD5`
  (HTTP digest authentication), never `PBKDF2`; it does not use `lodash` itself, and the worker bundle contains only
  twelve small `lodash` helpers (`isArray`, `isFunction` and the like), not `template`, `unset`, `omit` or `pullAt`;
  `ajv` arrives only through `request` → `har-validator`, which creates it without `$data`.
- **No installable pin:** npm 10 produces the four fixed versions only by rewriting `package-lock.json` from format
  v1 to v3, and on the v3 lockfile `npm ci` stops with a peer-dependency conflict (`worker-loader` 2.0.0 expects
  webpack 3 or 4, the package uses webpack 5) that the v1 lockfile does not record. npm 6, which keeps format v1,
  changes `package.json` and raises dev tools (webpack, Babel, jsdoc), and its audit data moves neither `crypto-js`
  nor `qs`.

`qs` 6.5.3 (through `request`) has two advisories, GHSA-6rw7-vpxm-498p and GHSA-4mjr-xmp4-gh2g; the in-range
version 6.5.5 closes neither (they need 6.14.1 and 6.16.0). The remaining advisories of the dependency tree
(`request`, `form-data`, `tough-cookie`, `uuid`, `serialize-javascript`) have no fix that npm can apply within the
declared ranges; upstream removed `request` by a code change, which is out of scope here. Measurement (files in
evidence/deps/2026-11-07/): `zephyr-javascript-pins.md`.
