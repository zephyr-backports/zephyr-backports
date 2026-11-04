# zephyr-backports

Security backports for [Zephyr Protocol](https://github.com/ZephyrProtocol), Debian-security
style: the upstream release **plus** security fixes cherry-picked from
[Monero](https://github.com/monero-project/monero) (the project Zephyr is derived from), tagged
`vX.Y.Z-sec.N`, fully compatible with upstream, GPG-signed. This repository holds the policy, the
inventories, the backport lists, the tooling and the keys. The code lives in the forks.

**Not affiliated with ZephyrProtocol.** An independent community effort. We do not write fixes of
our own; we only backport fixes that Monero has published. Report Zephyr vulnerabilities to the
ZephyrProtocol team, not to us (see [SECURITY.md](https://github.com/zephyr-backports/.github/blob/main/SECURITY.md)).

## Status (2026-11-04)

| Fork | Upstream base | Branch | Latest tag |
|---|---|---|---|
| [`zephyr`](https://github.com/zephyr-backports/zephyr) | v2.3.0 (`67c5f53b878fef41fb5e74c4382d5b7a2f37fd8a`) | `security/v2.3.0` | none yet; `v2.3.0-sec.1` (9 backports) is being prepared |
| [`zephyr-cpp`](https://github.com/zephyr-backports/zephyr-cpp) | upstream master | — | none; only when a backport is needed |
| [`zephyr-javascript`](https://github.com/zephyr-backports/zephyr-javascript) | upstream master | — | none; C++ bridge only, when needed |

The pick list with per-commit status: [`backports/v2.3.0.txt`](backports/v2.3.0.txt). The plan
per release: [`docs/PLAN-v2.3.0.md`](docs/PLAN-v2.3.0.md).

## How it works

- **Only clear security issues**: memory safety on untrusted input, key or secret exposure, funds
  at risk in transaction construction, privacy, remote DoS, a dependency with a current CVE. No
  features, refactors, correctness-only fixes or dependency bumps.
- **Only `git cherry-pick -x`** of commits from `monero-project/monero` (`release-v0.18`).
  Conflicts are resolved context-only inside the same commit. A semantic conflict means skip.
- **Never breaks compatibility** with upstream: no consensus, relay, p2p, RPC or file-format
  changes. Fork and upstream interoperate both ways; the version string stays the upstream one.
- **Every backport has an advisory** in the fork's `SECURITY-BACKPORTS.md`: origin, impact,
  compatibility statement, test evidence.
- **Provenance is checked by CI**: every commit above the upstream tag must be a Monero
  cherry-pick or one of the few allowed own files (`tools/check-provenance.sh`, called through
  [`.github/workflows/provenance.yml`](.github/workflows/provenance.yml)).
- **Exit**: a fork is archived as soon as upstream carries the fixes itself.

Full policy: [`docs/POLICY.md`](docs/POLICY.md).

## Verify a release

Tags and artefacts are signed with the release key; commits with the maintainer key, which also
certifies the release key. Details and rotation: [`keys/README.md`](keys/README.md),
[`docs/KEYS.md`](docs/KEYS.md).

| Key | Fingerprint |
|---|---|
| Release key `zephyr-backports <zephyr-backports@lateo.dev>` | `FB39 94F0 997C A6F0 43D7  2491 9EFF 03F5 27D2 40A1` |
| Maintainer key `loki-notfound` | `31DA 39AB 43E0 CA67 F1F3  A661 BA2A FF22 DF8A 4A13` |

```bash
gpg --locate-keys zephyr-backports@lateo.dev          # via WKD on lateo.dev, or import keys/*.asc
gpg --fingerprint zephyr-backports@lateo.dev          # compare with the table above
git verify-tag v2.3.0-sec.1                           # a release tag
gpg --verify SHA256SUMS.asc && sha256sum -c SHA256SUMS   # published artefacts, when any
```

Every release tag names the full upstream commit sha in its message. Upstream signs nothing, so
that sha is the only way to pin the base.

## Repository map

```
docs/POLICY.md                        policy: role, what counts as a security issue, scope, compatibility rules, workflow, verification, signing
docs/PLAN-v2.3.0.md                   plan for the current upstream release, measured on a dry cherry-pick run
docs/INVENTORY-MONERO-2024-2026.md    Monero fixes since Zephyr's base commit, grouped and assessed
docs/BASELINE.md                      how Zephyr relates to Monero (measured), how to reproduce the inventory
docs/KEYS.md                          keys: roles, creation, publication, verification, rotation, expiry
docs/ADVISORY-TEMPLATE.md             one advisory per backport
backports/v2.3.0.txt                  ordered pick list with status (read by tools/backport.sh)
tools/backport.sh                     cherry-pick in order, stop on conflict, dry-run mode
tools/check-provenance.sh             the provenance check (fork CI and local)
tools/inventory.sh                    rebuild the inventory from monero/release-v0.18
fork-files/zephyr/                    files that go into the fork: README section, SECURITY-BACKPORTS.md, CI caller
keys/                                 public keys, fingerprints, WKD files
.github/workflows/provenance.yml      reusable workflow the forks call
LICENSE                               BSD-3-Clause for this repo; the forks keep upstream's licence
```

## Contact

`zephyr-backports@lateo.dev` (receive-only; replies come from the maintainer's address
`loki-notfound@proton.me`, signed with the maintainer key; encrypt to that key). For problems **in a backport** (a cherry-pick that
misbehaves or does not match its advisory): an issue on the fork or that address. For
vulnerabilities in Zephyr itself: the ZephyrProtocol team. Proposing a backport:
[CONTRIBUTING.md](https://github.com/zephyr-backports/.github/blob/main/CONTRIBUTING.md).
