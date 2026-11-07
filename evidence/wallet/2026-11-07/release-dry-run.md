# zephyr-wallet release dry run at the tag (round 21, 2026-11-07)

Fresh clone `~/tmp/zeph-r7/zw` of the zephyr-wallet fork at tag `v2.3.0-sec.1` (`git tag -v`: good signature, release
key, tagger `zephyr-backports`; commit `edef8c0ee`, commit time `1794065184` = 2026-11-07 15:26:24 +0000).
Environment: `REACT_APP_NET_TYPE_ID=0`, `ZEPHYR_DESKTOP_DEVELOPMENT=false`, `NODE_INSTALLER=npm`, `CI=false`; Node
v16.20.2 (`npx -y -p node@16`) with npm 10.9.9 (support warning once per command); git over https in the
environment only. `npm ci` without `--ignore-scripts`, as the workflow runs it (install scripts run; Electron's
postinstall downloads its binary).

| artefact | result | size | sha256 | duration |
|---|---|---|---|---|
| web tarball A `zephyr-wallet-web-v2.3.0-sec.1.tar.gz` | built | 9712868 B (194 entries; `build/` 31912855 B) | `d40d6f8c2caec971dd46e5325e81799acbd18cc59abf002bc53e77d159454f6a` | `npm ci` 25 s, build 78 s |
| web tarball B (only `build/` removed) | built | 9712868 B | `d40d6f8c…` (equal) | build 30 s (warm cache) |
| web tarball C (extra: `build/` and `node_modules/.cache` removed) | built | 9712868 B | `d40d6f8c…` (equal) | build 85 s |
| Linux desktop: packaged app `out/Zephyr-linux-x64/` | built | 298128941 B | — | `npm ci` 22 s, `make` 17 s until the failure |
| Linux deb | **failed** (umask) | — | — | — |

## 1. Web tarball, twice
`client/`: `npm ci` exit 0 (1902 packages); `npm run build:web:ci` exit 0, "Compiled with warnings" (the ESLint warnings
of round 20). Tar command of the draft: `SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)`, `tar --sort=name
--mtime="@${SOURCE_DATE_EPOCH}" --owner=0 --group=0 --numeric-owner -C client -cf - build | gzip -n -9`.
- A and B: same sha256; `diff -r` of the two `build/` trees: no output. B reused `node_modules/.cache` (babel-loader,
  terser-webpack-plugin, 49M) from A, so a third build C ran with the cache removed (a CI runner builds cold): same
  sha256, `build/` identical to A.
- `build/` contains no absolute path of the build machine (`grep -rl` for the home directory and the work dir: 0
  files; the seven source maps use relative paths), so the hash should not depend on the checkout path. The CI run will
  show that (a second builder).
- **Reproducible on one machine: yes** (warm and cold cache). Tarball A kept as `~/tmp/zeph-r7/web-A.tar.gz`.
- The chunk names differ from round 20's web build (`main.9cb96aba` here, `main.75d545c1` there): round 20 did not set
  `REACT_APP_NET_TYPE_ID`, which ends up in the bundle; expected, not compared further.

## 2. Linux desktop
- `client/`: `npm run build:desktop:ci` exit 0, 61 s (`.env.desktop`: `REACT_APP_PLATFORM=desktop`, `BROWSER=none`,
  `INLINE_RUNTIME_CHUNK=false`; `.env.desktop.build`: `PUBLIC_URL=./.`, `GENERATE_SOURCEMAP=false`).
- `npm run copy-build` (= `rm -rf ../zephyr-desktop-app/client && rm -rf ./build/{ZephyrWebWorker*,zephyr*} && cp -rf
  ./build ../zephyr-desktop-app/client`): exit 0. What the `rm -rf` lines remove: the first, nothing (no
  `zephyr-desktop-app/client` in a fresh clone; the path is ignored by git); the second, nothing: `build/` has no
  `ZephyrWebWorker*` or `zephyr*` entry, and npm runs the script with `/bin/sh` = dash, which does not expand braces
  anyway. `zephyr-desktop-app/client` is afterwards identical to `client/build` (`diff -r`).
- `zephyr-desktop-app/`: `npm ci` exit 0 (1024 packages, Electron 22.0.2 downloaded into `node_modules/electron/dist`).
- `npm run make` (= `npm run build && electron-forge make`; `@electron-forge/cli` ^6.4.2, `electron-installer-debian`
  3.2.0): `tsc` OK, system checks OK (git 2.47.3, node 16.20.2, npm 10.9.9), make targets resolved to `deb` only
  (squirrel is win32, dmg and zip darwin); packaging for x64 on linux **succeeded** (`out/Zephyr-linux-x64/`); the deb
  maker **failed**, exit 1, after 17 s. The log from "Making distributables" to the end, verbatim (the npm support
  warning removed, the home directory written as `~`):
```
[STARTED] Making distributables
[STARTED] Making a deb distributable for linux/x64
The current umask, 7, is not supported. You should use 0022 or 0002
[FAILED] Command failed with a non-zero return code (2):
[FAILED] fakeroot dpkg-deb --build /tmp/user/1000/electron-installer--2298875-CyhxgI7bzuRK/zephyr_2.3.0_amd64
[FAILED] 
[FAILED] dpkg-deb: error: control directory has bad permissions 770 (must be >=0755 and <=0775)
[FAILED] Command failed with a non-zero return code (2):
[FAILED] fakeroot dpkg-deb --build /tmp/user/1000/electron-installer--2298875-CyhxgI7bzuRK/zephyr_2.3.0_amd64
[FAILED] 
[FAILED] dpkg-deb: error: control directory has bad permissions 770 (must be >=0755 and <=0775)

An unhandled rejection has occurred inside Forge:
Error: Command failed with a non-zero return code (2):
fakeroot dpkg-deb --build /tmp/user/1000/electron-installer--2298875-CyhxgI7bzuRK/zephyr_2.3.0_amd64

dpkg-deb: error: control directory has bad permissions 770 (must be >=0755 and <=0775)
at ChildProcess.<anonymous> (~/tmp/zeph-r7/zw/zephyr-desktop-app/node_modules/electron-installer-debian/node_modules/@malept/cross-spawn-promise/dist/src/index.js:99:24)
    at ChildProcess.emit (node:events:513:28)
    at ChildProcess.emit (node:domain:489:12)
    at maybeClose (node:internal/child_process:1100:16)
    at Socket.<anonymous> (node:internal/child_process:458:11)
    at Socket.emit (node:events:513:28)
    at Socket.emit (node:domain:489:12)
    at Pipe.<anonymous> (node:net:301:12)
```
  The lines before it (system checks, `tsc`, packaging) all end in `[SUCCESS]`; the full log is kept on the VM as
  `~/tmp/zeph-r7/desktop-make.log` (77 lines). Cause: the umask of this machine's shell is `007`; electron-installer-debian creates its staging tree with
  that umask, and `dpkg-deb` refuses a control directory that is not world-readable. Not a property of the fork's
  config. `out/make/deb/x64/` stays empty; the staging directory was removed by the tool. Stopped here as ordered (no
  re-run with another umask, no config change): question R21-1.

