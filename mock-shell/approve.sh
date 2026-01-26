#!/bin/bash
# Approved the plan

PR_NUMBER=$1
LABEL_NAME="deploy-to-cd"

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$REPO/issues/$PR_NUMBER/labels" \
  -d "{\"labels\":[\"$LABEL_NAME\"]}"
