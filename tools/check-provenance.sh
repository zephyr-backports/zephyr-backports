#!/usr/bin/env bash
# Provenance check for a security fork (runs in the fork's CI and locally).
#
#   tools/check-provenance.sh <fork-dir> <upstream-tag>      e.g. ~/github/zephyr-backports/zephyr v2.3.0
#
# Every commit above the upstream tag must be either
#   (a) a cherry-pick: body contains "(cherry picked from commit <sha>)" and that sha is
#       reachable from the fork's upstream branch (monero release-v0.18 for zephyr, woodser's
#       monero-cpp / monero-ts master for zephyr-cpp / zephyr-javascript), or
#   (b) an allowed own commit: touches only README.md, SECURITY-BACKPORTS.md, .github/**,
#       VERSIONTAG, and carries the trailer "Origin: zephyr-backports", or
#   (c) a dependency pin (package.json + lockfile only, trailers Origin + "Advisory: <id>"), or
#   (d) an artefact rebuild (dist/** or client/public/** only, trailers Origin + one
#       "Built-From: <repo> <tag> <sha>" per source); both per POLICY §5.
# Anything else fails. Also checks that every cherry-picked sha is listed in SECURITY-BACKPORTS.md.
set -euo pipefail
FORK=${1:?fork dir}; BASE=${2:?upstream tag}
cd "$FORK"
# upstream per fork (same mapping as backport.sh); env UP_REMOTE/UP_URL/UP_BRANCH override
case "$(basename "$(git remote get-url origin 2>/dev/null || pwd)" .git)" in
  zephyr-cpp)        d="monero-cpp https://github.com/woodser/monero-cpp.git master" ;;
  zephyr-javascript) d="monero-ts https://github.com/woodser/monero-ts.git master" ;;
  *)                 d="monero https://github.com/monero-project/monero.git release-v0.18" ;;
esac
read -r dr du db <<<"$d"; UP_REMOTE=${UP_REMOTE:-$dr}; UP_URL=${UP_URL:-$du}; UP_BRANCH=${UP_BRANCH:-$db}
git remote get-url "$UP_REMOTE" >/dev/null 2>&1 || git remote add "$UP_REMOTE" "$UP_URL"
git fetch -q "$UP_REMOTE" "$UP_BRANCH" 2>/dev/null || true
UP_REF="$UP_REMOTE/$UP_BRANCH"
fail=0
for c in $(git rev-list --reverse "$BASE..HEAD"); do
  body=$(git log -1 --format=%B "$c")
  subj=$(git log -1 --format=%s "$c")
  if origin=$(printf '%s' "$body" | grep -oE '\(cherry picked from commit [0-9a-f]{40}\)' | grep -oE '[0-9a-f]{40}' | head -1) && [ -n "$origin" ]; then
    if git merge-base --is-ancestor "$origin" "$UP_REF" 2>/dev/null; then
      grep -q "${origin:0:9}" SECURITY-BACKPORTS.md 2>/dev/null && st="ok" || { st="NOT IN SECURITY-BACKPORTS.md"; fail=1; }
      printf 'pick  %s  from %s %s  %s  [%s]\n' "${c:0:9}" "$UP_REMOTE" "${origin:0:9}" "$subj" "$st"
    else
      printf 'FAIL  %s  origin %s not on %s  %s\n' "${c:0:9}" "${origin:0:9}" "$UP_REF" "$subj"; fail=1
    fi
  else
    files=$(git show --format= --name-only "$c")
    has_origin=0; printf '%s' "$body" | grep -q '^Origin: zephyr-backports' && has_origin=1
    # (1) the fork's own files
    bad=$(printf '%s\n' "$files" | grep -vE '^(README\.md|SECURITY-BACKPORTS\.md|\.github/.*|VERSIONTAG)$' || true)
    # (2) dependency pin: package.json + lockfile only, with an Advisory trailer (POLICY §5)
    bad_dep=$(printf '%s\n' "$files" | grep -vE '(^|/)(package\.json|package-lock\.json)$' || true)
    has_adv=0; printf '%s' "$body" | grep -qE '^Advisory: (GHSA-[A-Za-z0-9-]+|CVE-[0-9]{4}-[0-9]+)' && has_adv=1
    # (3) artefact rebuild: dist/** or client/public/** only, with Built-From trailers (POLICY §5)
    bad_art=$(printf '%s\n' "$files" | grep -vE '^(dist/.*|client/public/.*)$' || true)
    has_built=0; printf '%s' "$body" | grep -qE '^Built-From: \S+ \S+ [0-9a-f]{40}$' && has_built=1
    if [ "$has_origin" = 1 ] && [ -z "$bad" ]; then
      printf 'own   %s  %s  (allowed files)\n' "${c:0:9}" "$subj"
    elif [ "$has_origin" = 1 ] && [ -z "$bad_dep" ] && [ "$has_adv" = 1 ]; then
      printf 'pin   %s  %s  (dependency pin, %s)\n' "${c:0:9}" "$subj" "$(printf '%s' "$body" | grep -oE '^Advisory: \S+' | head -1)"
    elif [ "$has_origin" = 1 ] && [ -z "$bad_art" ] && [ "$has_built" = 1 ]; then
      printf 'build %s  %s  (artefact rebuild, %s)\n' "${c:0:9}" "$subj" "$(printf '%s' "$body" | grep -cE '^Built-From: ') source(s)"
    else
      printf 'FAIL  %s  own commit outside the allowed types (files, Origin/Advisory/Built-From trailers): %s\n' "${c:0:9}" "$subj"
      printf '%s\n' "$files" | sed 's/^/        /'; fail=1
    fi
  fi
done
[ "$fail" = 0 ] && echo "provenance OK" || { echo "provenance FAILED"; exit 1; }