## 3. What the deb contains: not possible without a deb
Established from the packaged app `out/Zephyr-linux-x64/`, which is what electron-installer-debian puts into the deb:
- binary `zephyr` (`packagerConfig.executableName` on linux); Electron files beside it (`chrome-sandbox`,
  `resources/`, `locales/`, …); `resources/app/` unpacked (asar off): `client/`, `dist/`, `icons/`, `node_modules/`,
  `package.json`, `sites/`, `__tests__/` (the ignore list does not exclude `__tests__` and `sites`).
- `resources/app/node_modules/zephyr-javascript/dist/monero_wallet_full.wasm` and
  `resources/app/client/monero_wallet_full.wasm`: both `c984b999dd76550ab8135a0d7ddfd34b5fc7774200f8887aaa5f4984a7c7b1e4`
  (the artefact); `resources/app/client/monero_web_worker.js` `923f551c…`.
- `zephyr-node/`: absent.
- icon `zephyr-desktop-app/icons/icon.png` (the deb maker's `icon`): PNG 256×256.
Not established: the control fields, the install paths, the `.desktop` file, the icon's install location.

## 4. Does it start?
`Xvfb` and `xvfb-run` are present. Since there is no deb, the same binary was started from the packaged app (not
from an extracted deb): `HOME` and `XDG_CONFIG_HOME` set to `~/tmp/zeph-r7/run-home` so that nothing is written into the
real home directory; `timeout 15 xvfb-run -a ./zephyr --no-sandbox`. It ran until the timeout (exit 124); on SIGTERM it
printed `on App quit called` (stdout). stderr, 7 lines (process-id and time prefixes dropped):
```
libva error: vaGetDriverNames() failed with unknown libva error
ERROR:viz_main_impl.cc(186)] Exiting GPU process due to errors during initialization
libva error: vaGetDriverNames() failed with unknown libva error
ERROR:gpu_memory_buffer_support_x11.cc(44)] dri3 extension not supported.
ERROR:command_buffer_proxy_impl.cc(128)] ContextResult::kTransientFailure: Failed to send GpuControl.CreateCommandBuffer.
(node:…) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 connect listeners added to [Socket]. Use emitter.setMaxListeners() to increase limit
(Use `zephyr --trace-warnings ...` to show where the warning was created)
```
The GPU lines are expected under Xvfb without a GPU. The `MaxListenersExceededWarning` shows a socket in the main
process collecting `connect` listeners (repeated connection attempts); which socket and to which address was not
established. No line about the WASM or the worker (assessment, not checked: the WASM is loaded only when a wallet
is created or opened, which this run does not do). The app created `.config/Zephyr/` with `wallets/`, `Local Storage/`, `Preferences` and caches in the
temporary home.

## Round 22: the deb (2026-11-07)
`( umask 0022 && npm run make )` in `~/tmp/zeph-r7/zw/zephyr-desktop-app`, one subshell, same environment as round 21,
nothing else changed; the shell's umask stays `007` outside the subshell. Exit 0, 55 s (`tsc`, packaging, deb). Log
`~/tmp/zeph-r7/desktop-make-2.log`: no `[FAILED]` line; the deb maker ends with
`[SUCCESS] Making a deb distributable for linux/x64`.

| artefact | path | size | sha256 |
|---|---|---|---|
| deb | `out/make/deb/x64/zephyr_2.3.0_amd64.deb` | 80244968 B | `65ab720a849350a5b71cdcb36aef8edf20524dbf428ddb0f704268997461e521` |

The only file under `out/make/`. Electron installers are not expected to reproduce byte for byte (archive timestamps,
staging paths), and this deb is in addition not representative (file modes, below): its hash is a fact about this
build, not a reference for the CI deb.

### Control fields (`dpkg-deb -I`)
`Package: zephyr`, `Version: 2.3.0`, `Section: utils`, `Priority: optional`, `Architecture: amd64`, `Installed-Size: 292774`,
`Maintainer: Zephyr Team <zephyrcurrencyprotocol@gmail.com>`, `Description: Desktop App for Zephyr Wallet`;
`Depends: libgtk-3-0, libnotify4, libnss3, libxtst6, xdg-utils, libatspi2.0-0, libdrm2, libgbm1, libxcb-dri3-0,
kde-cli-tools | kde-runtime | trash-cli | libglib2.0-bin | gvfs-bin`; `Recommends: pulseaudio | libasound2`;
`Suggests: gir1.2-gnomekeyring-1.0, libgnome-keyring0, lsb-release`. Members: `debian-binary`, `control.tar.xz`, `data.tar.xz`.

### Paths (`dpkg-deb -c`, 5681 entries) against round 21's reading of the maker's source: equal
`/usr/lib/zephyr/` (Electron files, `zephyr` binary, `chrome-sandbox` setuid, `resources/app/` with `__tests__`, `client`,
`dist`, `icons`, `node_modules`, `package.json`, `sites`), `/usr/bin/zephyr -> ../lib/zephyr/zephyr`,
`/usr/share/applications/zephyr.desktop`, `/usr/share/pixmaps/zephyr.png`, `/usr/share/doc/zephyr/copyright` (Electron's
licence), `/usr/share/lintian/overrides/zephyr`. No hicolor icons. `zephyr-node/` absent (no path contains it).
`zephyr.desktop`, verbatim:
```
[Desktop Entry]
Name=zephyr
Comment=Desktop App for Zephyr Wallet
GenericName=Zephyr
Exec=zephyr %U
Icon=zephyr
Type=Application
StartupNotify=true
Categories=GNOME;GTK;Utility;
```
Icon: `/usr/share/pixmaps/zephyr.png`, PNG 256×256, byte-equal to `zephyr-desktop-app/icons/icon.png`.
WASM (`dpkg-deb -x`): `usr/lib/zephyr/resources/app/node_modules/zephyr-javascript/dist/monero_wallet_full.wasm` and
`usr/lib/zephyr/resources/app/client/monero_wallet_full.wasm`: both `c984b999dd76550ab8135a0d7ddfd34b5fc7774200f8887aaa5f4984a7c7b1e4`.

### File modes: this deb would not work for other users
`dpkg-deb -c` modes: Electron's files under `/usr/lib/zephyr/` (64 × `0644`, 7 × `0755`, `chrome-sandbox` `4755`) and the
files the maker writes itself (desktop file, pixmap, copyright, overrides) are right. **Everything under
`resources/app/`** (5118 files `0660`, 84 `0770`, 388 directories `0770`; owner root) is not readable by others: that tree
(`node_modules/`, `client/` from `copy-build`, `dist/` from `tsc`) was created in round 21 with this machine's umask `007`,
and electron-packager copies it with its modes; the subshell's `umask 0022` covers only what `make` itself creates.
Installed with dpkg, a normal user could not read the app and it would not start; the Xvfb run below ran as the owner of
the files and does not show this. A deb built with umask 0022 from the first `npm ci` on would not have this; the
workflow sets `umask 0022` only for the make step (question R22-1).

### Start of the extracted binary
`HOME`/`XDG_CONFIG_HOME` in `~/tmp/zeph-r7/run-home-2`; `timeout 15 xvfb-run -a usr/lib/zephyr/zephyr --no-sandbox`: ran until
the timeout (exit 124); stdout empty; stderr (prefixes dropped) as in round 21: the libva / GPU-process / dri3 /
command-buffer errors of a headless X server, and `MaxListenersExceededWarning: Possible EventEmitter memory leak
detected. 11 connect listeners added to [Socket]`. Nothing about the WASM or the worker.

### The socket that retries at start (from the source)
`zephyr-desktop-app/src/dev.ts` creates a `net.Socket` at module level and calls `tryConnection()` on import:
`client.connect({ port: 3000 }, …)` with no host, i.e. `localhost:3000` (the port of the CRA dev server); on `error` it
retries after 1 s (`setTimeout(tryConnection, 1000)`), without end and without a check of the mode. Every `connect()` with a
callback adds a `connect` listener; after 11 attempts (about 10 s) Node warns. `src/index.ts` imports `./dev`
unconditionally (`import { startInDevMode } from "./dev"`; compiled `dist/index.js` line 30 `require("./dev")`), so it runs
in the packaged app too, although `dist/env.js` has `isDevMode = false` there and the result (`devServerStarted`) is used only
by `startInDevMode`, which `index.ts` calls only in dev mode. Effect in a release build: one loopback connection attempt per
second to port 3000 for as long as the app runs, and a growing listener list; if any local process listens on port 3000,
the app opens a TCP connection to it (and sends nothing; it does not load from it outside dev mode). No other connection
at module level in the main process: the daemon RPC (`src/shared/zephyrd.ts`) and the local node
(`src/localNode/`) start only on IPC requests from the renderer; the menu's links open only on a click. The client's
`env/.env.*` files hold no address; `client/.env` (tracked) sets `REACT_APP_ZEPHYR_DIRECT_HOST=localhost:3000`, which the
renderer uses in `src/platforms/web/nodes.ts` (`webWalletConnection()`, called from `walletCreation.ts`) as the node URI of
the **web** platform when a wallet is created or opened: not the main process and not the start screen (side observation,
not analysed further; the value is in the round-20 web bundle). Upstream's code, out of scope here (application code).

### Flatpak manifest against the deb
All paths in `tools/release/flatpak/dev.lateo.zephyr.yml` match the deb (binary, app tree, pixmap, desktop file); the icon
size 256×256 is right. The eight build commands were run as a shell script against the deb with `/app` replaced by a
scratch directory: all succeed; the edited desktop file (`Exec=zephyr-wallet %U`, `Icon=dev.lateo.zephyr`) passes
`desktop-file-validate`. No path change; the header now says what was checked. Not checked: the flatpak build, the runtime,
the finish-args.

## Round 23: a representative deb (2026-11-07)
The linux job of `tools/release/build-wallet.yml` (the reviewer's version with `umask 0022` in the client-build and make
steps and the step "Every entry of the deb must be world-readable"; file sha256 `320fab616feaa8fc…`), run locally.

### Task 1: fresh clone, the job's run steps under umask 0022
`git clone ~/github/zephyr-backports/zephyr-wallet ~/tmp/zeph-r7/zw2 && git -C … checkout --detach v2.3.0-sec.1`:
`HEAD` `edef8c0ee281024de1a718aa6dce39bce75f3687`, `git describe --tags --exact-match` `v2.3.0-sec.1`. The clone ran, as the
work order puts it, before the subshell, i.e. under this machine's umask `007`: the checked-out files are `0660`/`0770`
(`zephyr-desktop-app/package.json` 660, `icons/icon.png` 660, `client/public/monero_wallet_full.wasm` 770, `sites/` 770).
Then one subshell, `umask 0022` first (`umask` printed `022`), Node 16.20.2 with npm 10.9.9, `REACT_APP_NET_TYPE_ID=0
ZEPHYR_DESKTOP_DEVELOPMENT=false NODE_INSTALLER=npm CI=false`: in `client/` `npm ci`, `npm run build:desktop:ci`,
`npm run copy-build`; in `zephyr-desktop-app/` `npm ci`, `npm run make`. Exit 0, 149 s; log `~/tmp/zeph-r7/zw2-build.log`.

| build | clone under | deb | size | sha256 (not a reference) | check |
|---|---|---|---|---|---|
| round 22 (`zw`) | umask 007, builds 007, make 0022 | `zw/…/zephyr_2.3.0_amd64.deb` | 80244968 B | `65ab720a849350a5…` | exit 1, 5590 entries |
| round 23 (`zw2`, the work order) | umask 007, all steps 0022 | `zw2/zephyr-desktop-app/out/make/deb/x64/zephyr_2.3.0_amd64.deb` | 80246760 B | `37fb46978120084fe7c7977acb6e3d3676e991e58a2bd1c5f7d73b0ac60ff43e` | **exit 1, 175 entries** |
| extra (`zw3`) | umask 0022, all steps 0022 | `zw3/zephyr-desktop-app/out/make/deb/x64/zephyr_2.3.0_amd64.deb` | 80263008 B | `d5e11ef15b5573dd74b95644abf93935afa99245f8c90f42c9f90be1a6bf37d6` | **exit 0** |

### Task 2: the check on both debs (and on the extra one)
The step's script, taken from the YAML with js-yaml (verbatim), run in `zephyr-desktop-app/` of each tree:
- round-22 deb: prints the entries, then `5590 entries are not world-readable`, **exit 1** (as expected).
- new `zw2` deb: `175 entries are not world-readable`, **exit 1** (expected: no output, exit 0). All 175 trace back to files
  `git checkout` wrote under umask 007: 27 entries copied directly by the packager with the checkout modes (`resources/app/`
  itself, `sites/` 15, `icons/` 8, `__tests__/` 2, `package.json`: `0660`/`0770`) and 148 that CRA copied from
  `client/public/` into the build (`pwa/` 111, `favicon/` 28, the seven `monero_*` files, `nodes.json`, `manifest.json`:
  `0640`/`0750`, the checkout mode under umask 0022). Everything `npm ci`, `tsc` and the builds created is right.
- extra `zw3` deb (clone also inside the umask 0022 subshell, the same steps): **exit 0**, no output.
So the check works both ways, and the step's two `umask 0022` lines cover what the build creates but not the checkout:
in CI, `actions/checkout` writes the tree under the runner's default umask (question R23-1).

Mode histogram of the `zw2` deb (`dpkg-deb -c | awk '{print substr($1,1,10)}' | sort | uniq -c`):
```
    138 -rw-r-----
   5029 -rw-r--r--
     19 -rw-rw----
      1 -rwsr-xr-x
      2 -rwxr-x---
     89 -rwxr-xr-x
      8 drwxr-x---
    386 drwxr-xr-x
      8 drwxrwx---
      1 lrwxrwxrwx
```
and of the `zw3` deb: `5186 -rw-r--r--`, `91 -rwxr-xr-x`, `402 drwxr-xr-x`, `1 -rwsr-xr-x`, `1 lrwxrwxrwx`.

Paths (`dpkg-deb -c` without mode, owner, size and date), `zw2` against the round-22 deb: 5681 entries each; `diff` shows
only the content hashes in five file names of the desktop client build
(`client/static/js/0.bf48b0e5.chunk.js` → `0.29350aed`, its `.LICENSE.txt`, `1.fde4084b` → `1.a0980893`, `4.04874dc8` →
`4.4867e99a`, `runtime-main.705e277f` → `runtime-main.c55e9fef`); `5.*` and `main.*` are equal. No other path differs.
WASM in the `zw2` deb (`dpkg-deb -x`): `usr/lib/zephyr/resources/app/node_modules/zephyr-javascript/dist/monero_wallet_full.wasm`
and `usr/lib/zephyr/resources/app/client/monero_wallet_full.wasm` both `c984b999dd76550ab8135a0d7ddfd34b5fc7774200f8887aaa5f4984a7c7b1e4`.
`zephyr-node`: no path contains it.

### Extra: the client build is not identical across checkouts, and the web tarball carries the builder's modes
- The five chunk names above differ because their content differs: no absolute path is in the chunks; the runtime chunks
  differ in minifier names and order (`c=r[1]`/`l=r[2]` against `l=r[1]`/`c=r[2]`), and the vendor chunk `0.*` has exactly the
  same size in both web builds compared below (2815473 bytes). The cause was not analysed further.
- The same holds for the **web** build: in `zw3` (umask 0022 throughout) `npm run build:web:ci` and the workflow's tar
  command give `~/tmp/zeph-r7/web-zw3.tar.gz`, sha256 `84e650bc96317521d5739b596a9f3cfb9cacd4cd324c406d9dedd56ab1d42661`;
  `diff -r` against round 21's `build-A/` (checkout `zw`): `main.9cb96aba.chunk.js` equal, but `0.*`, `1.*`, `4.*`,
  `runtime-main.*` (and so `index.html` and `asset-manifest.json`) differ. Round 21 built three times in one checkout with
  one hash; across checkouts on the same machine the bundle differs.
- The workflow's tar command fixes owner, group and mtime, not the modes: `web-A.tar.gz` (built under umask 007) holds 180
  `-rw-rw----`, 2 `-rwxrwx---`, 12 `drwxrwx---`; `web-zw3.tar.gz` holds 180 `-rw-r--r--`, 2 `-rwxr-xr-x`, 12 `drwxr-xr-x`.
  A tarball's hash therefore depends on the builder's umask as well.
- For runbook §6 (CI tarball against `web-A.tar.gz`): expect "different", for both reasons; `web-A` is not a usable
  reference (question R23-2).

### Task 3: the two workflow copies
`cmp tools/release/build-wallet.yml fork-files/zephyr-wallet/.github/workflows/build-wallet.yml`: equal (sha256
`320fab616feaa8fc0f98e742d031da5d465644f976c564809c15bab243fabb44`). js-yaml 3.14.1: parses; 6 jobs, 20 named steps, no step
name containing a colon; no tabs; the round-13 grep finds nothing. Not edited.

## Round 24: the checkout modes and the tarball modes (2026-11-07)
The workflow with the reviewer's two changes (file sha256 `a8c4bb82ea6b6344…`): the step "Checkout readable by everyone
(the packager copies these modes into the installer)", `chmod -R u+rwX,go+rX,go-w .`, first in the linux job (also in the mac
job, not run here), and `--mode='u+rwX,go+rX,go-w'` in the web job's tar command. Both verified on a tree checked out under
this machine's umask `007`, the case that failed in round 23. Steps taken from the YAML with js-yaml and run verbatim,
each with `bash -e` as GitHub runs them.

