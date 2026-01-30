#!/bin/bash
# Sync script: Downloads all un-retrieved artifacts from the last 3 days

source "$(dirname "$0")/.env"

REPO="GGital/terraform-opstella"
WORKFLOW_FILE="pipeline-caller.yml"
ARTIFACT_NAME="terraform-plan-output"

# Calculate the timestamp for 3 days ago (ISO 8601 format for GitHub API)
# Works on both Linux and macOS/WSL
if [[ "$OSTYPE" == "darwin"* ]]; then
    THREE_DAYS_AGO=$(date -v-3d -u +"%Y-%m-%dT%H:%M:%SZ")
else
    THREE_DAYS_AGO=$(date -u -d "3 days ago" +"%Y-%m-%dT%H:%M:%SZ")
fi

echo "Checking for completed runs since: $THREE_DAYS_AGO"

# 1. Fetch all completed runs for the workflow created after the timestamp
RUNS_JSON=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO/actions/workflows/$WORKFLOW_FILE/runs?status=completed&created=%3E$THREE_DAYS_AGO")

# Extract only the Run IDs
RUN_IDS=$(echo "$RUNS_JSON" | jq -r '.workflow_runs[].id')

if [ -z "$RUN_IDS" ] || [ "$RUN_IDS" == "null" ]; then
    echo "No completed runs found in the last 3 days."
    exit 0
fi

for RUN_ID in $RUN_IDS; do
    TARGET_DIR="./run-${RUN_ID}"

    # 2. Check if we already have this run's data
    if [ -d "$TARGET_DIR" ]; then
        echo "Skipping Run ID: $RUN_ID (Already retrieved)"
        continue
    fi

    echo "Processing Run ID: $RUN_ID..."

    # 3. Get the artifact ID for this specific run
    ARTIFACT_RESPONSE=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/artifacts")
    
    ARTIFACT_ID=$(echo "$ARTIFACT_RESPONSE" | jq -r --arg NAME "$ARTIFACT_NAME" '.artifacts | map(select(.name == $NAME)) | .[0].id // empty')

    if [ -z "$ARTIFACT_ID" ]; then
        echo "  - No artifact named '$ARTIFACT_NAME' found for this run. Skipping."
        continue
    fi

    # 4. Download and Extract
    echo "  - Found artifact $ARTIFACT_ID. Downloading to $TARGET_DIR..."
    mkdir -p "$TARGET_DIR"
    
    curl -L -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      -o "${TARGET_DIR}/${ARTIFACT_NAME}.zip" \
      "https://api.github.com/repos/$REPO/actions/artifacts/$ARTIFACT_ID/zip"

    unzip -o -q "${TARGET_DIR}/${ARTIFACT_NAME}.zip" -d "$TARGET_DIR"
    rm "${TARGET_DIR}/${ARTIFACT_NAME}.zip"
    
    echo "  - Successfully retrieved Run $RUN_ID."
done

echo "Sync complete."