# zephyr-wallet v2.3.0-sec.1: the public build runs (2026-11-07)

`build-wallet.yml` dispatched on `security/v2.3.0` with `tag=v2.3.0-sec.1`, in the order the workflow was fixed. Each fix
is one own commit on the fork, landed by the owner (PR, provenance, fast-forward); nothing in the fork's build
configuration changed. Run links: `https://github.com/zephyr-backports/zephyr-wallet/actions/runs/<id>`.

| run | workflow commit | result | cause |
|---|---|---|---|
| 42398347961 | `496b24f47` | `desktop-mac` cancelled by GitHub at once; `web`, `desktop-linux` green; `hashes` not run | "The configuration 'macos-14-arm64-us-default' is not supported": the macOS 14 images were retired from Actions on 2026-11-02 |
| 42398945264 | `857b277a5` (`runs-on: macos-15`) | `desktop-mac` failed in make; `web`, `desktop-linux`, `desktop-windows`, `flatpak` green | `Cannot find module 'appdmg'`: appdmg (optional, darwin, in the lockfile) builds native modules with node-gyp 9, which needs distutils; the image's Python is 3.15; npm 8 drops a failed optional install silently |
| 42399671015 | `027e5fd15` (setup-python 3.11, appdmg check) | all five build jobs green; `hashes` failed | `no matches found for dist/Zephyr-2.3.0`: the unquoted `find` output split the Windows installer's name ("Zephyr-2.3.0 Setup.exe") at the space; no draft release was created |
| 42401869253 | `56c4c8ee7` (flat asset names) | **all six jobs green; draft release created** | |

## Run 42399671015: what was built
Hashes printed by the `hashes` job before it failed (paths as downloaded; the next workflow version flattens them and
renames the installer to `Zephyr-2.3.0-Setup.exe`, since a GitHub release asset carries the base name and a space
becomes a dot):
```
a882bb263e8f54e47b6675c76042f43334518a06eaba244e6fa324748d5ad16a  Zephyr-2.3.0 Setup.exe
f66a405ada3aeeb6dacc3c5120c3f036e242101b5ab7e16a8e9fac89c5d8d283  Zephyr-2.3.0-arm64.dmg
d8cd54662fecb182dfd37df38b83b60fbc5e0577f5d1060d38afead90551c869  Zephyr-2.3.0-x64.dmg
3864fe45130c5eceb8109233b1afc11c46d1adce27093c3a9cd2d37c69ae71a9  zephyr-wallet-v2.3.0-sec.1.flatpak
8d0f9ef9f4914fa81dd9cccded9f1d4031369874ac5040745dcdf462c5cdc226  zephyr-wallet-web-v2.3.0-sec.1.tar.gz
2747d10da379b054044f1e719c6923582b6178964df04c86f53a44de692e80e0  zephyr_2.3.0_amd64.deb
faba0d52ca668bbc1687023950ba9005cb217184f04e63ed68d98f3cdfd523ea  zip/darwin/arm64/Zephyr-darwin-arm64-2.3.0.zip
bf6f1f8556c7a84f3ccf56f03b0d44498ce28bae2d4250455562369a5c01dfeb  zip/darwin/x64/Zephyr-darwin-x64-2.3.0.zip
```
- `desktop-linux`: the step "Every entry of the deb must be world-readable" passed (no output).
- `desktop-mac`: `Successfully set up CPython (3.11.9)`; `require.resolve('appdmg')` passed; dmg and zip for arm64 and x64
  made.
- `web`: tarball modes `0644`/`0755` only (180 files, 2 executables, 12 directories). Tree compared with the VM's
  `web-zw3.tar.gz` (`84e650bc…`): `diff -rq` shows only `asset-manifest.json`, `index.html` and the four chunks
  `0.*`, `1.*`, `4.*`, `runtime-main.*` (with their `.map` and `.LICENSE.txt`), as in the dry run's round 23;
  `main.*.chunk.js` byte-equal; `monero_wallet_full.wasm` in the tarball `c984b999dd76550ab8135a0d7ddfd34b5fc7774200f8887aaa5f4984a7c7b1e4`.

## Run 42401869253: the draft release
Nine assets, flat names, no spaces: `SHA256SUMS`, `Zephyr-2.3.0-Setup.exe`, `Zephyr-2.3.0-arm64.dmg`, `Zephyr-2.3.0-x64.dmg`,
`Zephyr-darwin-arm64-2.3.0.zip`, `Zephyr-darwin-x64-2.3.0.zip`, `zephyr-wallet-v2.3.0-sec.1.flatpak`,
`zephyr-wallet-web-v2.3.0-sec.1.tar.gz`, `zephyr_2.3.0_amd64.deb`. `SHA256SUMS` as uploaded by the run:
```
34d22343b7458cbb1693e10532e587cea6cde54363e3263ea34c65c983256fdc  Zephyr-2.3.0-Setup.exe
25299bb4a8602fb806837d8d8455c6677d7094f3066a45d6d0f3b35ffc180756  Zephyr-2.3.0-arm64.dmg
2222dde8106a263881896915e9587849cad60faeecf62644f9f1fee8290606d7  Zephyr-2.3.0-x64.dmg
5ddcaf227b174a79f03301b41f3bb0b47a94cb452b1bc67c969c41605c2f80e9  Zephyr-darwin-arm64-2.3.0.zip
5e5f3930aba738da1a408e1076372533004596be61791c257b659b9bc20c0762  Zephyr-darwin-x64-2.3.0.zip
9cf16a741015bb3d495904e430ffdca9bd02aa8575cd972cf5b1572ced7f11cf  zephyr-wallet-v2.3.0-sec.1.flatpak
8d0f9ef9f4914fa81dd9cccded9f1d4031369874ac5040745dcdf462c5cdc226  zephyr-wallet-web-v2.3.0-sec.1.tar.gz
b75a88320c14db49746b71a43a83eb19b067a75a14728e94fbaac12ce57e4950  zephyr_2.3.0_amd64.deb
```
Checked by the reviewer from the downloaded assets (before signing):
- `sha256sum -c` OK for the web tarball and the deb (the others are checked by the owner after the full download).
- Deb: no entry without a read bit; both WASM copies `c984b999…`.
- **Web tarball byte-identical across two CI runs** (`8d0f9ef9…` in runs 42399671015 and 42401869253, two runners, the
  same image): the bundle reproduces on GitHub's runner image; its tree against the VM's build differs only in the four
  chunks named above, `main.*` equal (see above). The installers differ between runs, as expected (timestamps).
- Release notes as written by the workflow; the run link points at 42401869253.
