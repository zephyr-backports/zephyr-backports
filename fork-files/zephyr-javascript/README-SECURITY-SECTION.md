## Security backports (this fork)

This is **not** a new zephyr-javascript. It is `ZephyrProtocol/zephyr-javascript` at its base
commit (`9d022ded`, "Updates for version 2.3.0", the state the Zephyr v2.3.0 wallets were built
from) plus a small number of security changes. Tags mirror the zephyr fork: `vX.Y.Z-sec.N`.
Full policy: https://github.com/zephyr-backports/zephyr-backports (docs/POLICY.md).

**This fork receives three kinds of change** (POLICY §3 and §5):
- **Cherry-picks into the C++ bridge** (`src/main/cpp/`) of commits from `woodser/monero-ts`,
  the project this library is derived from, with `git cherry-pick -x` and context-only conflict
  resolution, when a security fix lives in the bridge.
- **Artefact rebuilds:** the WASM and bundles in `dist/`, rebuilt reproducibly from named tags of
  the zephyr and zephyr-cpp security forks, so that their backports reach the library. Each such
  commit names its sources (`Built-From: <repo> <tag> <sha>`) and comes with a signed build manifest.
- **Dependency pins:** `package.json` and `package-lock.json` moved to the version of a dependency
  that fixes a named advisory (`Advisory: <GHSA or CVE id>`). A dependency without a fixed
  version, or a fix that needs application code, stays out: that is upstream's work.

Rules, in short:
- Only clear security issues: memory safety on untrusted input, key/secret exposure, funds at
  risk in transaction construction, privacy, remote DoS, or a dependency with a current advisory.
  No features, no refactors, no correctness-only fixes, no "newer dependency" bumps.
- No application code of our own. Nothing of our own except this section,
  `SECURITY-BACKPORTS.md`, CI, and the two own-commit types above (artefact rebuilds and dependency pins).
- Never breaks compatibility with upstream: same API, same wallet file formats, same RPC use. A
  wallet built on this fork and one built on upstream open each other's data, and the version
  string stays the upstream version.
- Every change has an advisory in `SECURITY-BACKPORTS.md`: what, origin, impact,
  compatibility statement, test evidence. CI verifies that every commit above the upstream
  base is one of the allowed types (`.github/workflows/provenance.yml`).
- This fork is archived as soon as upstream carries these fixes itself.

Reporting a security issue in Zephyr: report it to the ZephyrProtocol team. We do not fix
issues ourselves; we only bring in fixes that upstream projects have published.
