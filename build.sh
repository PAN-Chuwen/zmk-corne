#!/bin/bash
set -e

# Show help
show_help() {
  cat << EOF
ZMK Corne Firmware Build Script

Usage: ./build.sh [OPTIONS]

Options:
  --github         Download from latest successful GitHub Actions build
                   Outputs will be downloaded to output/github/

  --github --push  Push to GitHub, trigger build, and download when complete

  --dry-run        Show what would happen without executing

  --help           Show this help message

  (no flags)       Build locally using Docker (default)
                   Outputs to output/local/ with automatic backups

Examples:
  ./build.sh                  # Local Docker build
  ./build.sh --dry-run        # Preview local build actions
  ./build.sh --github         # Download from latest GitHub build (no push)
  ./build.sh --github --push --dry-run  # Preview push and build

Output Structure:
  output/local/           Latest local Docker builds (consistent names)
  output/github/          GitHub Actions builds (download artifacts here)
  output/backups/         Timestamped backup history

EOF
  exit 0
}

# Parse arguments
USE_GITHUB=false
ALLOW_PUSH=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h)
      show_help
      ;;
    --github)
      USE_GITHUB=true
      shift
      ;;
    --push)
      ALLOW_PUSH=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Error: Unknown option '$1'"
      echo "Run './build.sh --help' for usage information"
      exit 1
      ;;
  esac
done

if [ "$USE_GITHUB" = true ]; then
  if [ "$DRY_RUN" = true ]; then
    echo "=== ZMK Corne Firmware Build (GitHub Actions) [DRY RUN] ==="
  else
    echo "=== ZMK Corne Firmware Build (GitHub Actions) ==="
  fi
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
    echo "You have uncommitted changes:"
    echo ""
    git status --short
    echo ""

    if [ "$ALLOW_PUSH" = true ]; then
      NEED_PUSH=true
      echo "Will commit and push changes (--push flag provided)"
    else
      echo "Error: Uncommitted changes detected. Options:"
      echo "  1. Commit changes and use --github --push to trigger new build"
      echo "  2. Discard changes and use --github to download latest build"
      exit 1
    fi
  fi

  # Check if local is ahead of remote
  LOCAL_HEAD=$(git rev-parse HEAD)
  REMOTE_HEAD=$(git rev-parse @{u} 2>/dev/null || echo "")

  if [ "$NEED_PUSH" = false ] && [ -n "$REMOTE_HEAD" ] && [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
    if [ "$ALLOW_PUSH" = true ]; then
      echo "Local branch is ahead of remote. Push required."
      NEED_PUSH=true
    else
      echo "Error: Local branch is ahead of remote. Use --push to trigger build:"
      echo "  ./build.sh --github --push"
      exit 1
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    # Dry run mode - just mock everything
    if [ "$NEED_PUSH" = true ]; then
      BRANCH=$(git branch --show-current)
      echo "[DRY RUN] Would push to GitHub branch: $BRANCH"
      echo "[DRY RUN] Would run: git push origin $BRANCH"
      echo ""
      echo "[DRY RUN] Would wait for GitHub Actions build to complete..."
      echo "[DRY RUN] Assuming build succeeds..."
      RUN_ID="MOCK_RUN_ID"
    else
      echo "[DRY RUN] Local is up to date with remote."
      echo "[DRY RUN] Would use latest successful run from GitHub"
      RUN_ID="MOCK_RUN_ID"
    fi
  else
    # Real execution
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
  fi

  echo ""

  # Backup existing files if present
  BACKUP_DIR=""
  if [ -f "output/github/dongle.uf2" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="output/backups/github_${TIMESTAMP}"

    if [ "$DRY_RUN" = true ]; then
      echo "[DRY RUN] Would backup existing files:"
      ls -lh output/github/*.uf2 2>/dev/null
      echo ""
      echo "[DRY RUN] Backup destination: $BACKUP_DIR/"
      echo "[DRY RUN] Would run: mkdir -p $BACKUP_DIR"
      echo "[DRY RUN] Would run: mv output/github/*.uf2 $BACKUP_DIR/"
      echo ""
    else
      echo "Backing up previous GitHub firmware..."
      mkdir -p "$BACKUP_DIR"
      mv output/github/*.uf2 "$BACKUP_DIR/" 2>/dev/null || true
      echo "✓ Backed up to $BACKUP_DIR"
      echo ""
    fi
  fi

  echo "Downloading artifacts..."

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would create directory: output/github/"
    echo "[DRY RUN] Would run: gh run download $RUN_ID -D output/github/"
    echo ""
    echo "[DRY RUN] Expected download structure:"
    echo "  output/github/firmware/eyeslash_corne_central_dongle_oled.uf2"
    echo "  output/github/firmware/eyeslash_corne_peripheral_left_nice_oled-nice_nano_v2-zmk.uf2"
    echo "  output/github/firmware/eyeslash_corne_peripheral_right_nice_oled-nice_nano_v2-zmk.uf2"
    echo "  output/github/firmware/settings_reset-nice_nano_v2-zmk.uf2"
    echo ""
    echo "[DRY RUN] Would extract and rename to:"
    echo "  output/github/dongle.uf2"
    echo "  output/github/left.uf2"
    echo "  output/github/right.uf2"
    echo ""
    echo "[DRY RUN] Would remove: output/github/firmware/"
    echo ""
    echo "[DRY RUN] Final structure:"
    echo "  output/github/dongle.uf2"
    echo "  output/github/left.uf2"
    echo "  output/github/right.uf2"
    if [ -n "$BACKUP_DIR" ]; then
      echo "  $BACKUP_DIR/dongle.uf2 (backup)"
      echo "  $BACKUP_DIR/left.uf2 (backup)"
      echo "  $BACKUP_DIR/right.uf2 (backup)"
    fi
    echo ""
    echo "=== Dry Run Complete! ==="
  else
    # Create output directory
    mkdir -p output/github

    # Download artifacts
    gh run download "$RUN_ID" -D output/github/

    # Check what we downloaded
    echo ""
    echo "Downloaded files:"
    ls -lh output/github/

    # Rename files if they're in firmware subdirectory
    if [ -d "output/github/firmware" ]; then
      echo ""
      echo "Extracting and renaming files..."

      # Find and move files
      DONGLE=$(find output/github/firmware -name "*dongle*.uf2" -type f)
      LEFT=$(find output/github/firmware -name "*left*.uf2" -type f)
      RIGHT=$(find output/github/firmware -name "*right*.uf2" -type f)

      if [ -n "$DONGLE" ]; then
        mv "$DONGLE" output/github/dongle.uf2
      fi
      if [ -n "$LEFT" ]; then
        mv "$LEFT" output/github/left.uf2
      fi
      if [ -n "$RIGHT" ]; then
        mv "$RIGHT" output/github/right.uf2
      fi

      # Remove firmware directory
      rm -rf output/github/firmware
      echo "✓ Extracted to: dongle.uf2, left.uf2, right.uf2"
    fi

    echo ""
    echo "=== Download Complete! ==="
    echo "Firmware:"
    ls -lh output/github/*.uf2
    if [ -n "$BACKUP_DIR" ]; then
      echo ""
      echo "Previous version backed up to: $BACKUP_DIR"
    fi
  fi

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
