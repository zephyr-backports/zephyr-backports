#!/usr/bin/env bash
# Cherry-pick Monero commits into a Zephyr fork, in order, with provenance.
#
#   tools/backport.sh <fork-dir> <list-file> [--only sec.1] [--dry-run]     fork-dir e.g. ~/github/zephyr-backports/zephyr
#
# list-file: backports/<base>.txt  (lines "<sha> <release> <class> <status> <description>")
# --only     pick only lines whose release column matches
# --dry-run  pick cumulatively on a throwaway branch (later picks see earlier ones, like the real
#            run), report CLEAN/CONFLICT with hunk counts, then delete the branch
#
# Rules enforced here (docs/POLICY.md §5): `git cherry-pick -x` only; the sha must be reachable
# from monero/release-v0.18; on a conflict the script STOPS and leaves the conflict for a human
# (resolve context-only, add the trailer "Conflicts: <files> (context only)", then re-run).
# A successful real pick marks its line "picked" in the list file.
set -euo pipefail
FORK=${1:?fork dir}; LIST=${2:?list file}; shift 2
ONLY=""; DRY=0
while [ $# -gt 0 ]; do case "$1" in --only) ONLY=$2; shift 2;; --dry-run) DRY=1; shift;; *) echo "unknown arg $1"; exit 2;; esac; done
LIST=$(cd "$(dirname "$LIST")" && pwd)/$(basename "$LIST")

cd "$FORK"
git remote get-url monero >/dev/null 2>&1 || git remote add monero https://github.com/monero-project/monero.git
git fetch -q monero release-v0.18
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

clean=0; conf=0
while read -r sha rel cls status desc; do
  [ -z "$sha" ] || [ "${sha:0:1}" = "#" ] && continue
  [ -n "$ONLY" ] && [ "$rel" != "$ONLY" ] && continue
  [ "$status" = "picked" ] && continue
  [ "$rel" = "skip" ] && continue
  git merge-base --is-ancestor "$sha" monero/release-v0.18 || { echo "NOT ON monero/release-v0.18: $sha"; exit 1; }
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
