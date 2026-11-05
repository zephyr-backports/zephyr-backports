## Security backports (this fork)

This is **not** a new zephyr-cpp. It is `ZephyrProtocol/zephyr-cpp` at its base commit
(`4a99272`, the state the Zephyr v2.3.0 wallets were built from) plus a small number of security
fixes cherry-picked from `woodser/monero-cpp`, the project it is derived from. Tags mirror the
zephyr fork: `vX.Y.Z-sec.N`.
Full policy: https://github.com/zephyr-backports/zephyr-backports (docs/POLICY.md).

Rules, in short:
- Only clear security issues: memory safety on untrusted input, key/secret exposure, funds at
  risk in transaction construction, privacy, remote DoS, or a dependency with a current CVE.
  No features, no refactors, no correctness-only fixes, no "newer dependency" bumps.
- Only `git cherry-pick -x` of monero-cpp commits; conflicts resolved context-only inside the
  same commit. Nothing of our own except this section, `SECURITY-BACKPORTS.md` and CI.
- Never breaks compatibility with upstream: no consensus, relay, p2p, RPC or file-format
  changes. A node or wallet on this fork and one on upstream interoperate both ways, and
  the version string stays the upstream version.
- Every backport has an advisory in `SECURITY-BACKPORTS.md`: what, origin, impact,
  compatibility statement, test evidence. CI verifies that every commit above the upstream
  base is a monero-cpp cherry-pick (`.github/workflows/provenance.yml`).
- This fork is archived as soon as upstream carries these fixes itself.

Reporting a security issue in Zephyr: report it to the ZephyrProtocol team. We do not fix
issues ourselves; we only backport fixes that upstream (monero-cpp) has published.
