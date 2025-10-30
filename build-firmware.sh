#!/bin/bash
set -e

echo "=== ZMK Corne Dongle Firmware Build using Docker ==="
echo ""

# Pull latest ZMK build image
echo "Pulling latest ZMK build image..."
docker pull zmkfirmware/zmk-build-arm:stable

# Clean build directories
echo ""
echo "Cleaning build directories..."
rm -rf build/

# Build central dongle
echo ""
echo "Building DONGLE (central) firmware..."
docker run --rm -v "$(pwd):/workspace" -w /workspace zmkfirmware/zmk-build-arm:stable bash -c \
  "west zephyr-export && west build -s zmk/app -d build/dongle -b nice_nano_v2 -- -DZMK_CONFIG=/workspace/config -DSHIELD='eyeslash_corne_central_dongle dongle_display' -DZMK_EXTRA_MODULES=/workspace"

# Build peripheral left
echo ""
echo "Building LEFT (peripheral) keyboard firmware..."
docker run --rm -v "$(pwd):/workspace" -w /workspace zmkfirmware/zmk-build-arm:stable bash -c \
  "west zephyr-export && west build -s zmk/app -d build/left -b nice_nano_v2 -- -DZMK_CONFIG=/workspace/config -DSHIELD='eyeslash_corne_peripheral_left nice_view_custom' -DZMK_EXTRA_MODULES=/workspace"

# Build peripheral right
echo ""
echo "Building RIGHT (peripheral) keyboard firmware..."
docker run --rm -v "$(pwd):/workspace" -w /workspace zmkfirmware/zmk-build-arm:stable bash -c \
  "west zephyr-export && west build -s zmk/app -d build/right -b nice_nano_v2 -- -DZMK_CONFIG=/workspace/config -DSHIELD='eyeslash_corne_peripheral_right nice_view_custom' -DZMK_EXTRA_MODULES=/workspace"

# Create firmware output directory
mkdir -p output/local

# Copy firmware files with timestamps
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo ""
echo "Copying firmware files..."

cp build/dongle/zephyr/zmk.uf2 "output/local/eyeslash_corne_central_dongle_oled_${TIMESTAMP}.uf2"
cp build/left/zephyr/zmk.uf2 "output/local/eyeslash_corne_peripheral_left_${TIMESTAMP}.uf2"
cp build/right/zephyr/zmk.uf2 "output/local/eyeslash_corne_peripheral_right_${TIMESTAMP}.uf2"

# Create latest symlinks
ln -sf "eyeslash_corne_central_dongle_oled_${TIMESTAMP}.uf2" output/local/eyeslash_corne_central_dongle_oled_latest.uf2
ln -sf "eyeslash_corne_peripheral_left_${TIMESTAMP}.uf2" output/local/eyeslash_corne_peripheral_left_latest.uf2
ln -sf "eyeslash_corne_peripheral_right_${TIMESTAMP}.uf2" output/local/eyeslash_corne_peripheral_right_latest.uf2

echo ""
echo "=== Build complete! ==="
echo "DONGLE:  output/local/eyeslash_corne_central_dongle_oled_${TIMESTAMP}.uf2"
echo "LEFT:    output/local/eyeslash_corne_peripheral_left_${TIMESTAMP}.uf2"
echo "RIGHT:   output/local/eyeslash_corne_peripheral_right_${TIMESTAMP}.uf2"
echo ""
echo "Latest symlinks:"
echo "  output/local/eyeslash_corne_central_dongle_oled_latest.uf2"
echo "  output/local/eyeslash_corne_peripheral_left_latest.uf2"
echo "  output/local/eyeslash_corne_peripheral_right_latest.uf2"
