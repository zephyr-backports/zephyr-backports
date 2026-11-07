# zephyr-javascript dependency pins, measured again (round 17, 2026-11-07)

Scratch clone `~/tmp/zeph-r5/zjs-pin` of the fork at `9d022ded2a8d188127173aa7cf79fdd5ee006353`; Node v22.23.4,
npm 10.9.9, the same as `.agent/DEPENDENCY-PINS.md` (2026-11-05). Nothing of this is committed to the fork.

## The lockfile change
`npm audit fix --package-lock-only --omit=dev --ignore-scripts` (the 2026-11-05 command): exit 1 (vulnerabilities
remain), "8 vulnerabilities (5 moderate, 1 high, 2 critical)". `npm audit --omit=dev`: 10 before (3 critical, 2 high,
5 moderate), 8 after (2 critical, 1 high, 5 moderate), as on 2026-11-05.
- `package.json` unchanged (sha256 `37eadf511ad161c4284ed84e7af98a22c23dbd3353df6f275d3303ec1d26f347`).
- `package-lock.json`: lockfileVersion 1 → 3, `git diff --stat` 4177 lines (2822 insertions, 1355 deletions), new
  sha256 `ce2466cf30183261db32488247f34a1ebb12cec3d959fd87cdc6a5b0165c9d6c`.
- Lockfile entries: 510 before (v1 `dependencies`, flattened to `node_modules/...` paths), 510 after (v3 `packages`);
  none added, none removed; exactly four versions changed:

| entry | before | after |
|---|---|---|
| `node_modules/ajv` | 6.12.6 | 6.15.0 |
| `node_modules/crypto-js` | 4.1.1 | 4.2.0 |
| `node_modules/lodash` | 4.17.21 | 4.18.1 |
| `node_modules/qs` | 6.5.3 | 6.5.5 |

## `npm ls --all --json --package-lock-only`, before and after
Before: 815 tree entries, no problems. After: 834 entries, problem `invalid: webpack@5.77.0`. Changed entries: the
four packages above at every place they occur (`ajv` 6.12.6 → 6.15.0 under `eslint`, `@eslint/eslintrc`,
`request/har-validator`, `webpack/schema-utils`, `worker-loader/schema-utils`; `lodash` 4.17.21 → 4.18.1 under `async`,
`jsdoc/@jsdoc/salty`, `jsdoc/catharsis`, `jsdoc/requizzle`, `request-promise/request-promise-core`, `webpack-merge`;
`qs` under `request`; `crypto-js` at the top), plus 19 entries that only the after-view shows. These 19 are
peer-dependency edges, which a v1 lockfile does not record: `@babel/core` (under `@babel/helper-compilation-targets`,
`babel-loader`), `webpack` 5.77.0 (under `babel-loader`, `webpack-cli`, `@webpack-cli/configtest`,
`terser-webpack-plugin`, `worker-loader`), `webpack-cli` 4.10.0 (under the three `@webpack-cli/*`), `eslint` 8.21.0,
`acorn` 8.8.0 (2), `markdown-it` 12.3.2, `@types/markdown-it` 12.2.3, `request` 2.88.2 (2), `browserslist` 4.21.3,
`ajv` 6.15.0 (under `ajv-keywords`). Every one of them is a package version that is already in the tree (`ajv`
at its new version), and every one appears in `npm ls --all --json` of the actually installed tree at `9d022ded`
(`~/tmp/zeph-r5/zjs` after `npm ci`), which reports the same `invalid: webpack@5.77.0`. No package is added or removed.

## `npm ci` with the pinned lockfile fails
`npm ci` in the scratch clone with the new lockfile: **exit 1, `ERESOLVE could not resolve`**:
```
npm error While resolving: worker-loader@2.0.0
npm error Found: webpack@5.77.0
...
npm error Could not resolve dependency:
npm error peer webpack@"^3.0.0 || ^4.0.0-alpha.0 || ^4.0.0" from worker-loader@2.0.0
...
npm error Fix the upstream dependency conflict, or retry
npm error this command with --force or --legacy-peer-deps
```
With the original v1 lockfile `npm ci` succeeds (509 packages): npm cannot check peer dependencies that v1 does not
record. The v3 lockfile records the peer range of `worker-loader` 2.0.0 (a dev dependency), which webpack 5 does not
satisfy, so `npm ci` refuses. The conflict exists at `9d022ded` already; the format change makes npm enforce it.
`npm ci --legacy-peer-deps` with the pinned lockfile: exit 0, 509 packages, `crypto-js` 4.2.0, `ajv` 6.15.0,
`lodash` 4.18.1, `qs` 6.5.5 installed.

