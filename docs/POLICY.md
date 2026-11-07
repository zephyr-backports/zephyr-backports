# Policy: Zephyr security backports

*Adopted 2026-11-04. This is the policy of the forks under the GitHub organisation `zephyr-backports`; the README of every fork points here and summarises §2, §4 and §5.*

## 1. Role
The Zephyr team is small, has a history of long silences and is currently busy with the bridge. Monero keeps fixing things in the meantime. We take the role that Debian's security team has for Debian: **backport upstream fixes for clear security issues onto the version upstream has released, without changing anything else.** No fixes of our own, no features, no "improvements". An independent third party that gives the community a safer build of *the same* software: public, verifiable, and redundant as soon as upstream keeps up by itself.

Two hard properties:
- **Same version.** A release is upstream tag + N backports: `v2.3.0-sec.1`, `-sec.2`, … The version string stays upstream's: a build from a fork tag prints exactly what upstream's tagged build prints (`v2.3.0-release`; the build system names any tag at HEAD "release"). The git tag, the signed hashes and the build manifest identify a fork build.
- **Never break.** Upstream and fork are fully interchangeable, in both directions: nodes sync with each other, accept the same blocks and transactions, serve the same RPC, and open each other's wallet files. A backport that cannot guarantee this does not go in, however useful.

## 2. What counts as a "clear security issue"
A fix with a public origin that prevents one of these consequences:

| Class | Examples |
|---|---|
| **Memory safety on untrusted input** | over-read/over-write in epee parsing, tx/block deserialisation, levin buffers; use-after-free in the scan pipeline |
| **Loss or exposure of keys/secrets** | view key in logs, tx keys that are not wiped, incomplete memory wipe |
| **Funds at risk through wrong tx construction** | change to the wrong address, fee calculation that throws money away, double-spend paths |
| **Privacy** | manipulable decoy selection, restricted RPC/ZMQ that reveals too much, IP/address leaks |
| **Remote DoS of node or wallet** | infinite loops, unbounded allocations, crash on malformed peer/node data, resource exhaustion via p2p |
| **Dependency with a current security problem** | CVE in a pinned dependency (boost, OpenSSL, lmdb, unbound, randomx, rapidjson, easylogging) that affects its use |

**Not:** correctness without a security consequence (balance display, sync comfort), performance, refactors, features, newer dependency versions "to keep up", and anything that touches §4. **When in doubt, no.**

Origin: `monero-project/monero`, branch `release-v0.18`, or the upstream of a dependency. Exception (2026-11-05): Zephyr's base is derived from Monero master, so when a `release-v0.18` fix has a counterpart on `master` (same author, date and subject) that also adjusts master-only code or tests Zephyr carries, the `master` commit is the backport and the advisory names both shas. Our own discoveries we report to upstream and do not fix ourselves; that is not a backport but a design change.

## 3. Scope over repositories
What the wallet project needs, extensible if other Zephyr projects come along. Backports do **not** have to be limited to the wallet: daemon security (p2p DoS, restricted-RPC privacy) counts, because the community runs those nodes.

| Repo | Based on | Fixes from | Status |
|---|---|---|---|
| `ZephyrProtocol/zephyr` | Monero master 2024-03-12 (`15a4ff66f`) | `monero-project/monero` | **active**: wallet and daemon |
| `ZephyrProtocol/zephyr-cpp` | `woodser/monero-cpp` (base commit still to be established) | monero-cpp | when needed |
| `ZephyrProtocol/zephyr-javascript` | `woodser/monero-javascript` | monero-ts/-javascript | the C++ bridge only, when needed |
| `ZephyrProtocol/zephyr-wallet` | `haven-protocol-org/haven-web-app` | — | **artefact and dependency pins only** (§5): the rebuilt WASM and lockfile pins; no application code |
| `zephyr-gui` | — | — | no, unless the community asks |
| explorer, pool, pyzeph | — | — | no |

