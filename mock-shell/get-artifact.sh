#!/bin/bash
# Polling GitHub for approval label, then downloading artifacts into a SHA-named folder

source "$(dirname "$0")/.env"

REPO="GGital/terraform-opstella"
INTERVAL=30
MAX_RETRIES=20
RETRY_COUNT=0
ARTIFACT_NAME="terraform-plan-output"
APPROVAL_LABEL="waiting-for-approval"

until [ $RETRY_COUNT -ge $MAX_RETRIES ]; do 
  echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES: Scanning for all PRs with label '$APPROVAL_LABEL'..."

  # 1. Fetch all open PRs with the specific label
  # We use curl to avoid 'gh command not found' issues
  PR_LIST_JSON=$(curl -s -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/pulls?state=open")

  # Extract a simplified list of PR Numbers and their Head SHAs
  # Filter: only include PRs that have a label matching $APPROVAL_LABEL
  PR_MATCHES=$(echo "$PR_LIST_JSON" | jq -c --arg LABEL "$APPROVAL_LABEL" \
    '.[] | select(.labels | any(.name == $LABEL)) | {number: .number, sha: .head.sha}')

  if [ -z "$PR_MATCHES" ]; then
    echo "No PRs found with the '$APPROVAL_LABEL' label."
  else
    echo "Found PRs matching label. Checking for artifacts..."
    
    # 2. Fetch the global artifact list for the repo
    ARTIFACT_RESPONSE=$(curl -s -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/repos/$REPO/actions/artifacts")

    # 3. Iterate through each matching PR
    FOUND_ALL=true
    while read -r pr; do
      PR_NUM=$(echo "$pr" | jq -r '.number')
      PR_SHA=$(echo "$pr" | jq -r '.sha')
      
      echo "Processing PR #$PR_NUM (SHA: $PR_SHA)..."

      # Find the artifact matching this specific SHA
      ARTIFACT_ID=$(echo "$ARTIFACT_RESPONSE" | jq -r --arg NAME "$ARTIFACT_NAME" --arg SHA "$PR_SHA" \
        '.artifacts | map(select(.name == $NAME and .workflow_run.head_sha == $SHA)) | max_by(.created_at) | .id // empty')

      if [ -n "$ARTIFACT_ID" ]; then
        TARGET_DIR="./run-$PR_NUM"
        if [ ! -d "$TARGET_DIR" ]; then
          echo "  -> Downloading artifact for PR #$PR_NUM into $TARGET_DIR..."
          mkdir -p "$TARGET_DIR"
          
          curl -L -s -H "Authorization: Bearer $GITHUB_TOKEN" -o "temp_$PR_SHA.zip" \
            "https://api.github.com/repos/$REPO/actions/artifacts/$ARTIFACT_ID/zip"
          
          unzip -q -o "temp_$PR_SHA.zip" -d "$TARGET_DIR"
          rm "temp_$PR_SHA.zip"
          echo "  -> Extraction complete."
        else
          echo "  -> Directory for SHA $PR_SHA already exists. Skipping download."
        fi
      else
        echo "  -> Artifact for PR #$PR_NUM not ready yet."
        FOUND_ALL=false
      fi
    done <<< "$PR_MATCHES"

    # If we successfully found/downloaded artifacts for ALL labeled PRs, we can exit
    if [ "$FOUND_ALL" = true ]; then
      echo "All approved artifacts have been processed successfully."
      exit 0
    fi
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "Retrying in $INTERVAL seconds..."
  sleep $INTERVAL
done

echo "Error: Timed out. Some artifacts may not have been found."
exit 1