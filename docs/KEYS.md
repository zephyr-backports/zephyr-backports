# Keys: who signs what, and how anyone checks it

*2026-11-04. Elaboration of `POLICY.md` §7. Comparable to Monero (per-maintainer keys in `utils/gpg_keys/`) and Debian (separate archive signing keys).*

## 1. Roles

| Key | UID | Signs | Where the secret parts live |
|---|---|---|---|
| **Maintainer key** (the maintainer's existing personal key) | pseudonym, existing e-mail address | commits in the forks and the home repo; **certifies** the release key | as now |
| **Release key** `zephyr-backports` | `zephyr-backports <zephyr-backports@lateo.dev>` | tags `vX.Y.Z-sec.N`, `SHA256SUMS`, build manifests | primary (certify-only) offline; signing subkey on the workstation or a hardware token |

Why two: the release key can be handed over and rotated without the maintainer's commit identity changing, and a second maintainer later gets their own commit key while releases keep a single signature. The trust chain stays short: `lateo.dev` → maintainer key → (certification) → release key → tag.

What a signature proves: who made the tag or the file. Not that the content is safe; that is proven by the provenance check, the compatibility tests and the advisories (`POLICY.md` §6).

Mail: `zephyr-backports@lateo.dev` only **receives** (forwarded to the maintainer's mailbox); every reply comes from the maintainer's own address, `loki-notfound@proton.me`, signed with the maintainer key. Encrypted mail goes to the maintainer key, which has an encryption subkey. The release key is sign-only and cannot receive encrypted mail.

## 2. Creating the release key
ed25519, primary for certification only, separate signing subkey, valid for two years.

```bash
gpg --quick-gen-key "zephyr-backports <zephyr-backports@lateo.dev>" ed25519 cert 2y
FPR=$(gpg --list-keys --with-colons zephyr-backports@lateo.dev | awk -F: '/^fpr/{print $10; exit}')
gpg --quick-add-key "$FPR" ed25519 sign 2y
gpg --output zephyr-backports-revoke.asc --gen-revoke "$FPR"      # keep offline, next to the primary
gpg -u <maintainer-key-id> --quick-sign-key "$FPR"                 # certify with the maintainer key
gpg --armor --export "$FPR" > zephyr-backports.asc                 # public key for keys/ and lateo.dev; after the certification
```

Take the primary off the workstation, keep only the subkey:
```bash
gpg --export-secret-keys "$FPR" > zephyr-backports-primary-SECRET.gpg   # store offline (USB/paper), then:
gpg --export-secret-subkeys "$FPR" > subkeys.gpg
gpg --delete-secret-keys "$FPR" && gpg --import subkeys.gpg && shred -u subkeys.gpg
gpg --list-secret-keys "$FPR"     # the primary must now show "sec#" (stub), the subkey "ssb"
```
With a hardware token: `gpg --edit-key "$FPR"` → `key 1` → `keytocard`, and the primary offline all the same.

Notes:
- Run this in a terminal of your own (pinentry), not through an agent.
- GnuPG 2.4 automatically writes `~/.gnupg/openpgp-revocs.d/<FPR>.rev` on creation; that belongs offline too and must leave the workstation afterwards.
- Check the offline backup before the `shred`: import it into a temporary `GNUPGHOME` (`GNUPGHOME=$(mktemp -d) gpg --import zephyr-backports-primary-SECRET.gpg`) and check that `sec` (not `sec#`) appears.
- Test the subkey with a signed tag in a throwaway repo (`git init t && cd t && git commit --allow-empty -m x && git -c user.signingkey="$FPR" tag -s t -m t && git verify-tag t`).
- Expiry reminder: see §7.

## 3. Publishing
1. **Home repo** `zephyr-backports/zephyr-backports`, directory `keys/`:
   ```
   keys/README.md                  roles, fingerprints, verification commands (§5)
   keys/zephyr-backports.asc       release key (public)
   keys/<maintainer>.asc           maintainer key (public)
   keys/wkd/openpgpkey/            ready-to-serve WKD directory for lateo.dev
   ```
   Fingerprints in the main README as well. After a rotation, old keys stay with an `EXPIRED`/`REVOKED` note so that old tags remain verifiable.
2. **`lateo.dev`:** both fingerprints on the placeholder page; WKD entry for `zephyr-backports@lateo.dev`: serve the directory `keys/wkd/openpgpkey/` verbatim as `.well-known/openpgpkey/` (`hu/<hash>` is the binary key, `policy` an empty file, with the header `Access-Control-Allow-Origin: *`; the hash comes from `gpg --with-wkd-hash --fingerprint zephyr-backports@lateo.dev`); in `security.txt` an `Encryption:` line pointing at `keys/loki-notfound.asc` (the maintainer key: the release key has no encryption subkey). Test: `gpg --locate-external-keys zephyr-backports@lateo.dev`.
3. **GitHub:** add the release key to the maintainer's account, with `zephyr-backports@lateo.dev` as a verified e-mail address on that account. Otherwise GitHub shows the tags as "Unverified"; offline they remain verifiable, but the community looks at that badge. Organisation-level domain verification does not count for this; the badge is decided per user account.
4. Optionally `keys.openpgp.org` (verifies the e-mail address); no SKS keyservers.

## 4. Use
Git settings in every fork and in the home repo (commits: maintainer key, i.e. the default `user.signingkey`):
```bash
git config commit.gpgsign true
git config tag.gpgsign true
```
A release:
```bash
FPR=<fingerprint of the release key>
git -c user.signingkey="$FPR" tag -s v2.3.0-sec.1 \
  -m "zephyr v2.3.0 (67c5f53b878fef41fb5e74c4382d5b7a2f37fd8a) + 9 security backports; see SECURITY-BACKPORTS.md"
# artefacts (as soon as they are published through the org):
sha256sum monero_wallet_full.wasm monero_wallet_keys.wasm build-manifest.json > SHA256SUMS
gpg -u "$FPR" --clearsign SHA256SUMS            # -> SHA256SUMS.asc
```
The tag message always names the full upstream sha: upstream signs nothing, so the base can only be pinned through that content-addressed sha.

## 5. Verifying (this is what `keys/README.md` and the home README say, literally)
```bash
gpg --locate-keys zephyr-backports@lateo.dev          # via WKD on lateo.dev
gpg --fingerprint zephyr-backports@lateo.dev          # compare with lateo.dev and keys/README.md
git verify-tag v2.3.0-sec.1                           # the tag
gpg --verify SHA256SUMS.asc && sha256sum -c SHA256SUMS   # the artefacts
```
For the curious: `gpg --check-sigs zephyr-backports@lateo.dev` shows the certification by the maintainer key.

## 6. Hygiene
- Primary and revocation certificate offline, in two places. Never on the workstation or on network storage.
- The subkey expires after 2 years: set a reminder; extend (`gpg --quick-set-expire`) or rotate. Details in §7.
- **Rotation:** certify the new release key with the maintainer key and with the old release key; announce it in the home README and in a message signed with the old key; leave the old key in `keys/`.
- **Compromise:** publish the revocation certificate (home repo, lateo.dev, keyserver), new key as with a rotation, reassess all tags since the last known good moment and re-tag them (`-sec.N+1`), advisory about it.
- A second maintainer later: own commit key, certified by the maintainer key; the release key stays with one person (the release manager) or is replaced by "every release signed by two maintainers". That decision is taken then, not now.

## 7. State and expiry
Created 2026-11-04. Primary `FB39 94F0 997C A6F0 43D7 2491 9EFF 03F5 27D2 40A1` (certify-only), signing subkey `AFCB 1596 42DE 74B6 5D18 3AA2 0937 555B 1B70 815A`, both valid until **2028-11-03**. Certified by the maintainer key `31DA 39AB 43E0 CA67 F1F3 A661 BA2A FF22 DF8A 4A13` (no expiry). WKD hash for `zephyr-backports@lateo.dev`: `pisc8e8b1xjprod7jok65zzkr74rshsr`. Public files: `keys/`. The release key is registered on the maintainer's GitHub account with the address verified.

**Calendar: 2028-10-01.** A month of slack. First test the offline backup (import into a temporary `GNUPGHOME`; `sec` must appear), then choose:

**Extend** (the default, if nothing is wrong). Only the primary may set the expiry, so this happens in a temporary keyring that is discarded afterwards:
```bash
export GNUPGHOME=$(mktemp -d)
gpg --import /offline/zephyr-backports-primary-SECRET.gpg
FPR=FB3994F0997CA6F043D724919EFF03F527D240A1
gpg --quick-set-expire "$FPR" 2y            # primary
gpg --quick-set-expire "$FPR" 2y '*'        # all subkeys
gpg --export-secret-keys "$FPR" > /offline/zephyr-backports-primary-SECRET.gpg   # replace the backup, in both places
gpg --armor --export "$FPR" > zephyr-backports.asc
gpg --export "$FPR" > pisc8e8b1xjprod7jok65zzkr74rshsr                          # new WKD file (binary)
rm -rf "$GNUPGHOME"; unset GNUPGHOME
gpg --import zephyr-backports.asc           # workstation: stub and subkey get the new date
```
Then republish everywhere listed in §3: `keys/zephyr-backports.asc` in the home repo, the WKD file on `lateo.dev`, `keys.openpgp.org`, and on GitHub **delete and re-add** the key (GitHub reads the expiry only at upload). The certification by the maintainer key does not need redoing: it sits on the UID and has no end date of its own.

**Rotate** if something has to change anyway (hardware token, second maintainer, doubt about the backup): new key per §2, certify with the maintainer key and with the old release key, announce with a message signed by the old key, leave the old key in `keys/` marked `EXPIRED`.

**If it expires after all:** old tags remain verifiable (`Good signature`, with the note that the key has expired); new tags are possible again only after extending or rotating. Extending also works after the end date, as long as the offline primary exists. The only real risk is an unreadable backup; hence two places and the test beforehand.
