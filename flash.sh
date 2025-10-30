#!/bin/bash
set -e

echo "=== ZMK Corne Firmware Flash Tool ==="
echo ""

# Function to list available firmware sources
list_sources() {
  echo "Available firmware sources:"
  echo ""

  # Check local builds
  if [ -f "output/local/dongle.uf2" ]; then
    local_date=$(stat -f %Sm -t "%Y-%m-%d %H:%M:%S" output/local/dongle.uf2)
    echo "  1) local - Latest local build ($local_date)"
  else
    echo "  1) local - (no builds available)"
  fi

  # Check GitHub builds
  if [ -f "output/github/eyeslash_corne_central_dongle_oled.uf2" ]; then
    github_date=$(stat -f %Sm -t "%Y-%m-%d %H:%M:%S" output/github/eyeslash_corne_central_dongle_oled.uf2)
    echo "  2) github - Latest GitHub Actions build ($github_date)"
  else
    echo "  2) github - (no builds available)"
  fi

  # Check backups
  if [ -d "output/backups" ] && [ -n "$(ls -A output/backups 2>/dev/null)" ]; then
    echo "  3) backup - Previous builds"
    backup_count=$(ls -1 output/backups | wc -l | tr -d ' ')
    echo "     ($backup_count backups available)"
  else
    echo "  3) backup - (no backups available)"
  fi

  # Check vendor firmware
  if [ -f "vendor/firmware/eyeslash_corne_central_dongle_oled.uf2" ]; then
    echo "  4) vendor - Original stock firmware"
  else
    echo "  4) vendor - (not available)"
  fi

  echo ""
}

# Function to select backup
select_backup() {
  echo ""
  echo "Available backups (newest first):"
  echo ""

  backups=($(ls -1t output/backups))

  if [ ${#backups[@]} -eq 0 ]; then
    echo "No backups found!"
    exit 1
  fi

  for i in "${!backups[@]}"; do
    backup="${backups[$i]}"
    if [ -f "output/backups/$backup/dongle.uf2" ]; then
      backup_date=$(stat -f %Sm -t "%Y-%m-%d %H:%M:%S" "output/backups/$backup/dongle.uf2")
      echo "  $((i+1))) $backup - $backup_date"
    fi
  done

  echo ""
  read -p "Select backup number: " backup_choice

  if [ "$backup_choice" -ge 1 ] && [ "$backup_choice" -le "${#backups[@]}" ]; then
    selected_backup="${backups[$((backup_choice-1))]}"
    FIRMWARE_SOURCE="output/backups/$selected_backup"
    DONGLE_FILE="$FIRMWARE_SOURCE/dongle.uf2"
    LEFT_FILE="$FIRMWARE_SOURCE/left.uf2"
    RIGHT_FILE="$FIRMWARE_SOURCE/right.uf2"
  else
    echo "Invalid backup selection!"
    exit 1
  fi
}

# Main menu
list_sources

read -p "Select firmware source (1-4): " choice

case $choice in
  1)
    if [ ! -f "output/local/dongle.uf2" ]; then
      echo "Error: No local builds available. Run ./build.sh first."
      exit 1
    fi
    FIRMWARE_SOURCE="output/local"
    DONGLE_FILE="$FIRMWARE_SOURCE/dongle.uf2"
    LEFT_FILE="$FIRMWARE_SOURCE/left.uf2"
    RIGHT_FILE="$FIRMWARE_SOURCE/right.uf2"
    echo "Selected: Local builds"
    ;;
  2)
    if [ ! -f "output/github/eyeslash_corne_central_dongle_oled.uf2" ]; then
      echo "Error: No GitHub builds available. Download firmware artifact from Actions."
      exit 1
    fi
    FIRMWARE_SOURCE="output/github"
    # GitHub Actions uses different naming
    DONGLE_FILE="$FIRMWARE_SOURCE/eyeslash_corne_central_dongle_oled.uf2"
    LEFT_FILE="$FIRMWARE_SOURCE/eyeslash_corne_peripheral_left-nice_view_custom.uf2"
    RIGHT_FILE="$FIRMWARE_SOURCE/eyeslash_corne_peripheral_right-nice_view_custom.uf2"
    echo "Selected: GitHub builds"
    ;;
  3)
    select_backup
    echo "Selected: Backup $selected_backup"
    ;;
  4)
    if [ ! -f "vendor/firmware/eyeslash_corne_central_dongle_oled.uf2" ]; then
      echo "Error: Vendor firmware not available."
      exit 1
    fi
    FIRMWARE_SOURCE="vendor/firmware"
    DONGLE_FILE="$FIRMWARE_SOURCE/eyeslash_corne_central_dongle_oled.uf2"
    LEFT_FILE="$FIRMWARE_SOURCE/eyeslash_corne_peripheral_left_nice_oled.uf2"
    RIGHT_FILE="$FIRMWARE_SOURCE/eyeslash_corne_peripheral_right_nice_oled.uf2"
    echo "Selected: Vendor firmware"
    ;;
  *)
    echo "Invalid choice!"
    exit 1
    ;;
esac

echo ""
echo "Firmware files:"
echo "  Dongle: $DONGLE_FILE"
echo "  Left:   $LEFT_FILE"
echo "  Right:  $RIGHT_FILE"
echo ""

# Verify all files exist
if [ ! -f "$DONGLE_FILE" ] || [ ! -f "$LEFT_FILE" ] || [ ! -f "$RIGHT_FILE" ]; then
  echo "Error: One or more firmware files not found!"
  exit 1
fi

echo "=== Ready to Flash ==="
echo ""
echo "IMPORTANT: Flash all 3 devices when updating firmware!"
echo ""
echo "Instructions:"
echo "  1. Double-press RESET button to enter bootloader"
echo "  2. Device will mount as NICENANO volume"
echo "  3. Script will copy firmware and wait for device to reconnect"
echo ""

# Function to wait for device
wait_for_device() {
  local device_name=$1
  echo "Waiting for $device_name to enter bootloader..."
  echo "(Double-press RESET button now)"

  while [ ! -d "/Volumes/NICENANO" ]; do
    sleep 0.5
  done

  echo "✓ $device_name detected!"
  sleep 0.5
}

# Function to flash device
flash_device() {
  local device_name=$1
  local firmware_file=$2

  echo ""
  echo "--- Flashing $device_name ---"
  wait_for_device "$device_name"

  echo "Copying firmware..."
  cp "$firmware_file" /Volumes/NICENANO/

  echo "Waiting for device to reboot..."
  # Wait for device to unmount (indicates successful flash)
  while [ -d "/Volumes/NICENANO" ]; do
    sleep 0.5
  done

  echo "✓ $device_name flashed successfully!"
  sleep 1
}

# Flash devices in order
read -p "Press Enter to start flashing DONGLE..."
flash_device "DONGLE" "$DONGLE_FILE"

read -p "Press Enter to flash LEFT keyboard..."
flash_device "LEFT" "$LEFT_FILE"

read -p "Press Enter to flash RIGHT keyboard..."
flash_device "RIGHT" "$RIGHT_FILE"

echo ""
echo "=== All Devices Flashed Successfully! ==="
echo ""
echo "Your Corne keyboard is ready to use."
echo ""
