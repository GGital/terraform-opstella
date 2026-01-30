#!/bin/bash
# Trigger the before approve pipeline

source "$(dirname "$0")/.env"

REPO="GGital/terraform-opstella"
BRANCH_NAME="two_workflow"

gh workflow run pipeline-caller.yml --ref "$BRANCH_NAME"