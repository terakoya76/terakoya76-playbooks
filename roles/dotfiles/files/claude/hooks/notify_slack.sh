#!/usr/bin/env bash

set -eux -o pipefail

if [[ -z "${SLACK_TOKEN}" ]]; then
  exit 1
fi

message="$1"
curl -X POST https://slack.com/api/chat.postMessage \
    -H "Authorization: Bearer $SLACK_TOKEN" \
    -H "Content-type: application/json" \
    --data "{
        \"channel\": \"#claude-code\",
        \"text\": \"${message}\"
    }"
