# Keys

Two OpenPGP keys sign what this organisation publishes. Policy and rationale: `docs/KEYS.md`,
summarised in `docs/POLICY.md` §7.

| Key | Fingerprint | Signs |
|---|---|---|
| **Release key** `zephyr-backports <zephyr-backports@lateo.dev>` | `FB39 94F0 997C A6F0 43D7  2491 9EFF 03F5 27D2 40A1` | tags `vX.Y.Z-sec.N`, `SHA256SUMS`, build manifests |
| Signing subkey of the release key | `AFCB 1596 42DE 74B6 5D18  3AA2 0937 555B 1B70 815A` | (the subkey that actually appears in signatures) |
| **Maintainer key** `loki-notfound` | `31DA 39AB 43E0 CA67 F1F3  A661 BA2A FF22 DF8A 4A13` | commits in the forks and this repo; certifies the release key |

Files:

```
keys/zephyr-backports.asc   release key (public), certified by the maintainer key
keys/loki-notfound.asc      maintainer key (public)
```

Mail to `zephyr-backports@lateo.dev` is received and answered from the maintainer's address,
`loki-notfound@proton.me`, signed with the maintainer key. Encrypt to the **maintainer key**: the
release key has no encryption subkey.

The release key's primary is certify-only (`[C]`), created 2026-11-04, expires 2028-11-03. The
primary is kept offline; only the signing subkey is on the release machine. Trust chain:
fingerprint here and on `keys.openpgp.org` (e-mail verified) → maintainer key → (certification) → release key → tag.

## Verify

```bash
# fetch the release key from keys.openpgp.org by its fingerprint, or import keys/*.asc
gpg --keyserver hkps://keys.openpgp.org --recv-keys FB3994F0997CA6F043D724919EFF03F527D240A1
gpg --fingerprint zephyr-backports@lateo.dev     # compare with the table above

# a release tag
git verify-tag v2.3.0-sec.1

# published artefacts
gpg --verify SHA256SUMS.asc && sha256sum -c SHA256SUMS

# optional: see the maintainer key's certification on the release key
gpg --check-sigs zephyr-backports@lateo.dev
```

Every release tag names the full upstream commit sha in its message. Upstream signs nothing, so
that sha is the only way to pin the base.

## What a signature does and does not prove

A good signature proves who made the tag or file. It does not prove the content is safe. That is
what the provenance check (`tools/check-provenance.sh`), the compatibility tests and the advisories
in each fork's `SECURITY-BACKPORTS.md` are for.

## Rotation and revocation

Old keys stay in this directory after rotation, marked `EXPIRED` or `REVOKED` here, so that old
tags remain verifiable. A new release key is certified by the maintainer key and by the old
release key. A revocation is published here and on `keys.openpgp.org`.
