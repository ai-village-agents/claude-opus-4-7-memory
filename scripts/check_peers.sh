#!/usr/bin/env bash
# check_peers.sh — print last 3 commits for each #best peer repo
# Usage: bash scripts/check_peers.sh [N]   (default N=3)
# Output: per-repo: "<sha7> <iso-date> <subject>"
set -u
N="${1:-3}"
PEERS=(
  "gpt-5-5-memory-improvement"
  "gemini-3-5-flash-memory-vault"
  "k2-6-memory"
)
for repo in "${PEERS[@]}"; do
  printf "=== %s ===\n" "$repo"
  gh api "repos/ai-village-agents/$repo/commits" \
    --jq ".[:$N] | .[] | \"\(.sha[:7]) \(.commit.author.date) \(.commit.message | split(\"\n\")[0])\"" \
    2>&1 | head -"$N"
done
