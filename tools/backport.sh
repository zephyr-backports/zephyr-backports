#!/usr/bin/env bash
# Cherry-pick upstream commits into a fork, in order, with provenance.
#
#   tools/backport.sh <fork-dir> <list-file> [--only sec.1] [--dry-run]     fork-dir e.g. ~/github/zephyr-backports/zephyr
#
# list-file: backports/<base>.txt  (lines "<sha> <release> <class> <status> <description>")
#            an optional header line "# upstream: <remote-name> <url> <branch>" names the upstream
#            the shas must be reachable from; without it the fork's name decides (see upstream_for).
# --only     pick only lines whose release column matches
# --dry-run  pick cumulatively on a throwaway branch (later picks see earlier ones, like the real
#            run), report CLEAN/CONFLICT with hunk counts, then delete the branch
#
# Rules enforced here (docs/POLICY.md §5): `git cherry-pick -x` only; the sha must be reachable
# from the upstream branch; on a conflict the script STOPS and leaves the conflict for a human
# (resolve context-only, add the trailer "Conflicts: <files> (context only)", then re-run).
# A successful real pick marks its line "picked" in the list file.
set -euo pipefail
FORK=${1:?fork dir}; LIST=${2:?list file}; shift 2
ONLY=""; DRY=0
while [ $# -gt 0 ]; do case "$1" in --only) ONLY=$2; shift 2;; --dry-run) DRY=1; shift;; *) echo "unknown arg $1"; exit 2;; esac; done
LIST=$(cd "$(dirname "$LIST")" && pwd)/$(basename "$LIST")

# upstream per fork: "<remote> <url> <branch>"; the list header overrides
upstream_for() {
  case "$(basename "$(git -C "$1" remote get-url origin 2>/dev/null || basename "$1")" .git)" in
    zephyr-cpp)        echo "monero-cpp https://github.com/woodser/monero-cpp.git master" ;;
    zephyr-javascript) echo "monero-ts https://github.com/woodser/monero-ts.git master" ;;
    zephyr-wallet)     echo "haven https://github.com/haven-protocol-org/haven-web-app.git master" ;;
    *)                 echo "monero https://github.com/monero-project/monero.git release-v0.18 master" ;;   # master only for the counterpart case of POLICY §2
  esac
}
hdr=$(grep -m1 -E '^# upstream: ' "$LIST" | sed 's/^# upstream: //' || true)
read -r UP_REMOTE UP_URL UP_BRANCH <<<"${hdr:-$(upstream_for "$FORK")}"   # UP_BRANCH may list several branches
UP_REF=""; for b in $UP_BRANCH; do UP_REF="$UP_REF $UP_REMOTE/$b"; done; UP_REF=${UP_REF# }
on_upstream() { local r; for r in $UP_REF; do git merge-base --is-ancestor "$1" "$r" 2>/dev/null && return 0; done; return 1; }

cd "$FORK"
git remote get-url "$UP_REMOTE" >/dev/null 2>&1 || git remote add "$UP_REMOTE" "$UP_URL"
for b in $UP_BRANCH; do git fetch -q "$UP_REMOTE" "$b"; done
[ -z "$(git status --porcelain)" ] || { echo "fork working tree not clean"; exit 1; }
start_branch=$(git branch --show-current); start=$(git rev-parse HEAD)
cleanup() {
  if [ "$DRY" = 1 ]; then
    git cherry-pick --abort 2>/dev/null || true
    git checkout -q "$start_branch" 2>/dev/null || true
    git branch -q -D "dry-run-$$" 2>/dev/null || true
  fi
}
trap cleanup EXIT
[ "$DRY" = 1 ] && git checkout -q -b "dry-run-$$"
echo "upstream: $UP_REF ($UP_URL)"

clean=0; conf=0
while read -r sha rel cls status desc; do
  [ -z "$sha" ] || [ "${sha:0:1}" = "#" ] && continue
  [ -n "$ONLY" ] && [ "$rel" != "$ONLY" ] && continue
  case "$status" in picked|conflict|skipped) continue;; esac
  [ "$rel" = "skip" ] && continue
  on_upstream "$sha" || { echo "NOT ON $UP_REF: $sha"; exit 1; }
  if git cherry-pick -x --no-edit "$sha" >/dev/null 2>&1; then
    clean=$((clean+1)); printf 'CLEAN     %s %-6s %-8s %s\n' "$sha" "$rel" "$cls" "$desc"
    [ "$DRY" = 1 ] || sed -i -E "s/^($sha +$rel +$cls +)todo /\1picked /" "$LIST"
  else
    n=0; for f in $(git diff --name-only --diff-filter=U); do n=$((n + $(grep -c '^<<<<<<<' "$f" || true))); done
    files=$(git diff --name-only --diff-filter=U | tr '\n' ' ')
    printf 'CONFLICT  %s %-6s %-8s %s  -> %d hunks in %s\n' "$sha" "$rel" "$cls" "$desc" "$n" "$files"
    conf=$((conf+1))
    if [ "$DRY" = 1 ]; then git cherry-pick --abort; else
      trap - EXIT
      echo; echo "Stopped on conflict. Resolve context-only, then:"
      echo "  git add -A && git -c core.editor=true cherry-pick --continue"
      echo "  git commit --amend   # add trailer: Conflicts: ${files}(context only)"
      echo "then mark the line 'picked' in $LIST and re-run this script."; exit 1
    fi
  fi
done < "$LIST"

echo; echo "clean=$clean conflict=$conf  (started at ${start:0:10}, now $(git rev-parse --short HEAD))"
