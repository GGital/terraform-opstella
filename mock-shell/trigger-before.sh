#!/bin/bash
# Trigger the before approve pipeline

source "$(dirname "$0")/.env"

REPO="GGital/terraform-opstella"
BRANCH_NAME="two_workflow"

curl -s -X POST -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/$REPO/dispatches \
  -d "{
    \"event_type\": \"before-approve\",
    \"client_payload\": {
      \"branch\": \"$BRANCH_NAME\"
    }
  }"