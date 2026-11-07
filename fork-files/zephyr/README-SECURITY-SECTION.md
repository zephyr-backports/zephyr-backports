## Security backports (this fork)

This is **not** a new Zephyr. It is `ZephyrProtocol/zephyr` at an upstream release tag plus a
small number of security fixes cherry-picked from `monero-project/monero` (`release-v0.18`),
the project Zephyr is derived from. Tags are `vX.Y.Z-sec.N`: upstream `vX.Y.Z` + N backport batches of this fork (the companion
zephyr-cpp tag has its own N; the release sets are listed in the home repository).
Full policy: https://github.com/zephyr-backports/zephyr-backports (docs/POLICY.md).

Rules, in short:
- Only clear security issues: memory safety on untrusted input, key/secret exposure, funds at
  risk in transaction construction, privacy, remote DoS, or a dependency with a current CVE.
  No features, no refactors, no correctness-only fixes, no "newer dependency" bumps.
- Only `git cherry-pick -x` of Monero commits; conflicts resolved context-only inside the
  same commit. Nothing of our own except this section, `SECURITY-BACKPORTS.md` and CI.
- Never breaks compatibility with upstream: no consensus, relay, p2p, RPC or file-format
  changes. A node or wallet on this fork and one on upstream interoperate both ways, and
  the version string stays the upstream version.
- Every backport has an advisory in `SECURITY-BACKPORTS.md`: what, origin, impact,
  compatibility statement, test evidence. CI verifies that every commit above the upstream
  tag is a Monero cherry-pick (`.github/workflows/provenance.yml`).
- This fork is archived as soon as upstream carries these fixes itself.

Reporting a security issue in Zephyr: report it to the ZephyrProtocol team. We do not fix
issues ourselves; we only backport fixes that upstream (Monero) has published.