### Task 1: the linux job on a 007 checkout
`git clone ~/github/zephyr-backports/zephyr-wallet ~/tmp/zeph-r7/zw4 && git -C … checkout --detach v2.3.0-sec.1` in the plain
shell (umask `007`): `HEAD` `edef8c0ee281024de1a718aa6dce39bce75f3687`. Checkout modes: `zephyr-desktop-app/package.json` 660,
`icons/icon.png` 660, `client/public/monero_wallet_full.wasm` 770, `client/public/nodes.json` 660, `zephyr-desktop-app/sites` 770,
`client/public/pwa` 770; 792 entries outside `.git` not readable by others.
The four run steps of the linux job, in order, each in its own `( umask 0022 && cd <working-directory> && bash -e <step> )`,
Node 16.20.2 with npm 10.9.9, job env `REACT_APP_NET_TYPE_ID=0 ZEPHYR_DESKTOP_DEVELOPMENT=false NODE_INSTALLER=npm CI=false`;
log `~/tmp/zeph-r7/zw4-build.log`:

| step | working directory | exit | duration |
|---|---|---|---|
| Checkout readable by everyone | `.` | 0 | 1 s |
| Client build for desktop, copied into the desktop app | `client` | 0 | 103 s |
| Make deb | `zephyr-desktop-app` | 0 | 88 s |
| Every entry of the deb must be world-readable | `zephyr-desktop-app` | **0, no output** | 3 s |

