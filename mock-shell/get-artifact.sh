#!/bin/bash
# Polling github API to check if artifacts is available for download

source "$(dirname "$0")/.env"

REPO="GGital/terraform-opstella"
INTERVAL=30
MAX_RETRIES=20
RETRY_COUNT=0
ARTIFACT_NAME="terraform-plan-output"

until [ $RETRY_COUNT -ge $MAX_RETRIES ]; do 

  echo "Trying to fetch artifact (Attempt: $((RETRY_COUNT + 1))/$MAX_RETRIES)..."

  RESPONSE=$(curl -s -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    https://api.github.com/repos/$REPO/actions/artifacts)
  
  ARTIFACT_ID=$(echo $RESPONSE | jq -r --arg NAME "$ARTIFACT_NAME" '.artifacts | map(select(.name == $NAME)) | max_by(.created_at) | .id')

  if [ -n "$ARTIFACT_ID" ]; then
    echo "Artifact '$ARTIFACT_NAME' found with ID: $ARTIFACT_ID"

    # After the artifact is found, download it

    DOWNLOAD_URL="https://api.github.com/repos/$REPO/actions/artifacts/$ARTIFACT_ID/zip"
    curl -L -s -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -o "${ARTIFACT_NAME}.zip" \
      $DOWNLOAD_URL

    # Unzip the downloaded artifact
    unzip -o "${ARTIFACT_NAME}.zip" -d "./${ARTIFACT_NAME}"

    exit 0

  else
    echo "Artifact '$ARTIFACT_NAME' not found. Retrying in $INTERVAL seconds..."
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep $INTERVAL
  fi
done