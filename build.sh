#!/bin/bash
set -e

# Show help
show_help() {
  cat << EOF
ZMK Corne Firmware Build Script

Usage: ./build.sh [OPTIONS]

Options:
  --github    Push to GitHub and trigger GitHub Actions build
              Outputs will be available as artifacts to download to output/github/

  --help      Show this help message

  (no flags)  Build locally using Docker (default)
              Outputs to output/local/ with automatic backups

Examples:
  ./build.sh              # Local Docker build
  ./build.sh --github     # GitHub Actions build

Output Structure:
  output/local/           Latest local Docker builds (consistent names)
  output/github/          GitHub Actions builds (download artifacts here)
  output/backups/         Timestamped backup history

EOF
  exit 0
}

# Parse arguments
USE_GITHUB=false
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  show_help
elif [ "$1" = "--github" ]; then
  USE_GITHUB=true
elif [ -n "$1" ]; then
  echo "Error: Unknown option '$1'"
  echo "Run './build.sh --help' for usage information"
  exit 1
fi

if [ "$USE_GITHUB" = true ]; then
  echo "=== ZMK Corne Firmware Build (GitHub Actions) ==="
  echo ""

  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD --; then
    echo "Error: You have uncommitted changes. Please commit them first."
    echo ""
    echo "Uncommitted changes:"
    git status --short
    exit 1
  fi

  # Get current branch
  BRANCH=$(git branch --show-current)

  echo "Pushing to GitHub to trigger build on branch: $BRANCH"
  git push origin "$BRANCH"

  echo ""
  echo "✓ Pushed to GitHub!"
  echo ""
  echo "GitHub Actions build triggered."
  echo "Monitor progress: https://github.com/$(git remote get-url origin | sed 's/.*github.*://;s/.git$//')/actions"
  echo ""

  # Check if gh CLI is available
  if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) not found. Install it to auto-download artifacts."
    echo ""
    echo "Manual download:"
    echo "  gh run list --limit 1"
    echo "  gh run download <run-id> -n firmware -D output/github"
    exit 0
  fi

  echo "Waiting for build to start..."
  echo ""

  # Wait a moment for GitHub to register the new workflow run
  sleep 5

  # Get the latest run ID (should be our new build)
  LATEST_RUN_ID=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')

  echo "Monitoring build (run #$LATEST_RUN_ID)..."

  # Wait for the run to complete
  while true; do
    RUN_STATUS=$(gh run view "$LATEST_RUN_ID" --json status --jq '.status')
    RUN_CONCLUSION=$(gh run view "$LATEST_RUN_ID" --json conclusion --jq '.conclusion')

    if [ "$RUN_STATUS" = "completed" ]; then
      if [ "$RUN_CONCLUSION" = "success" ]; then
        echo "✓ Build completed successfully!"
        break
      else
        echo "✗ Build failed (conclusion: $RUN_CONCLUSION)"
        echo "Check: https://github.com/$(git remote get-url origin | sed 's/.*github.*://;s/.git$//')/actions/runs/$LATEST_RUN_ID"
        exit 1
      fi
    elif [ "$RUN_STATUS" = "in_progress" ] || [ "$RUN_STATUS" = "queued" ]; then
      echo "  Status: $RUN_STATUS - waiting..."
      sleep 10
    else
      echo "✗ Unexpected status: $RUN_STATUS"
      echo "Check: https://github.com/$(git remote get-url origin | sed 's/.*github.*://;s/.git$//')/actions/runs/$LATEST_RUN_ID"
      exit 1
    fi
  done

  RUN_ID="$LATEST_RUN_ID"

  echo ""
  echo "Downloading artifacts to output/github/..."

  # Backup existing files if present
  if [ -d "output/github" ] && [ -n "$(ls -A output/github 2>/dev/null)" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="output/backups-github/${TIMESTAMP}"
    mkdir -p "$BACKUP_DIR"
    echo "Backing up previous GitHub build to $BACKUP_DIR..."
    mv output/github/* "$BACKUP_DIR/"
  else
    mkdir -p output/github
  fi

  # Download to temp directory first
  TEMP_DIR=$(mktemp -d)
  gh run download "$RUN_ID" -n firmware -D "$TEMP_DIR"

  # Rename files to match local naming convention
  echo "Renaming files to match local convention..."
  mv "$TEMP_DIR/eyeslash_corne_central_dongle_oled.uf2" "output/github/dongle.uf2"
  mv "$TEMP_DIR/"eyeslash_corne_peripheral_left*".uf2" "output/github/left.uf2"
  mv "$TEMP_DIR/"eyeslash_corne_peripheral_right*".uf2" "output/github/right.uf2"

  # Clean up temp directory
  rm -rf "$TEMP_DIR"

  echo ""
  echo "=== Build Complete! ==="
  echo "Firmware downloaded to: output/github/"
  ls -lh output/github/*.uf2

  exit 0
fi

echo "=== ZMK Corne Firmware Build (Docker Compose) ==="
echo ""

# Check if image exists, pull if not
if ! docker image inspect zmkfirmware/zmk-build-arm:stable &>/dev/null; then
  echo "Pulling ZMK build image..."
  docker pull zmkfirmware/zmk-build-arm:stable
else
  echo "✓ ZMK build image found locally"
fi

# Clean only build output (keep zmk/ modules/ for caching)
echo ""
echo "Cleaning build output..."
rm -rf build/dongle build/left build/right

# Run docker-compose build
echo ""
docker-compose run --rm build-all

# Create output directories
mkdir -p output/local
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Backup existing firmware if present
if [ -f "output/local/dongle.uf2" ]; then
  echo ""
  echo "Backing up previous firmware..."
  BACKUP_DIR="output/backups/$(stat -f %Sm -t %Y%m%d_%H%M%S output/local/dongle.uf2)"
  mkdir -p "$BACKUP_DIR"
  mv output/local/dongle.uf2 "$BACKUP_DIR/"
  mv output/local/left.uf2 "$BACKUP_DIR/"
  mv output/local/right.uf2 "$BACKUP_DIR/"
  echo "✓ Backed up to $BACKUP_DIR"
fi

echo ""
echo "Copying firmware to output/local/..."
cp build/dongle/zephyr/zmk.uf2 "output/local/dongle.uf2"
cp build/left/zephyr/zmk.uf2 "output/local/left.uf2"
cp build/right/zephyr/zmk.uf2 "output/local/right.uf2"

# Also save timestamped copy in backups
BACKUP_DIR="output/backups/${TIMESTAMP}"
mkdir -p "$BACKUP_DIR"
cp output/local/dongle.uf2 "$BACKUP_DIR/"
cp output/local/left.uf2 "$BACKUP_DIR/"
cp output/local/right.uf2 "$BACKUP_DIR/"

echo ""
echo "=== Build Complete! ==="
echo "Firmware:        output/local/{dongle,left,right}.uf2"
echo "Backup saved to: $BACKUP_DIR"
