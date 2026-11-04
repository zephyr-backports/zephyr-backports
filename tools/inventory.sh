#!/usr/bin/env bash
# Inventory of Monero release-v0.18 commits since a date, minus what the Zephyr tree already has.
#
#   tools/inventory.sh <since-date> [zephyr-dir]      default zephyr-dir: ~/github/zephyr-backports/zephyr
#
# Output: inventory/<date>/commits.tsv (sha, date, subject, dirs) and per-commit file lists in
# inventory/<date>/files/<sha>.txt for commits not already in Zephyr's history (matched by subject).
# Needs: gh (authenticated), git.
set -euo pipefail
SINCE=${1:?since date}; Z=${2:-$HOME/github/zephyr-backports/zephyr}
OUT="$(dirname "$0")/../inventory/$SINCE"; mkdir -p "$OUT/files"
PATHS="src/wallet contrib/epee src/cryptonote_basic src/cryptonote_core src/cryptonote_protocol src/ringct src/crypto src/common src/device src/multisig src/serialization src/net src/mnemonics src/rpc src/p2p src/checkpoints src/hardforks external/randomx external/db_drivers"
: > "$OUT/raw.tsv"
for p in $PATHS; do
  gh api --paginate "repos/monero-project/monero/commits?sha=release-v0.18&since=${SINCE}T00:00:00Z&path=$p&per_page=100" \
    --jq ".[] | [.sha, .commit.author.date[:10], (.commit.message|split(\"\n\")[0]), \"$p\"] | @tsv" >> "$OUT/raw.tsv"
done
git -C "$Z" log --format=%s > "$OUT/zephyr-subjects.txt"
python3 -I - "$OUT" <<'EOF'
import sys, re, collections
out = sys.argv[1]
rows = collections.OrderedDict()
for l in open(f'{out}/raw.tsv'):
    sha, date, subj, p = l.rstrip('\n').split('\t')
    rows.setdefault(sha, [date, subj, set()])[2].add(p)
norm = lambda s: re.sub(r'\s+', ' ', s.strip().lower())
have = {norm(s) for s in open(f'{out}/zephyr-subjects.txt')}
with open(f'{out}/commits.tsv', 'w') as f:
    n = 0
    for sha, (date, subj, ps) in sorted(rows.items(), key=lambda kv: kv[1][0]):
        if subj.startswith('Merge ') or norm(subj) in have: continue
        f.write(f"{sha[:9]}\t{date}\t{subj}\t{','.join(sorted(ps))}\n"); n += 1
print(f"{len(rows)} commits, {n} not merges and not already in zephyr -> {out}/commits.tsv")
EOF
while IFS=$'\t' read -r sha date subj dirs; do
  [ -f "$OUT/files/$sha.txt" ] || gh api "repos/monero-project/monero/commits/$sha" --jq '.files[] | "\(.additions)\t\(.deletions)\t\(.filename)"' > "$OUT/files/$sha.txt"
done < "$OUT/commits.tsv"
echo "per-commit file lists in $OUT/files/"
