# Release runbook: zephyr-wallet artefacts (owner)

For `v2.3.0-sec.1`; later tags the same way. The workflow (`.github/workflows/build-wallet.yml` in the zephyr-wallet
fork) builds the web tarball, macOS dmg and zip (arm64 and x64), the Windows Squirrel installer, the Linux deb and the
flatpak bundle from a signed tag, and puts them with an unsigned `SHA256SUMS` into a **draft** release. The owner
verifies, signs the hashes with the release key, uploads the signature and publishes. POLICY §7: no platform code
signing. Never a change to the fork's build configuration (`forge.config.js`, `package.json` scripts, `sh/*`).

```bash
FPR=FB3994F0997CA6F043D724919EFF03F527D240A1      # release key (docs/KEYS.md §7)
REPO=zephyr-backports/zephyr-wallet
TAG=v2.3.0-sec.1
```

## 1. Land the flatpak manifest, then pin it in the workflow
1. The reviewer makes the home branch with `tools/release/flatpak/dev.lateo.zephyr.yml`; land it as usual (one commit, PR, checks
   green, the owner's fast-forward push to `main`, POLICY §6). Note the resulting home commit:
   `git -C ~/github/zephyr-backports/zephyr-backports rev-parse origin/main`.
2. The reviewer replaces `HOME_SHA` in `fork-files/zephyr-wallet/.github/workflows/build-wallet.yml` with that full sha and
   rebuilds the one commit on the fork branch `pr/build-workflow` (still one own commit, `.github/workflows/build-wallet.yml`
   only). Until then the flatpak job cannot check out the manifest and the run fails at that job.

## 2. Land the workflow (PR, fast-forward)
```bash
cd ~/github/zephyr-backports/zephyr-wallet
git push origin pr/build-workflow
gh pr create --repo "$REPO" --base security/v2.3.0 --head pr/build-workflow \
  --title "security: release build workflow" --body "One own commit: .github/workflows/build-wallet.yml."
# wait for the provenance check to be green, then land the checked head by fast-forward (POLICY §5):
git push origin pr/build-workflow:security/v2.3.0
```
Check: `git ls-remote origin security/v2.3.0` shows the PR head; GitHub marks the PR merged.

## 3. Dispatch the build on the tag
The tag `v2.3.0-sec.1` predates the workflow, so a tag push cannot start it; the first run is a dispatch. The workflow
file is taken from `--ref`, the sources from the `tag` input.
```bash
gh workflow list --repo "$REPO"                         # build-wallet must be listed
gh workflow run build-wallet.yml --repo "$REPO" --ref security/v2.3.0 -f tag="$TAG"
```
**If `gh workflow run` says the workflow is not found or cannot be dispatched:** GitHub may only dispatch workflows that
also exist on the repository's default branch, which is `master` in this fork (upstream's history, not changed by us).
Not verified before the first run. The repository setting that resolves it is the default branch
(`gh repo edit "$REPO" --default-branch security/v2.3.0`); that is an owner decision (it also changes what visitors
see first). No change to `master` and no re-tagging.

## 4. Watch the run
```bash
RUN=$(gh run list --repo "$REPO" --workflow build-wallet.yml --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch "$RUN" --repo "$REPO" --exit-status
gh run view "$RUN" --repo "$REPO" --log-failed         # only if a job failed
```
The web job prints the tarball's sha256 in its log; the hashes job prints `SHA256SUMS`.

## 5. Download and verify
```bash
mkdir -p ~/tmp/release-$TAG && cd ~/tmp/release-$TAG
gh release download "$TAG" --repo "$REPO"              # the draft release: all artefacts and SHA256SUMS
sha256sum -c SHA256SUMS                                 # every file OK
grep -c . SHA256SUMS                                    # web, 2 dmg, 2 zip, exe, deb, flatpak: 8 lines expected
```

