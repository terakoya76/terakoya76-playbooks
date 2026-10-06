#!/usr/bin/env bash

set -eux -o pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[[ "$TOOL" != "WebFetch" ]] && exit 0
URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty' 2>/dev/null)
[ -z "$URL" ] && exit 0
DOMAIN=$(echo "$URL" | sed -E 's|^https?://||' | sed 's|/.*||' | sed 's|:.*||')
[ -z "$DOMAIN" ] && exit 0
ALLOW_ALL=true
ALLOWED=("docs.anthropic.com" "github.com" "developer.mozilla.org")

if [ "$ALLOW_ALL" = "true" ]; then
  jq -n '{ hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "allow" } }'
  exit 0
fi

for d in "${ALLOWED[@]}"; do
  [ "$DOMAIN" = "$d" ] && jq -n '{ hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "allow" } }' && exit 0
done

exit 0  # Not matched — falls through to normal permission prompt
