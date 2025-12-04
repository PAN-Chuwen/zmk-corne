#!/bin/bash

echo "=== ZMK Corne Choc (Low Profile) Firmware Flash Tool ==="
echo ""
echo "This script flashes firmware for the Choc (low profile) Corne keyboard."
echo "Unlike the dongle version, this only has LEFT and RIGHT keyboards."
echo ""

# Function to list available firmware sources
list_sources() {
  echo "Available firmware sources:"
  echo ""

  # Check local builds
  if [ -f "output/choc/local/left.uf2" ]; then
    local_date=$(stat -f %Sm -t "%Y-%m-%d %H:%M:%S" output/choc/local/left.uf2)
    echo "  1) local - Latest local build ($local_date)"
  else
    echo "  1) local - (no builds available)"
  fi

  # Check GitHub builds
  if [ -f "output/choc/github/left.uf2" ]; then
    github_date=$(stat -f %Sm -t "%Y-%m-%d %H:%M:%S" output/choc/github/left.uf2)
    echo "  2) github - Latest GitHub Actions build ($github_date)"
  else
    echo "  2) github - (no builds available)"
  fi

  # Check backups
  if [ -d "output/choc/backups" ] && [ -n "$(ls -A output/choc/backups 2>/dev/null)" ]; then
    echo "  3) backup - Previous builds"
    backup_count=$(ls -1 output/choc/backups | wc -l | tr -d ' ')
    echo "     ($backup_count backups available)"
  else
    echo "  3) backup - (no backups available)"
  fi

  echo ""
}

# Function to select backup
select_backup() {
  echo ""
  echo "Available backups (newest first):"
  echo ""

  backups=($(ls -1t output/choc/backups))

  if [ ${#backups[@]} -eq 0 ]; then
    echo "No backups found!"
    exit 1
  fi

  for i in "${!backups[@]}"; do
    backup="${backups[$i]}"
    if [ -f "output/choc/backups/$backup/left.uf2" ]; then
      backup_date=$(stat -f %Sm -t "%Y-%m-%d %H:%M:%S" "output/choc/backups/$backup/left.uf2")
      echo "  $((i+1))) $backup - $backup_date"
    fi
  done

  echo ""
  read -p "Select backup number: " backup_choice

  if [ "$backup_choice" -ge 1 ] && [ "$backup_choice" -le "${#backups[@]}" ]; then
    selected_backup="${backups[$((backup_choice-1))]}"
    FIRMWARE_SOURCE="output/choc/backups/$selected_backup"
    LEFT_FILE="$FIRMWARE_SOURCE/left.uf2"
    RIGHT_FILE="$FIRMWARE_SOURCE/right.uf2"
  else
    echo "Invalid backup selection!"
    exit 1
  fi
}

# Main menu
list_sources

# Read single character without requiring Enter
read -n 1 -p "Select firmware source (1-3): " choice
echo ""

case $choice in
  1)
    if [ ! -f "output/choc/local/left.uf2" ]; then
      echo "Error: No local builds available."
      exit 1
    fi
    FIRMWARE_SOURCE="output/choc/local"
    LEFT_FILE="$FIRMWARE_SOURCE/left.uf2"
    RIGHT_FILE="$FIRMWARE_SOURCE/right.uf2"
    echo "Selected: Local builds"
    ;;
  2)
    if [ ! -f "output/choc/github/left.uf2" ]; then
      echo "Error: No GitHub builds available."
      echo ""
      echo "To download from GitHub Actions:"
      echo "  gh run download <RUN_ID> --repo PAN-Chuwen/zmk-choc-corne --dir output/choc/github"
      echo ""
      echo "Then rename firmware files:"
      echo "  mv output/choc/github/firmware/eyelash_corne_left*.uf2 output/choc/github/left.uf2"
      echo "  mv output/choc/github/firmware/eyelash_corne_right*.uf2 output/choc/github/right.uf2"
      exit 1
    fi
    FIRMWARE_SOURCE="output/choc/github"
    LEFT_FILE="$FIRMWARE_SOURCE/left.uf2"
    RIGHT_FILE="$FIRMWARE_SOURCE/right.uf2"
    echo "Selected: GitHub builds"
    ;;
  3)
    select_backup
    echo "Selected: Backup $selected_backup"
    ;;
  *)
    echo "Invalid choice!"
    exit 1
    ;;
