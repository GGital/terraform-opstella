#!/bin/bash
# Approved the plan

source "$(dirname "$0")/.env"

REPO="GGital/terraform-opstella"
BRANCH_NAME="two_workflow"

gh workflow run after-gate.yml --ref "$BRANCH_NAME"