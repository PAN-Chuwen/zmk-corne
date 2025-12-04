#!/bin/bash

echo "=== Download Choc Firmware from GitHub Actions ==="
echo ""

REPO="PAN-Chuwen/zmk-choc-corne"
OUTPUT_DIR="output/choc/github"

# Get latest run ID
echo "Fetching latest workflow run..."
RUN_INFO=$(gh run list --repo "$REPO" --limit 1 --json databaseId,status,conclusion,displayTitle 2>/dev/null)

if [ -z "$RUN_INFO" ] || [ "$RUN_INFO" = "[]" ]; then
  echo "Error: No workflow runs found."
  echo ""
  echo "Make sure:"
  echo "  1. GitHub Actions is enabled in the repo"
  echo "  2. A workflow has been triggered (push to main branch)"
  echo ""
  echo "To manually trigger:"
  echo "  gh workflow run build.yml --repo $REPO"
  exit 1
fi

RUN_ID=$(echo "$RUN_INFO" | jq -r '.[0].databaseId')
STATUS=$(echo "$RUN_INFO" | jq -r '.[0].status')
CONCLUSION=$(echo "$RUN_INFO" | jq -r '.[0].conclusion')
TITLE=$(echo "$RUN_INFO" | jq -r '.[0].displayTitle')

echo "Latest run: #$RUN_ID - $TITLE"
echo "Status: $STATUS (conclusion: $CONCLUSION)"
echo ""

if [ "$STATUS" != "completed" ]; then
  echo "Build is still running. Wait for it to complete or watch with:"
  echo "  gh run watch $RUN_ID --repo $REPO"
  exit 1
fi

if [ "$CONCLUSION" != "success" ]; then
  echo "Build failed! Check the logs:"
  echo "  gh run view $RUN_ID --repo $REPO --log"
  exit 1
fi

# Download artifacts
echo "Downloading firmware artifacts..."
rm -rf "$OUTPUT_DIR/firmware" 2>/dev/null
gh run download "$RUN_ID" --repo "$REPO" --dir "$OUTPUT_DIR"

if [ $? -ne 0 ]; then
  echo "Error downloading artifacts!"
  exit 1
fi

echo ""
echo "Downloaded files:"
ls -la "$OUTPUT_DIR/"

# Rename firmware files for easier use
echo ""
echo "Renaming firmware files..."

# Find and rename left firmware (could be studio or regular)
LEFT_FILE=$(find "$OUTPUT_DIR" -name "*left*.uf2" -o -name "*_studio_left*.uf2" | head -1)
RIGHT_FILE=$(find "$OUTPUT_DIR" -name "*right*.uf2" | head -1)
RESET_FILE=$(find "$OUTPUT_DIR" -name "*settings_reset*.uf2" | head -1)

if [ -n "$LEFT_FILE" ]; then
  cp "$LEFT_FILE" "$OUTPUT_DIR/left.uf2"
  echo "  Left:  $OUTPUT_DIR/left.uf2"
fi

if [ -n "$RIGHT_FILE" ]; then
  cp "$RIGHT_FILE" "$OUTPUT_DIR/right.uf2"
  echo "  Right: $OUTPUT_DIR/right.uf2"
fi

if [ -n "$RESET_FILE" ]; then
  cp "$RESET_FILE" "$OUTPUT_DIR/settings_reset.uf2"
  echo "  Reset: $OUTPUT_DIR/settings_reset.uf2"
fi

echo ""
echo "=== Download Complete ==="
echo ""
echo "Firmware ready at: $OUTPUT_DIR/"
echo ""
echo "To flash, run: ./flash-choc.sh"
echo ""