After the chmod step the same files are 644 / 644 / 755 / 644 / 755 / 755, and 0 entries outside `.git` are not readable by
others (the step also touches `.git/`, e.g. `.git/HEAD` 660 → 644; harmless). Total 195 s.
Deb: `out/make/deb/x64/zephyr_2.3.0_amd64.deb` (the only file), 80247136 B, sha256
`c7851d24180c50585b67da2d7bbe42b8ce700583c4d43db87dfd2256d7750464` (not a reference). Mode histogram, identical to the `zw3`
deb of round 23 (clone and build under 0022):
```
   5186 -rw-r--r--
      1 -rwsr-xr-x
     91 -rwxr-xr-x
    402 drwxr-xr-x
      1 lrwxrwxrwx
```
Both WASM copies (`resources/app/node_modules/zephyr-javascript/dist/` and `resources/app/client/`):
`c984b999dd76550ab8135a0d7ddfd34b5fc7774200f8887aaa5f4984a7c7b1e4`. `zephyr-node`: no path contains it. Path list against the
`zw3` deb with the content hashes in `static/js/` file names masked: 5681 entries each, equal; unmasked, only the five
desktop chunk names differ (`0.*` and its `.LICENSE.txt`, `1.*`, `4.*`, `runtime-main.*`), as across checkouts in round 23.