## 4. Compatibility rules (hard)
1. **No consensus, relay or hard-fork change**: nothing in `src/hardforks`, consensus constants in `cryptonote_config.h`, block/tx validation in `blockchain.cpp`/`tx_pool.cpp`, relay rules. Example of what therefore does *not* go in: Monero's `dd47d03cf` ("enforce unlock_time is zero by relay rule").
2. **No wire change**: p2p/levin messages, RPC schemas (no additions either), ZMQ formats. Clarified 2026-11-05: an upstream commit that stops serving an endpoint in `--restricted-rpc` mode for privacy reasons is not a wire change (schema unchanged, unrestricted nodes unchanged), provided no wallet in the release set calls that endpoint; the advisory names the endpoint. New text in an error reply to input that was never valid is not a wire change either.
3. **No file-format change**: wallet cache, keys file, LMDB schema; no migrations.
4. **Stricter parsing only of input that was never valid.** A fix that rejects an encoding upstream accepts is, for a node, a consensus change: forbidden, even if Monero merged it as hardening, because Zephyr has structures of its own (pricing record, asset fields). Proof: the full-chain scan (§6).
5. **Version identity**: `DEF_MONERO_VERSION` and the printed version string unchanged (a tagged fork build prints `v2.3.0-release` like upstream's); only the git tag carries `-sec.N`.

## 5. Workflow
- Forks under the GitHub organisation `zephyr-backports` (home repo `zephyr-backports/zephyr-backports` with this policy, the advisories index and the tooling), licence unchanged. One branch per upstream tag: `security/v2.3.0`; tags `v2.3.0-sec.N`. Remote `monero` for `release-v0.18`.
- **Only `git cherry-pick -x`.** Whole commits (Monero tested them as a unit; daemon files may change along). Conflict resolution strictly context-only, in the same commit, with the trailer `Conflicts: <files> (context only)`: the lines the commit adds stay byte-identical to upstream's, indentation included, and the lines it removes are absent afterwards; only the surrounding unchanged lines may differ. A removal that the base already contains (git merges it silently, no trailer) is fine; a hunk whose pre-image does not exist in Zephyr and whose change is not already present cannot be dropped: that is a semantic conflict. Semantic conflict → **skip** and note it.
- **No own commits**, except, exactly what `tools/check-provenance.sh` allows, changes to `README.md` (the security section), `SECURITY-BACKPORTS.md` and `.github/**`, each with the trailer `Origin: zephyr-backports`. No build-only fixes in the fork: whoever builds the fork (such as the webwallet project) solves build problems in their own build layer (`tools/wasm/patches/`). Nothing is written inside the fork: it is prepared here (`fork-files/`) and inserted or copied.
- **Two further own-commit types, Debian-style, for the repositories whose security fixes cannot be expressed as an upstream cherry-pick** (adopted 2026-11-05): (a) a **dependency pin** to the version that fixes a named advisory, touching only `package.json` and the lockfile, with the trailers `Origin: zephyr-backports` and `Advisory: <GHSA or CVE id>`; (b) an **artefact rebuild** (`dist/**` in zephyr-javascript, `client/public/**` in zephyr-wallet) built reproducibly from named fork tags, with the trailers `Origin: zephyr-backports` and one `Built-From: <repo> <tag> <sha>` per source, and a signed build manifest. Each gets an advisory like any backport. A dependency without a fixed version, or a fix that needs application code, stays out: that is upstream's work.
- **Every change through a pull request; the maintainer lands it.** Every change to a protected branch (`main` in the home repo and the org repo, `security/*` in the forks) is opened as a pull request, where the checks run and the diff is public. It is landed not with GitHub's merge button but by the maintainer, who pushes the checked PR head as a **fast-forward** onto the protected branch (the forks) or squashes it locally into one signed commit (home and org repo). GitHub's own merges rewrite commits with GitHub as committer: a rebase merge cannot be signed by GitHub at all, and the dates carry the merging account's time zone. The fast-forward keeps every cherry-pick as the separate, maintainer-signed commit with its provenance line that was checked; the sha on GitHub is the sha that was built and tested. The one commit GitHub created before this rule, the squash of the first policy PR on the home repo (`7d56cbc`), stays as it is. Only the maintainer (organisation owner) may bypass the pull-request rule, and only for that fast-forward; the merge buttons stay restricted as a guard.
- **One advisory per backport** in `SECURITY-BACKPORTS.md` (template: `docs/ADVISORY-TEMPLATE.md`): number, Monero commit(s), class from §2, what went wrong and for whom (wallet/daemon/both), impact, compatibility statement (which rules of §4 were checked and how), test evidence. The advisory is the product; the commit is the attachment.
- **On an upstream release:** new branch from the new tag; reassess every open backport; first new tag only when there is something to backport. Upstream tag without backports = use upstream.
- **Exit:** as soon as upstream structurally keeps up, archive the fork.

## 6. Verifiability
1. **Provenance (CI in the fork, `tools/check-provenance.sh`):** every commit above the upstream tag has `(cherry picked from commit <sha>)` and that sha is reachable from `monero/release-v0.18` or, in the counterpart case of §2, `monero/master` (or the dependency upstream); exceptions only for the files in §5. `SECURITY-BACKPORTS.md` is compared with the log.
2. **Build (CI):** Zephyr's own `build.yml` matrix for daemon and wallet.
3. **Tests (CI):** Monero unit tests that passed on the upstream tag keep passing.
4. **Compatibility (from the webwallet project, per tag):** WASM build with the fork tag and four guards; harness with **cross-open of wallet data in both directions** against upstream's binary; **full-chain scan** from height 0 on our own node (one rejected valid block = blocker); as soon as there are daemon builds: fork node syncs from upstream peers and serves upstream wallets, and the other way round.
5. Every tag gets a signed manifest (upstream tag, backport list, hashes of the artefacts).

## 7. Signing
*Details (keys, creation, publication, verification, rotation): [`KEYS.md`](KEYS.md).*

Upstream does not sign its commits, tags or releases. We do. That is not a backport but a property of *our* release process, and by itself a reason to use these forks:
- **Commits:** every commit is GPG-signed. The maintainer key (`git commit -S`) signs every commit, and what lands on a protected branch is exactly the signed commit that was checked in the pull request (§6, fast-forward by the maintainer): no commit on `security/*` is created or signed by GitHub, so verification needs the maintainer key alone and no trust in GitHub's infrastructure (the practice of Bitcoin Core's `github-merge.py` and of Monero's maintainers). The branch rules require a verified signature on every commit. Tags and artefacts are signed with the release key; the fingerprint is in the home README and in `keys/README.md`, and the key is on `keys.openpgp.org`. Contact address: `zephyr-backports@lateo.dev` (Cloudflare Email Routing); that address is the UID of the **separate release key** (KEYS.md §1), certified by the maintainer key, published on `keys.openpgp.org` and registered on the maintainer's GitHub account so that tags show "Verified".
- **Tags:** `vX.Y.Z-sec.N` are signed tags (`git tag -s`). The upstream base cannot be verified cryptographically (no signatures upstream); therefore we pin it on the full commit sha (content-addressed) and name it in the tag message and in `SECURITY-BACKPORTS.md`.
- **Artefacts:** if binaries or the WASM are ever published through the org, then with a signed `SHA256SUMS` (Monero's `hashes.txt` practice) and a signed build manifest, preferably reproducibly built, so that the signature says something about the source and not only about the build machine.
- **What we do not claim:** a signature proves who made the tag, not that the content is safe. That is proven by the provenance check, the compatibility tests and the advisories.
- **No platform code signing, by choice.** Desktop builds are not notarized by Apple or Authenticode-signed for Windows: both require a legal identity in the certificate, which this pseudonymous organisation does not provide. Upstream's own releases are not signed either. Verification of our builds is by the GPG-signed hashes, the signed build manifest and the public CI run that produced them.

## 8. Organisation files
The GitHub organisation `zephyr-backports` has a small `.github` repo (`org-files/` here): the org profile with the "not affiliated" disclaimer, and `SECURITY.md`/`CONTRIBUTING.md`, which GitHub shows as the default on every fork **without them being in the fork tree**. That keeps the forks clean (§5) and makes the reporting route (to ZephyrProtocol, not to us) visible everywhere. The reusable provenance workflow lives in the home repo, not in `.github`.
