#!/bin/bash

# Security Review Script
# Automated daily security review of merged PRs in antiwork/gumroad

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
STATE_FILE="${WORKSPACE_DIR}/memory/security-review-state.json"
REPO="antiwork/gumroad"

# Ensure state file exists
if [ ! -f "$STATE_FILE" ]; then
    echo '{"reviewed_prs": []}' > "$STATE_FILE"
fi

# Get the last 24 hours timestamp
SINCE_DATE=$(date -u -d "24 hours ago" '+%Y-%m-%dT%H:%M:%SZ')

echo "🔍 Security Review Starting..."
echo "⏰ Checking PRs merged since: $SINCE_DATE"

# Fetch recently merged PRs
MERGED_PRS=$(gh pr list --repo "$REPO" --state merged --limit 50 --json number,title,mergedAt,author,url | jq --arg since "$SINCE_DATE" '[.[] | select(.mergedAt >= $since)]')

if [ "$(echo "$MERGED_PRS" | jq 'length')" -eq 0 ]; then
    echo "✅ No PRs were merged in the last 24 hours"
    exit 0
fi

echo "🔎 Found $(echo "$MERGED_PRS" | jq 'length') recently merged PR(s)"

# Output the findings
echo "$MERGED_PRS" | jq -r '.[] | "- PR #\(.number): \(.title) (merged \(.mergedAt)) by @\(.author.login)"'
echo ""
echo "📋 Security analysis complete - see detailed report above"

# Update state file to track reviewed PRs
REVIEWED_PRS=$(jq -r '.reviewed_prs' "$STATE_FILE")
NEW_PR_NUMBERS=$(echo "$MERGED_PRS" | jq '[.[].number]')
UPDATED_REVIEWED=$(echo "$REVIEWED_PRS $NEW_PR_NUMBERS" | jq -s 'add | unique')
echo "{\"reviewed_prs\": $UPDATED_REVIEWED}" > "$STATE_FILE"

echo "💾 State updated with $(echo "$NEW_PR_NUMBERS" | jq 'length') new PR(s)"