### Task 2: the tar option on a 007 tree
In `zw4/client`, plain shell, umask `007`: `npm run build:web:ci` exit 0 (76 s). `build/` modes before tar: 138 `644`, 10 `755`
(copied from `public/`, corrected by the chmod step) and 42 `660`, 4 `770` (created by the build under 007). The web job's
tar step verbatim (`TAG=v2.3.0-sec.1`, with `--mode`), exit 0, moved to `~/tmp/zeph-r7/web-zw4.tar.gz`:
sha256 `2fdedd97567ee5a4dc6d0bb21a8f90eb578cea954bcc5ba1ae1670e31773a491`; `tar -tvzf`: 180 `-rw-r--r--`, 2 `-rwxr-xr-x`, 12
`drwxr-xr-x`, nothing else. The same command without `--mode` on the same build (`web-zw4-nomode.tar.gz`, `b5f937bdc98f3307…`):
138 `-rw-r--r--`, 42 `-rw-rw----`, 2 `-rwxr-xr-x`, 8 `drwxr-xr-x`, 4 `drwxrwx---`. The option is what makes the modes
independent of the builder's umask.
`diff -rq` of the unpacked `web-zw4` tree against `web-zw3.tar.gz` (`84e650bc…`): 20 entries, the same kind as round 23: the
chunks `0.*` (with `.LICENSE.txt` and `.map`), `1.*`, `4.*` and `runtime-main.*` (with their maps) under other content hashes,
and the two files that name them (`asset-manifest.json`, `index.html`); `main.9cb96aba.chunk.js` equal; every other file equal.

### Task 3: the copies
`cmp tools/release/build-wallet.yml fork-files/zephyr-wallet/.github/workflows/build-wallet.yml`: equal (sha256
`a8c4bb82ea6b6344b5a6851981e198e0daa5df6beb79344108223c386431cf0a`). js-yaml 3.14.1: parses; 6 jobs, 22 named steps, no step
name with a colon; no tabs; the round-13 grep finds nothing. Not edited.

## Round 26: AppImage from the deb (2026-11-07)
An AppImage built from the round-24 deb only (`~/tmp/zeph-r7/zw4/zephyr-desktop-app/out/make/deb/x64/zephyr_2.3.0_amd64.deb`,
80247136 B, sha256 `c7851d24180c50585b67da2d7bbe42b8ce700583c4d43db87dfd2256d7750464`, re-checked before use). No fork
change, nothing pushed. Work dir `~/tmp/zeph-r7/appimage/`; every command below ran there, the shell's umask is `007`, so each
step that writes runs under `umask 0022`.

### Tools, pinned
```
mkdir -p ~/tmp/zeph-r7/appimage/tools && cd ~/tmp/zeph-r7/appimage/tools
( umask 0022 && curl -fsSLO https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage \
  && curl -fsSLO https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64 )
chmod 0755 appimagetool-x86_64.AppImage
```

