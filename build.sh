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

# Create output directory and copy files
mkdir -p output/local
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo ""
echo "Copying firmware to output/local/..."
cp build/dongle/zephyr/zmk.uf2 "output/local/eyeslash_corne_central_dongle_oled_${TIMESTAMP}.uf2"
cp build/left/zephyr/zmk.uf2 "output/local/eyeslash_corne_peripheral_left_${TIMESTAMP}.uf2"
cp build/right/zephyr/zmk.uf2 "output/local/eyeslash_corne_peripheral_right_${TIMESTAMP}.uf2"

# Create latest symlinks
ln -sf "eyeslash_corne_central_dongle_oled_${TIMESTAMP}.uf2" output/local/eyeslash_corne_central_dongle_oled_latest.uf2
ln -sf "eyeslash_corne_peripheral_left_${TIMESTAMP}.uf2" output/local/eyeslash_corne_peripheral_left_latest.uf2
ln -sf "eyeslash_corne_peripheral_right_${TIMESTAMP}.uf2" output/local/eyeslash_corne_peripheral_right_latest.uf2

echo ""
echo "=== Build Complete! ==="
echo "DONGLE:  output/local/eyeslash_corne_central_dongle_oled_${TIMESTAMP}.uf2"
echo "LEFT:    output/local/eyeslash_corne_peripheral_left_${TIMESTAMP}.uf2"
echo "RIGHT:   output/local/eyeslash_corne_peripheral_right_${TIMESTAMP}.uf2"
echo ""
echo "Latest symlinks:"
echo "  output/local/eyeslash_corne_central_dongle_oled_latest.uf2"
echo "  output/local/eyeslash_corne_peripheral_left_latest.uf2"
echo "  output/local/eyeslash_corne_peripheral_right_latest.uf2"
