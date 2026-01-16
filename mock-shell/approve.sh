#!/bin/bash
# Approved the plan

source "$(dirname "$0")/.env"

curl -s -X POST -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/GGital/terraform-opstella/dispatches \
  -d '{"event_type":"gate-approved"}'