| file | size | sha256 |
|---|---|---|
| `appimagetool-x86_64.AppImage` (appimagetool release 1.9.1) | 15092216 B | `ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0` |
| `runtime-x86_64` (type2-runtime release 20251108) | 944632 B | `2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d` |

Both sizes as in the work order; both hashes equal to the `digest` GitHub's release API (unauthenticated
`api.github.com/repos/AppImage/<repo>/releases/tags/<tag>`) gives for the asset. Release dates from the same API:
appimagetool 1.9.1 published 2025-11-18T17:47:57Z; type2-runtime `20251108` published 2025-12-08T17:50:07Z.
`./appimagetool-x86_64.AppImage --appimage-extract-and-run --version`:
`appimagetool, continuous build (git version 8c8c91f), build 296 built on 2025-12-04 17:55:56 UTC`. The binary says it was
built 16 days after the release was published, so the asset was uploaded after that date; the sha256 pin is what fixes
it. The packed image's runtime reports `AppImage runtime version: https://github.com/AppImage/type2-runtime/commit/dd6cebe`.

### AppRun
`~/tmp/zeph-r7/appimage/src/AppRun`, sha256 `038b2e46ade0bf3cc5ca3f48e3c9b263161375ee8d71325873b8b87090dba831`, verbatim:
```sh
#!/bin/sh
# Starts the Zephyr wallet inside the AppImage. The setuid sandbox helper cannot work in a mounted
# AppImage, so Electron's sandbox needs unprivileged user namespaces. When they are not available
# (disabled, restricted by AppArmor, or no unshare), the wallet is started with --no-sandbox.
# The probe is electron-builder's (app-builder-lib/src/targets/linux/appimage/appImageUtil.ts).
HERE=$(dirname "$(readlink -f "$0")")
BIN="$HERE/usr/lib/zephyr/zephyr"
for arg in "$@"; do
  if [ "$arg" = --no-sandbox ]; then
    exec "$BIN" "$@"
  fi
done
if unshare -Ur true 2>/dev/null; then
  exec "$BIN" "$@"
fi
exec "$BIN" --no-sandbox "$@"
```
`sh -n` passes (shellcheck is not installed). Deviation from the work order: the decision is the probe `unshare -Ur true`
(create a user namespace and map the caller to root in it) instead of reading `/proc/sys/kernel/unprivileged_userns_clone` and `/proc/sys/user/max_user_namespaces`.
Source: electron-builder `master` (`04585d61`, 2026-11-07),
`packages/app-builder-lib/src/targets/linux/appimage/appImageUtil.ts` (last changed in `b98e1f29`, 2026-10-24; file sha256
`78eb3323494ea3d2b7d72c735ae7750dcadfeca2c8e4ec644b40b3e84a7f5ee4`), `generateAppRunScript()`:
`if [ $HAVE_NO_SANDBOX -eq 0 ] && ! unshare -Ur true 2>/dev/null ; then NO_SANDBOX=(--no-sandbox) fi`. Its comment calls a
missing `unshare` (exit 127, so `--no-sandbox`) "an intentional fail-safe". The older AppRun template in develar/app-builder
(`pkg/package-format/appimage/templates/AppRun.sh`, last changed 2019-06-22) has no sandbox logic. electron-builder's
docs (`website/docs/appimage.md`) describe the current behaviour: with the static runtime, AppRun adds `--no-sandbox` "only when
unprivileged user namespaces are unavailable". Why the probe and not the two sysctls: test (d) below. In a namespace where no
further user namespace can be created, the sysctls read `unprivileged_userns_clone=1` and
`max_user_namespaces=2147483647` (the sysctl test would say "allowed"), and the binary without `--no-sandbox` aborts. The
probe should also catch Ubuntu 24.04's AppArmor restriction (`kernel.apparmor_restrict_unprivileged_userns`), which neither
sysctl shows (expected, not verified: that sysctl does not exist on this machine, Debian 13.7, kernel 6.12.115).
Differences from electron-builder's script: POSIX `sh` instead of bash, no `PATH`/`LD_LIBRARY_PATH`/`XDG_DATA_DIRS`
exports (the AppDir has no own libraries), no EULA, no `APPDIR` search loop (the work order's `HERE`).

### AppDir
`~/tmp/zeph-r7/appimage/src/build-appdir.sh` (sha256 `dc37933a23a75b69976bdc7f3be903771da4bf2615dc837efaf175defb84b3da`), run as
`bash ./src/build-appdir.sh` in the work dir, exit 0, verbatim:
```bash
set -e
umask 0022
DEB=~/tmp/zeph-r7/zw4/zephyr-desktop-app/out/make/deb/x64/zephyr_2.3.0_amd64.deb
rm -rf deb-x Zephyr.AppDir
mkdir deb-x
dpkg-deb -x "$DEB" deb-x
mkdir -p Zephyr.AppDir/usr/lib Zephyr.AppDir/usr/share/icons/hicolor/256x256/apps
cp -a deb-x/usr/lib/zephyr Zephyr.AppDir/usr/lib/zephyr
cp deb-x/usr/share/applications/zephyr.desktop Zephyr.AppDir/zephyr.desktop
cp deb-x/usr/share/pixmaps/zephyr.png Zephyr.AppDir/zephyr.png
cp deb-x/usr/share/pixmaps/zephyr.png Zephyr.AppDir/usr/share/icons/hicolor/256x256/apps/zephyr.png
ln -s zephyr.png Zephyr.AppDir/.DirIcon
install -m 0755 src/AppRun Zephyr.AppDir/AppRun
desktop-file-validate Zephyr.AppDir/zephyr.desktop
```
`desktop-file-validate`: no output, exit 0. The desktop file is the deb's byte for byte (`cmp`), so `Exec=zephyr %U` and
`Icon=zephyr` as round 22 shows them, not edited. `deb-x` (5681 entries) has the deb's mode histogram from round 24
(5186 `-rw-r--r--`, 1 `-rwsr-xr-x`, 91 `-rwxr-xr-x`, 402 dirs, 1 symlink). `diff -r deb-x/usr/lib/zephyr Zephyr.AppDir/usr/lib/zephyr`:
equal. AppDir: 5678 entries, 5278 files, 399 directories, 1 symlink (`.DirIcon -> zephyr.png`); 5185 `-rw-r--r--`, 1
`-rwsr-xr-x` (`usr/lib/zephyr/chrome-sandbox`, as in the deb), 92 `-rwxr-xr-x` (the deb's 91 plus `AppRun`), 399
`drwxr-xr-x`. `zephyr.png` sha256 `0c7347f6bccbc2bc58e8fae7939ffe3fa04ee3c990b74e344634a158558dfea3`, PNG 256×256. Both WASM copies
under `usr/lib/zephyr/resources/app/` (`client/` and `node_modules/zephyr-javascript/dist/`):
`c984b999dd76550ab8135a0d7ddfd34b5fc7774200f8887aaa5f4984a7c7b1e4`. Nothing removed from the deb's tree, no other file added.

### Pack
```
( umask 0022 && ARCH=x86_64 ./tools/appimagetool-x86_64.AppImage --appimage-extract-and-run --runtime-file tools/runtime-x86_64 \
  Zephyr.AppDir zephyr-wallet-v2.3.0-sec.1-x86_64.AppImage ) > pack.log 2>&1
```
Exit 0. Log: two warnings (`appstreamcli command is missing`, `AppStream upstream metadata is missing … usr/share/metainfo/zephyr.appdata.xml`),
`Using architecture x86_64`, mksquashfs: `zstd compressed, data block size 131072`, `Number of inodes 5678`, `Number of files
5278`, `Number of directories 399`, `Number of symbolic links 1`, uids and gids `root (0)` only; `Embedding ELF...`,
`Marking the AppImage as executable...`, `Embedding MD5 digest`, `Success`. No update information, no signature.

| artefact | size | sha256 |
|---|---|---|
| `zephyr-wallet-v2.3.0-sec.1-x86_64.AppImage` | 98662904 B | `b3f9ce8796d031352da0b58817ace9da6c86d4e87a9321433ebc5cbcc27d5753` |

`file`: `ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), static-pie linked, BuildID[sha1]=a87aaf5da1bf2ef30becedd1aa58e217818fb503, stripped`.
`--appimage-version`: `AppImage runtime version: https://github.com/AppImage/type2-runtime/commit/dd6cebe`.
`--appimage-offset`: `944632` (the runtime's size).
Contents: `unsquashfs -o 944632 -lls zephyr-wallet-v2.3.0-sec.1-x86_64.AppImage`: 5678 lines, the AppDir's entry count, all
`root/root`, `chrome-sandbox` `-rwsr-xr-x`. `--appimage-extract` into `ex/` (under umask 0022): `squashfs-root` with 5677 entries below it
(5678 with itself), 5278 files; `diff -r --no-dereference Zephyr.AppDir ex/squashfs-root`: equal; both WASM copies
`c984b999…`; same mode histogram as the AppDir.
Mounted with `--appimage-mount`: `/proc/mounts` shows `fuse.zephyr-wallet-v2.3.0-sec.1-x86_64.AppImage ro,nosuid,nodev,relatime,user_id=1000,group_id=1000`;
`chrome-sandbox` there is `root root 4755`, but the mount is `nosuid`, so the helper cannot work. That is why the sandbox depends on user
namespaces.
Repeatability: packing the same `Zephyr.AppDir` a second time gives the same sha256. A second AppDir built with
the same script in `rebuild/` gives a different image (`bd693893…`, 60521 bytes differ; `unsquashfs -lls` listings equal
apart from the times). With `SOURCE_DATE_EPOCH=1762473600` (an arbitrary test value, 2025-11-07T00:00:00Z) set for the pack
command, both AppDirs give the same image, `66ca4a9e5e91afae6edbdfd2cb4cbbce60fcd25da337f41d08af278c4010efe4`, with every
time in the listing set to that value. This was only a test; the artefact above was packed without it.

### Start tests
Harness `src/start-test.sh` (sha256 `574717d8beb1ff8b586c3cc9528b2187d7a4f4a3ef7a1a82c40b8ded52e83171`), verbatim:
```bash
# usage: start-test.sh <name> <command...>; runs the command 15 s under xvfb-run in a fresh HOME,
# records stderr, stdout, exit code and, after 8 s, the command lines of the zephyr processes.
name=$1; shift
out=~/tmp/zeph-r7/appimage/runs/$name
rm -rf "$out"; mkdir -p "$out/home"
( sleep 8; pgrep -a -x zephyr | grep -v -- '--type=' > "$out/main-process.txt" ) &
HOME="$out/home" XDG_CONFIG_HOME="$out/home/.config" timeout 15 xvfb-run -a "$@" > "$out/stdout.txt" 2> "$out/stderr.txt"
echo $? > "$out/exit.txt"
wait
```
To make user namespaces unavailable without root, `src/no-userns.sh` (sha256
`e7923f9ef523e0d04f0499969a3a26210c7d4045b242598901e6ff98b46d0946`) runs the command as the same uid in a user namespace whose
parent allows only one, already used up. Verbatim:
```sh
# usage: no-userns.sh <command...>; runs the command as the same uid in a user namespace in which no
# further user namespace can be created (max_user_namespaces 1, used up by the inner one).
uid=$(id -u); gid=$(id -g)
exec unshare -Ur sh -c 'u=$0; g=$1; shift; echo 1 > /proc/sys/user/max_user_namespaces && exec unshare --user --map-user="$u" --map-group="$g" "$@"' "$uid" "$gid" "$@"
```
Inside it: `id -u` 1000, `unshare -Ur true` gives `unshare: unshare failed: No space left on device` (exit 1). On this machine
outside it: `/dev/fuse` `crw-rw-rw-`, `unprivileged_userns_clone` 1, `max_user_namespaces` 59862, `unshare -Ur true` exit 0.
The commands, all in one `( umask 0022 … )` in the work dir. `shim/unshare` is `#!/bin/sh` plus `exit 1`, outside the AppDir.
```
bash src/start-test.sh base-deb-nosandbox deb-x/usr/lib/zephyr/zephyr --no-sandbox
bash src/start-test.sh a-appimage-fuse ./zephyr-wallet-v2.3.0-sec.1-x86_64.AppImage
bash src/start-test.sh b1-apprun-arg-nosandbox ex/squashfs-root/AppRun --no-sandbox
PATH=$PWD/shim:$PATH bash src/start-test.sh b2-apprun-unshare-fails ex/squashfs-root/AppRun
bash src/start-test.sh b3-apprun-no-userns sh src/no-userns.sh ex/squashfs-root/AppRun
bash src/start-test.sh c-apprun-sandbox ex/squashfs-root/AppRun
bash src/start-test.sh d-binary-sandbox-no-userns sh src/no-userns.sh ex/squashfs-root/usr/lib/zephyr/zephyr
bash src/start-test.sh e-appimage-extract-and-run ./zephyr-wallet-v2.3.0-sec.1-x86_64.AppImage --appimage-extract-and-run
```

| test | what | main process after 8 s | exit | stdout |
|---|---|---|---|---|
| base | the deb's binary, round 22's command | `…/deb-x/usr/lib/zephyr/zephyr --no-sandbox` | 124 | empty |
| (a) | the AppImage as is, FUSE mount | `/tmp/user/1000/.mount_zephyrogEAdk/usr/lib/zephyr/zephyr` (no `--no-sandbox`) | 124 | `on App quit called` |
| (b1) | extracted AppRun, `--no-sandbox` passed | `…/ex/squashfs-root/usr/lib/zephyr/zephyr --no-sandbox` (once) | 124 | `on App quit called` |
| (b2) | extracted AppRun, `unshare` replaced by `exit 1` | `…/ex/squashfs-root/usr/lib/zephyr/zephyr --no-sandbox` | 124 | `on App quit called` |
| (b3) | extracted AppRun, user namespaces really unavailable | `…/ex/squashfs-root/usr/lib/zephyr/zephyr --no-sandbox` | 124 | `on App quit called` |
| (c) | extracted AppRun, user namespaces available | `…/ex/squashfs-root/usr/lib/zephyr/zephyr` (no `--no-sandbox`) | 124 | `on App quit called` |
| (d) | the binary without `--no-sandbox`, user namespaces unavailable | none (aborted) | **133** | empty |
| (e) | the AppImage with `--appimage-extract-and-run` | `/tmp/user/1000/appimage_extracted_18af180f…/usr/lib/zephyr/zephyr` (no `--no-sandbox`) | 124 | `on App quit called` |

stderr, base and (a) to (c), (e) (pid/time prefixes dropped): each has the start lines of round 22, in this order:
`libva error: vaGetDriverNames() failed with unknown libva error`, `ERROR:viz_main_impl.cc(186)] Exiting GPU process due to
errors during initialization`, the libva line again, `ERROR:gpu_memory_buffer_support_x11.cc(44)] dri3 extension not
supported.`, in base, b1, b2, b3 also `ERROR:command_buffer_proxy_impl.cc(128)] ContextResult::kTransientFailure: Failed to send
GpuControl.CreateCommandBuffer.`, then `(node:<pid>) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 connect
listeners added to [Socket]. Use emitter.setMaxListeners() to increase limit` and ``(Use `zephyr --trace-warnings ...` to show
where the warning was created)``. At the end, at the SIGTERM, all except base have one to three teardown lines:
`ERROR:zygote_communication_linux.cc(291)] Failed to send GetTerminationStatus message to zygote` (b2 also
`zygote_communication_linux.cc(158)] Did not receive ping from zygote child`). The same tests in an earlier set of runs (with a
broken process filter, so not in the table) had (a) and (c) with empty stdout and no zygote line, and (a) once with
`ERROR:network_service_instance_impl.cc(521)] Network service crashed, restarting service.` These lines and `on App quit called`
come from shutdown order (the app gets SIGTERM, or loses the display first). Both sandbox branches show them, and the deb's
binary showed none in two base runs. No SUID-sandbox message in any test except (d). Nothing about the WASM or the worker.
(d), verbatim, the whole stderr (3 lines):
```
[3647189:1107/231356.331562:FATAL:setuid_sandbox_host.cc(157)] The SUID sandbox helper binary was found, but is not configured correctly. Rather than run without sandboxing I'm aborting now. You need to make sure that ~/tmp/zeph-r7/appimage/ex/squashfs-root/usr/lib/zephyr/chrome-sandbox is owned by root and has mode 4755.
Trace/breakpoint trap (core dumped)
[3647193:0100/000000.353841:ERROR:zygote_linux.cc(661)] write: Broken pipe (32)
```
So without user namespaces and without `--no-sandbox` the wallet does not start, and (b3) shows that the AppRun probe
catches exactly that case. (a) and (e) show the default path on a machine with user namespaces: the sandbox is on.
Side effect of `--appimage-extract-and-run`: the runtime leaves `$TMPDIR/appimage_extracted_<hash>/` in place. That happened
for the wallet after the timeout kill and for appimagetool even after exit 0 (`--version`). The dirs this round left were
removed; on a CI runner this costs only disk.

### Round 26, reviewer's check of the workflow job
The three run steps of the `appimage` job (work repo, `tools/release/build-wallet.yml`), extracted from the YAML with js-yaml
and run verbatim on a fresh checkout of `v2.3.0-sec.1` with the round-24 deb in `deb/` (the `apt-get` line left out:
`desktop-file-utils` is installed here): tool hashes OK, AppDir `diff -r`-equal to round 26's (AppRun byte-equal), pack
6 s, `zephyr-wallet-v2.3.0-sec.1-x86_64.AppImage` 98662904 B, sha256
`811d5613303db4a0df70b30668a9712dcca1e7ea7c4c7710d39dd456a3fdf245` with `SOURCE_DATE_EPOCH=1794065184` (the tag's commit
time; the CI build should give the same hash from the same deb). Started 12 s under Xvfb: exit 124, the listener warning,
no sandbox error.