## 6. Second builder: compare the web tarball
The VM built the same tag on 2026-11-07 (`evidence/wallet/2026-11-07/release-dry-run.md`, rounds 21 and 23). The web
bundle reproduces within one checkout (three builds, one hash) but **not across checkouts**: four chunks (`0.*`, `1.*`,
`4.*`, `runtime-main.*`) differ in minifier naming and order, `main.*` is equal; the cause is in upstream's build
(react-scripts 4), not analysed yet (UPSTREAM-FINDINGS zephyr-wallet 18). So expect the CI tarball's hash to differ from
the VM's, and compare the trees instead:
```bash
mkdir ci vm && tar -xzf zephyr-wallet-web-$TAG.tar.gz -C ci && tar -xzf ~/tmp/zeph-r7/web-zw3.tar.gz -C vm
diff -rq ci vm                                          # expected: only chunk files with differing hashes, index.html, asset-manifest.json
cmp ci/build/static/js/main.*.chunk.js vm/build/static/js/main.*.chunk.js   # expected: equal
```
Record the result in the evidence before publishing (the `diff -rq` output and the `main.*` result). Anything beyond
the four chunks and the two files that name them is a reason to stop and ask. The desktop installers are not byte-reproducible (dmg and Squirrel embed timestamps); for them the claim is "built by
this public run from this tag".

## 7. Sign and upload the signature
```bash
gpg -u "$FPR" --clearsign SHA256SUMS                    # -> SHA256SUMS.asc
gpg --verify SHA256SUMS.asc                             # Good signature from "zephyr-backports <zephyr-backports@lateo.dev>"
gh release upload "$TAG" SHA256SUMS.asc --repo "$REPO"
```

## 8. Release notes and publishing
The workflow writes the notes; check them in the draft (`gh release view "$TAG" --repo "$REPO"`). The text says:
- the same source as upstream's release (`v2.3.0`) plus the security changes listed in `SECURITY-BACKPORTS.md`
  (the wallet core rebuilt from the zephyr and zephyr-cpp security forks, and dependency pins);
- not notarized by Apple or Authenticode-signed for Windows, like upstream's own builds; macOS Gatekeeper and Windows
  SmartScreen will warn;
- the web bundle is upstream's web build unchanged and connects to the node at `localhost:3000` of the browser's
  machine (`client/.env` in the source; UPSTREAM-FINDINGS zephyr-wallet 23);
- how to verify instead: `gpg --verify SHA256SUMS.asc` (release key, see the home repository), then
  `sha256sum -c SHA256SUMS`; the signed tag and the WASM's build manifest; the link to the public run.
```bash
gh release edit "$TAG" --repo "$REPO" --draft=false
```
Then the reviewer lists the release set in the home README (zephyr `v2.3.0-sec.2`, zephyr-cpp `v2.3.0-sec.1`,
zephyr-javascript `v2.3.0-sec.1`, zephyr-wallet `v2.3.0-sec.1`) with the release link and the run.

## 9. When a job fails
- Read the log (`gh run view "$RUN" --repo "$REPO" --log-failed`), note the job and the error in the evidence.
- Fix it **in the workflow**: a new branch from `security/v2.3.0`, one own commit to `.github/workflows/build-wallet.yml`,
  PR, provenance green, fast-forward (step 2); then dispatch again (step 3). Delete the half-made draft release first if
  the hashes job created one (`gh release delete "$TAG" --repo "$REPO"` deletes the release, not the tag).
- **Never** a change to the fork's build configuration (`forge.config.js`, `package.json` scripts, `sh/*`) or to the
  application code. If a platform cannot be built without one, that platform is left out of this release and named
  in the notes; ask first.
- Known risks for the first run: the `workflow_dispatch` default-branch question (step 3); the deb was built on the
  VM (`evidence/wallet/2026-11-07/release-dry-run.md`, rounds 22 and 23) and the workflow sets `umask 0022` in the
  steps whose files end up in the deb and fails when an entry of the deb is not world-readable; the macOS and Windows artefact paths
  follow electron-forge 6 defaults and were not built locally; the flatpak runtime 26.08 for Electron 22 is untested
  (25.08 is the step back, in the manifest).