## The worker bundle and the pins
`dist/monero_web_worker.js` bundles `crypto-js`, `ajv`, `lodash` (12 helper modules) and `qs` (see
`../../wasm/2026-11-07/set-2026-11-07-dist.md`). Built from the pinned install (`--legacy-peer-deps`) with the same four
release-set files: exit 0, and `monero_web_worker.js` (`c0da6e55d9f9d6bc…`) and its `.map` (`5ddc24ed10164c16…`)
differ from the bundle built from the `9d022ded` lockfile (`923f551c…`, `ae2b5afe…`); the `.LICENSE.txt` is the same.
The visible differences are in the `ajv` code. So the pinned versions reach the shipped bundle only if the bundle is
built after the pin.

## Where the packages are used (for the advisories' impact)
- `crypto-js`: zephyr-javascript calls only `CryptoJS.MD5` (`src/main/js/common/HttpClient.js` lines 437 to 439, HTTP
  digest authentication). No call to `PBKDF2` in `src/main/js` (GHSA-xwcq-pm8m-c4vf concerns PBKDF2's defaults).
- `lodash`: no direct use in `src/main/js`; the bundle contains only the 12 helper modules listed above; `template`,
  `unset`, `omit` and `pullAt` (GHSA-r5fr-rjxr-66jc, GHSA-xxjr-mmjv-4gpg) are not in the bundle. Other users are dev
  tools (`jsdoc`, `webpack-merge`) and `request-promise-core` / `async` in Node.
- `ajv`: no direct use in `src/main/js`; bundled through `request` → `har-validator`, which creates
  `new Ajv({ allErrors: true })` without the `$data` option (GHSA-2g4f-4pwh-qvx6 needs `$data`).
- `qs`: through `request`; 6.5.5 does not close GHSA-6rw7-vpxm-498p (needs 6.14.1) or GHSA-4mjr-xmp4-gh2g (needs 6.16.0).

## npm 6, lockfile v1 (round 18, 2026-11-07)
Fresh clone `~/tmp/zeph-r5/zjs-pin6` at `9d022ded`. `npx -y npm@6 --version`: `6.14.18` (Node v22.23.4). Lockfile
tree view before (npm 10, `npm ls --all --json --package-lock-only`): identical to the round-17 before-view; npm 6's own
`ls` reads only `node_modules` and cannot view a lockfile.

`npx -y npm@6 audit fix --package-lock-only`: exit 0. npm prints "This endpoint is being retired. Use the bulk
advisory endpoint instead" (npm 6 uses the legacy audit endpoint), then `+ ajv@6.15.0`, `+ jsdoc@4.0.5`,
`+ @babel/core@7.29.13`, `+ webpack@5.112.2`, "fixed 88 of 140 vulnerabilities in 512 scanned packages". Result:
- `package.json` **changed**: ranges `ajv` `^6.12.6` → `^6.15.0`, `@babel/core` `^7.15.0` → `^7.29.13`, `jsdoc`
  `^4.0.0` → `^4.0.5`, `webpack` `^5.76.0` → `^5.112.2`.
- `package-lock.json`: lockfileVersion stays 1, but 198 entries changed, added or removed (510 → 558 entries), almost
  all dev dependencies. Of the production entries only `ajv` 6.12.6 → 6.15.0 and `lodash` 4.17.21 → 4.18.1 change;
  **`crypto-js` stays 4.1.1 and `qs` 6.5.3**.

Measured once more, not part of the work order and not used: `npx -y npm@6 audit fix --package-lock-only --only=prod`
(the npm 6 form of `--omit=dev`): exit 0, "fixed 5 of 140"; `package.json` changed (`ajv` range); lockfile 510 → 510
entries, two changes (`ajv` 6.15.0, `lodash` 4.18.1); `crypto-js` and `qs` unchanged again.

**Outcome: no pin (R17-1 option a).** npm 6 does not produce a v1 lockfile with the four versions while leaving
`package.json` alone: it changes `package.json` in both forms, and its audit data does not move `crypto-js` (the
critical one) or `qs`. The npm 10 form gives the four versions but a v3 lockfile on which `npm ci` fails (above).
`npm ci` with npm 10 on the npm 6 lockfile was not tried, since the lockfile already failed the conditions.
The worker bundle in the artefact commit is therefore built from the unpinned install at `9d022ded`.