esac

echo ""
echo "Firmware files:"
echo "  Left:   $LEFT_FILE"
echo "  Right:  $RIGHT_FILE"
echo ""

# Verify all files exist
if [ ! -f "$LEFT_FILE" ] || [ ! -f "$RIGHT_FILE" ]; then
  echo "Error: One or more firmware files not found!"
  exit 1
fi

echo "=== Ready to Flash ==="
echo ""
echo "IMPORTANT: Flash BOTH devices when updating firmware!"
echo ""
echo "Instructions:"
echo "  1. Double-press RESET button to enter bootloader"
echo "  2. Device will mount as NICENANO volume"
echo "  3. Script will copy firmware and wait for device to reconnect"
echo ""

# Function to wait for device
wait_for_device() {
  local device_name=$1
  local max_wait=$2  # Maximum wait time in seconds

  echo "Waiting for $device_name to enter bootloader..."
  echo "(Double-press RESET button now - will auto-detect)"

  local elapsed=0
  while [ ! -d "/Volumes/NICENANO" ] && [ $elapsed -lt $max_wait ]; do
    sleep 0.5
    elapsed=$((elapsed + 1))
  done

  if [ ! -d "/Volumes/NICENANO" ]; then
    echo ""
    echo "Device not detected after ${max_wait}s. Retrying..."
    wait_for_device "$device_name" $max_wait
    return
  fi

  echo "Device detected!"

  # Wait for filesystem to be fully mounted and ready
  echo "Waiting for device to be ready..."
  sleep 2
}

# Function to flash device
flash_device() {
  local device_name=$1
  local firmware_file=$2

  echo ""
  echo "--- Flashing $device_name ---"
  wait_for_device "$device_name" 30

  echo "Copying firmware..."

  # Copy firmware - device will disconnect during/after copy (this is normal!)
  cp "$firmware_file" /Volumes/NICENANO/ 2>/dev/null || true

  echo "Firmware sent - device will now flash and reboot..."

  # Wait for device to disconnect (it will eject itself as it flashes)
  sleep 1
  local timeout=0
  while [ -d "/Volumes/NICENANO" ] && [ $timeout -lt 10 ]; do
    sleep 0.5
    timeout=$((timeout + 1))
  done

  if [ -d "/Volumes/NICENANO" ]; then
    echo "Note: Device still mounted. This is OK if it's flashing."
  fi

  echo "$device_name flash initiated!"
  echo "  (Wait for LED to stop flashing before continuing)"
  sleep 2
}

# Check for settings_reset file
RESET_FILE="vendor/firmware/settings_reset-nice_nano_v2-zmk.uf2"

echo ""
echo "=== Flash Sequence ==="
echo ""

# Ask if user wants to reset settings
read -n 1 -p "Reset settings before flashing? (recommended for first flash) [y/N]: " reset_choice
echo ""

if [ "$reset_choice" = "y" ] || [ "$reset_choice" = "Y" ]; then
  if [ ! -f "$RESET_FILE" ]; then
    echo "Warning: settings_reset file not found at $RESET_FILE"
    echo "Skipping settings reset..."
  else
    echo ""
    echo "--- LEFT (reset) ---"
    flash_device "LEFT (reset)" "$RESET_FILE"

    echo ""
    echo "--- RIGHT (reset) ---"
    flash_device "RIGHT (reset)" "$RESET_FILE"
  fi
fi

echo ""
echo "--- LEFT (firmware) ---"
flash_device "LEFT" "$LEFT_FILE"

echo ""
echo "--- RIGHT (firmware) ---"
flash_device "RIGHT" "$RIGHT_FILE"

echo ""
echo "=== All Devices Flashed Successfully! ==="
echo ""
echo "Your Corne Choc keyboard is ready to use."
echo ""
echo "Note: LEFT keyboard connects to your computer via USB."
echo "      RIGHT keyboard connects to LEFT via Bluetooth."
echo ""
