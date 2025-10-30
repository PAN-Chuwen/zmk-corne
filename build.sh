#!/bin/bash
set -e

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
