# Reproducible WASM build in a container (DRAFT, not run)

The webwallet project's `tools/wasm/build.sh` already builds the wallet WebAssembly from pinned
sources and records `build-manifest.json` (source commits, patch hashes, toolchain, flags, and the
sha256 of every output). The `Dockerfile` here only freezes the host around it, so that two
independent builders can show they get the same bytes.

## Run

```
docker build -t zephyr-wasm-builder tools/release/wasm        # or: podman build …
mkdir -p "$PWD/wasm-work"
docker run --rm \
  -v ~/github/zeph-webwallet-workrepo:/webwallet:ro \
  -v "$PWD/wasm-work":/work \
  [-v ~/github/clones/zephyrprotocol:/mirrors:ro] \
  zephyr-wasm-builder
# result: wasm-work/build/out/{monero_wallet_full,monero_wallet_keys}.{js,wasm}, build-manifest.json
```

`build.sh` builds the commits pinned at its top (today upstream v2.3.0: zephyr `67c5f53b`,
zephyr-cpp `4a99272f`, zephyr-javascript `9d022ded`). Building a security-fork tag means changing
those pins and pointing `/mirrors` at clones that contain the fork commits; that is the webwallet
project's change to make (`docs/FORK-PLAN.md` there), not something this image does.

## Two-builder comparison (intended)

1. Builder A (the owner's workstation) and builder B (a second machine or a GitHub-hosted
   runner) each build the image from this Dockerfile at the same commit and record the image id.
   The image itself need not be byte-identical (layer timestamps); what matters is that it
   contains the same packages (snapshot date) and the same emsdk.
2. Both run the container on the same `build.sh` (same `script_sha256` in the manifest) and the
   same pins.
3. Compare `outputs.*.sha256` in the two `build-manifest.json` files (everything except
   `built_at_utc`). Equal hashes for `monero_wallet_full.wasm`, `monero_wallet_full.js`,
   `monero_wallet_keys.wasm`, `monero_wallet_keys.js` = reproduced. `monero_wallet_full.symbols.txt`
   comes from a separate analysis link and is compared too, but is not shipped.
4. A host run of `build.sh` without the container is a third data point: `-ffile-prefix-map`
   keeps paths out of the binaries, so it should match as well.
5. The matching manifest is what the owner signs and what an artefact-rebuild commit in
   zephyr-javascript cites (`Built-From:` trailers, POLICY §5).

## Status on 2026-11-05

- Neither `docker` nor `podman` is installed on the workstation: **no container build was tried**,
  so there is no comparison yet.
- Reference for the comparison: the last host run of `build.sh` on the workstation,
  `/tmp/zeph-wasm/out/build-manifest.json`, built 2026-11-04T15:09:20+00:00 from upstream v2.3.0
  (emsdk 3.1.10, installer `d7b41306`):

  | sha256 | file |
  |---|---|
  | `3e99a8f5bda3756e996fd902635a52888ed1e75d022655064fe1738b4b6a0a74` | `monero_wallet_full.wasm` |
  | `a1fc5e219591a5564cb4447b85f2499ec855fab329b1e498d003add2804b3974` | `monero_wallet_full.js` |
  | `7283e5bd0dead72b630e47acc94cdc0f1422dec59bb5f8e124a5fe1553d21c63` | `monero_wallet_keys.wasm` |
  | `69b02e1e9f12064b845a9d06ed3577a54eeedcafd679dbc283ae515470abe607` | `monero_wallet_keys.js` |

  That manifest's `script_sha256` (`eac7c10c…`) differs from the current `build.sh`
  (`7131f9a5…`): the script changed after that run. A fresh host run is needed before the first
  container comparison is like for like.
