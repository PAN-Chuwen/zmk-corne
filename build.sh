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

  # Check if gh CLI is available
  if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) not found. Install it first:"
    echo "  brew install gh"
    exit 1
  fi

  # Check if we need to push
  NEED_PUSH=false
  if ! git diff-index --quiet HEAD --; then
    echo "You have uncommitted changes. Commit and push before downloading."
    echo ""
    git status --short
    echo ""
    read -p "Do you want to commit, push, and wait for build? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      NEED_PUSH=true
    else
      echo "Cancelled."
      exit 1
    fi
  fi

  # Check if local is ahead of remote
  LOCAL_HEAD=$(git rev-parse HEAD)
  REMOTE_HEAD=$(git rev-parse @{u} 2>/dev/null || echo "")

  if [ "$NEED_PUSH" = false ] && [ -n "$REMOTE_HEAD" ] && [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
    echo "Local branch is ahead of remote. Push required."
    NEED_PUSH=true
  fi

  if [ "$NEED_PUSH" = true ]; then
    BRANCH=$(git branch --show-current)
    echo "Pushing to GitHub to trigger build on branch: $BRANCH"
    git push origin "$BRANCH"
    echo ""
    echo "✓ Pushed to GitHub!"
    echo ""
    echo "Waiting for build to start..."
    sleep 5

    # Get the latest run ID (should be our new build)
    LATEST_RUN_ID=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
    echo "Monitoring build (run #$LATEST_RUN_ID)..."

    # Wait for the run to complete
    while true; do
      if ! RUN_STATUS=$(gh run view "$LATEST_RUN_ID" --json status --jq '.status' 2>/dev/null); then
        echo "  Network error - retrying in 5s..."
        sleep 5
        continue
      fi

      if ! RUN_CONCLUSION=$(gh run view "$LATEST_RUN_ID" --json conclusion --jq '.conclusion' 2>/dev/null); then
        RUN_CONCLUSION="null"
      fi

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
        exit 1
      fi
    done

    RUN_ID="$LATEST_RUN_ID"
  else
    # No push needed, use latest successful run
    echo "Local is up to date with remote. Using latest successful run."
    echo ""

    # Get the latest successful run
    RUN_ID=$(gh run list --limit 5 --json databaseId,status,conclusion --jq '.[] | select(.status == "completed" and .conclusion == "success") | .databaseId' | head -1)

    if [ -z "$RUN_ID" ]; then
      echo "Error: No successful runs found. Push changes first:"
      echo "  git push"
      exit 1
    fi

    echo "Using run #$RUN_ID"
  fi

  echo ""
  echo "Downloading artifacts..."

  # Create clean output directory
  mkdir -p output/github
  rm -rf output/github/*

  # Download artifacts
  gh run download "$RUN_ID" -D output/github/

  # Check what we downloaded
  echo ""
  echo "Downloaded files:"
  ls -lh output/github/

  # Rename files if they're in firmware subdirectory
  if [ -d "output/github/firmware" ]; then
    echo ""
    echo "Renaming files to match local convention..."

    # Find and rename files
    DONGLE=$(find output/github/firmware -name "*dongle*.uf2" -type f)
    LEFT=$(find output/github/firmware -name "*left*.uf2" -type f)
    RIGHT=$(find output/github/firmware -name "*right*.uf2" -type f)

    if [ -n "$DONGLE" ]; then
      cp "$DONGLE" output/github/dongle.uf2
    fi
    if [ -n "$LEFT" ]; then
      cp "$LEFT" output/github/left.uf2
    fi
    if [ -n "$RIGHT" ]; then
      cp "$RIGHT" output/github/right.uf2
    fi

    # Keep firmware directory for reference
    echo "✓ Renamed to: dongle.uf2, left.uf2, right.uf2"
  fi

  echo ""
  echo "=== Download Complete! ==="
  echo "Firmware available at:"
  ls -lh output/github/*.uf2 2>/dev/null || echo "  output/github/firmware/"

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

# Clean build output completely (CMake cache causes issues when changing shields)
echo ""
echo "Cleaning build output..."
rm -rf build/

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
