#!/usr/bin/env bash
# Provenance check for a security fork (runs in the fork's CI and locally).
#
#   tools/check-provenance.sh <fork-dir> <upstream-tag>      e.g. ~/github/zephyr-backports/zephyr v2.3.0
#
# Every commit above the upstream tag must be either
#   (a) a cherry-pick: body contains "(cherry picked from commit <sha>)" and that sha is
#       reachable from monero/release-v0.18, or
#   (b) an allowed own commit: touches only README.md, SECURITY-BACKPORTS.md, .github/**,
#       VERSIONTAG, and carries the trailer "Origin: zephyr-backports".
# Anything else fails. Also checks that every cherry-picked sha is listed in SECURITY-BACKPORTS.md.
set -euo pipefail
FORK=${1:?fork dir}; BASE=${2:?upstream tag}
cd "$FORK"
git fetch -q monero release-v0.18 2>/dev/null || true
fail=0
for c in $(git rev-list --reverse "$BASE..HEAD"); do
  body=$(git log -1 --format=%B "$c")
  subj=$(git log -1 --format=%s "$c")
  if origin=$(printf '%s' "$body" | grep -oE '\(cherry picked from commit [0-9a-f]{40}\)' | grep -oE '[0-9a-f]{40}' | head -1) && [ -n "$origin" ]; then
    if git merge-base --is-ancestor "$origin" monero/release-v0.18 2>/dev/null; then
      grep -q "${origin:0:9}" SECURITY-BACKPORTS.md 2>/dev/null && st="ok" || { st="NOT IN SECURITY-BACKPORTS.md"; fail=1; }
      printf 'pick  %s  from monero %s  %s  [%s]\n' "${c:0:9}" "${origin:0:9}" "$subj" "$st"
    else
      printf 'FAIL  %s  origin %s not on monero/release-v0.18  %s\n' "${c:0:9}" "${origin:0:9}" "$subj"; fail=1
    fi
  else
    files=$(git show --format= --name-only "$c")
    bad=$(printf '%s\n' "$files" | grep -vE '^(README\.md|SECURITY-BACKPORTS\.md|\.github/.*|VERSIONTAG)$' || true)
    if [ -z "$bad" ] && printf '%s' "$body" | grep -q '^Origin: zephyr-backports'; then
      printf 'own   %s  %s  (allowed files)\n' "${c:0:9}" "$subj"
    else
      printf 'FAIL  %s  own commit touching disallowed files or missing Origin trailer: %s\n' "${c:0:9}" "$subj"
      printf '%s\n' "$bad" | sed 's/^/        /'; fail=1
    fi
  fi
done
[ "$fail" = 0 ] && echo "provenance OK" || { echo "provenance FAILED"; exit 1; }
