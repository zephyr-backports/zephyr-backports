#!/usr/bin/env bash
# Apply the branch ruleset of the public zephyr-backports repos (idempotent: replaces a ruleset
# with the same name). Requires `gh` with admin on the org.
#
#   tools/protect.sh <owner/repo> <branch-pattern> <merge-method> <status-context>...
#   e.g. tools/protect.sh zephyr-backports/zephyr-backports '~DEFAULT_BRANCH' squash
#        tools/protect.sh zephyr-backports/.github '~DEFAULT_BRANCH' squash
#        tools/protect.sh zephyr-backports/zephyr 'refs/heads/security/*' rebase 'provenance / provenance'
#
# A new branch matching the pattern (security/v2.3.0 at the upstream tag) may be created without the
# status check (do_not_enforce_on_create); every later change goes through a pull request.
# merge-method (squash | rebase | merge) is the only method the ruleset allows and the only merge
# button left on in the repo settings; it is a guard, the maintainer lands PRs by push (below).
#
# Status-check names: a workflow that runs in the repo itself reports its job name; a reusable
# workflow called from another repo reports "<caller job> / <called job>" ("provenance / provenance").
# A wrong name blocks every merge with "waiting for status to be reported". With no contexts the
# status-check rule is left out. This script stays private (it is not copied to the home repo).
#
# Rules: no deletion, no force push, every change through a pull request, the listed status
# checks must pass on the PR head, every commit signed. Bypass: the organisation owners only
# (POLICY §6: the maintainer lands a checked PR head by fast-forward push, so that every commit on
# the branch is the maintainer-signed commit that was checked; GitHub's own merges rewrite commits
# and cannot sign a rebase). The merge buttons stay restricted to one method as a guard, but are
# not used.
set -euo pipefail
repo=${1:?owner/repo}; pattern=${2:?branch pattern}; method=${3:?merge method: squash|rebase|merge}; shift 3
case "$method" in squash|rebase|merge) ;; *) echo "merge method must be squash, rebase or merge" >&2; exit 2;; esac
name="protect ${pattern#refs/heads/}"
checks=$(printf '%s\n' "$@" | python3 -c 'import json,sys; print(json.dumps([{"context": l.rstrip("\n")} for l in sys.stdin if l.strip()]))')
status_rule=""
[ "$checks" = "[]" ] || status_rule=",
    { \"type\": \"required_status_checks\", \"parameters\": {
        \"strict_required_status_checks_policy\": true,
        \"do_not_enforce_on_create\": true,
        \"required_status_checks\": $checks } }"
body=$(cat <<EOF
{
  "name": "$name",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [ { "actor_id": 1, "actor_type": "OrganizationAdmin", "bypass_mode": "always" } ],
  "conditions": { "ref_name": { "include": ["$pattern"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_signatures" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["$method"] } }$status_rule
  ]
}
EOF
)
existing=$(gh api "repos/$repo/rulesets" --jq ".[] | select(.name == \"$name\") | .id" 2>/dev/null || true)
if [ -n "$existing" ]; then
  gh api -X PUT "repos/$repo/rulesets/$existing" --input - <<<"$body" --jq '"updated ruleset \(.id) \(.name) on '"$repo"'"'
else
  gh api -X POST "repos/$repo/rulesets" --input - <<<"$body" --jq '"created ruleset \(.id) \(.name) on '"$repo"'"'
fi
# repo settings: only that merge button, delete the head branch after merge
gh repo edit "$repo" --enable-squash-merge="$([ "$method" = squash ] && echo true || echo false)" \
  --enable-rebase-merge="$([ "$method" = rebase ] && echo true || echo false)" \
  --enable-merge-commit="$([ "$method" = merge ] && echo true || echo false)" \
  --delete-branch-on-merge >/dev/null && echo "repo settings: merge method $method only, delete branch on merge"
