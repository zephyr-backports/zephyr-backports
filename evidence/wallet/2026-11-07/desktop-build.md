# zephyr-wallet desktop app: build and tests with the pinned library (round 20, 2026-11-07)

Work clone `~/tmp/zeph-r6/zw`, `zephyr-desktop-app/` with the files of commit 4 (`d8962907`: `zephyr-javascript` →
`github:zephyr-backports/zephyr-javascript#v2.3.0-sec.1`, 2.3.0 at `7b17a1428`, plus the dependency pins). Node v16.20.2
(`npx -y -p node@16`) with npm 10.9.9 (support warning once per command). No Electron packaging.

- `npm ci --ignore-scripts`: exit 0, "added 1024 packages, and audited 1025 packages"; lockfile unchanged.
- `npm run build` (`tsc`): **exit 0**, 4 s, no diagnostics.
- `npm test` (`jest --detectOpenHandles`): **exit 1**: one suite, `__tests__/index.ts`, "Test suite failed to run",
  0 tests:
```
__tests__/index.ts:1:37 - error TS2307: Cannot find module '../src/daemonPaths' or its corresponding type declarations.
__tests__/index.ts:3:36 - error TS2307: Cannot find module '../src/rpc/RPCHRequestHandler' or its corresponding type declarations.
Test Suites: 1 failed, 1 total
Tests:       0 total
```
  plus the coverage thresholds (100 %) not met, since nothing ran. **Not caused by the library move:** the test
  imports two modules that do not exist in the app (no `src/daemonPaths*`, no `src/rpc/`); the file was last changed
  in `c01ce826` (2023-07-11, "Adapt for Zephyr"). Control at commit 2 (`3b982332c`, library 0.7.11 at `55c7db9f`, base
  lockfile, the same Node 16 and npm, fresh clone `~/tmp/zeph-r6/zw-base`): the identical two TS2307 errors, 0 tests,
  exit 1. Jest gives no evidence either way; `tsc` is the check that the app compiles against the library's API.
- The WASM the library loads in Node (`LibraryUtils` requires `../../../../dist/monero_wallet_full`):
  `node_modules/zephyr-javascript/dist/monero_wallet_full.wasm`
  `c984b999dd76550ab8135a0d7ddfd34b5fc7774200f8887aaa5f4984a7c7b1e4` (the artefact); the whole `dist/` passes
  `sha256sum -c` against its `SHA256SUMS` (the tag's). Before the pin: `5dd69ec92e1f3639…` (the 2023 build of 0.7.11).
- Behaviour in Node of this library with these files: the webwallet harness (`core-test.cjs`) runs zephyr-javascript's
  JavaScript at `9d022ded` (identical to the tag outside `dist/`) with the `dist/` of the tag's commit `7b17a1428`:
  keys from seed, sync to tip, reserve info, serialisation, reopen, cross-open both ways with upstream's WASM, all OK
  (2026-11-07, `../../wasm/2026-11-07/harness-results.md`, section "Committed `dist/` of the zephyr-javascript branch
  tip (round 18)"). The desktop app's own code paths (IPC, the Electron main process) were not run.
