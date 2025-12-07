#!/bin/bash
set -e

# ZMK Corne Firmware Management Script
# Handles build, download, and flash for both Dongle (OLED) and Choc (LCD) versions

DONGLE_REPO="PAN-Chuwen/zmk-corne-dongle"
CHOC_REPO="PAN-Chuwen/zmk-choc-corne"
OUTPUT_DIR="$(dirname "$0")/output"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Ensure output directories exist
ensure_output_dirs() {
    mkdir -p "$OUTPUT_DIR/dongle"
    mkdir -p "$OUTPUT_DIR/choc"
}

# ============================================
# BUILD COMMAND
# ============================================
sync_keymap() {
    local repo="$1"
    local remote_path="$2"
    local repo_name="$3"
    local keymap_file="config/eyeslash_corne.keymap"

    if [ ! -f "$keymap_file" ]; then
        print_error "Keymap not found: $keymap_file"
        return 1
    fi

    print_info "Syncing keymap to $repo_name..."

    # Get current SHA
    local sha
    sha=$(gh api "repos/$repo/contents/$remote_path" --jq '.sha' 2>/dev/null || echo "")

    # Upload
    if [ -n "$sha" ]; then
        gh api --method PUT "repos/$repo/contents/$remote_path" \
            -f message="feat: sync keymap" \
            -f content="$(base64 < "$keymap_file")" \
            -f sha="$sha" > /dev/null
    else
        gh api --method PUT "repos/$repo/contents/$remote_path" \
            -f message="feat: sync keymap" \
            -f content="$(base64 < "$keymap_file")" > /dev/null
    fi

    print_success "$repo_name synced"
}

cmd_build() {
    local target="${1:-both}"

    print_header "Syncing Keymap"

    # Auto-sync keymap to repos before building
    if [ "$target" = "dongle" ] || [ "$target" = "both" ]; then
        sync_keymap "$DONGLE_REPO" "config/eyeslash_corne.keymap" "Dongle"
    fi
    if [ "$target" = "choc" ] || [ "$target" = "both" ]; then
        sync_keymap "$CHOC_REPO" "config/eyelash_corne.keymap" "Choc"
    fi

    print_header "Triggering GitHub Actions Build"

    case "$target" in
        dongle)
            print_info "Triggering Dongle (OLED) build..."
            gh workflow run build.yml --repo "$DONGLE_REPO"
            print_success "Dongle build triggered"
            ;;
        choc)
            print_info "Triggering Choc (LCD) build..."
            gh workflow run build.yml --repo "$CHOC_REPO"
            print_success "Choc build triggered"
            ;;
        both)
            print_info "Triggering Dongle (OLED) build..."
            gh workflow run build.yml --repo "$DONGLE_REPO"
            print_success "Dongle build triggered"

            print_info "Triggering Choc (LCD) build..."
            gh workflow run build.yml --repo "$CHOC_REPO"
            print_success "Choc build triggered"
            ;;
        *)
            print_error "Unknown target: $target"
            echo "Usage: $0 build [dongle|choc|both]"
            exit 1
            ;;
    esac

    # Wait for builds to register then download
    echo ""
    print_info "Waiting 5 seconds for builds to register..."
    sleep 5

    ensure_output_dirs
    wait_for_builds "$target"

    # Download firmware
    print_header "Downloading Firmware"
    case "$target" in
        dongle)
            download_firmware "$DONGLE_REPO" "dongle" "Dongle"
            ;;
        choc)
            download_firmware "$CHOC_REPO" "choc" "Choc"
            ;;
        both)
            download_firmware "$DONGLE_REPO" "dongle" "Dongle"
            download_firmware "$CHOC_REPO" "choc" "Choc"
            ;;
    esac

    echo ""
    print_success "Build complete! Use '$0 flash' to flash the firmware."
}

# ============================================
# HELPER FUNCTIONS FOR BUILD
# ============================================
get_latest_run_id() {
    local repo="$1"
    gh run list --repo "$repo" --workflow=build.yml --limit 1 --json databaseId --jq '.[0].databaseId'
}

wait_for_builds() {
    local target="$1"
    local dongle_run_id=""
    local choc_run_id=""

    # Get run IDs
    if [ "$target" = "dongle" ] || [ "$target" = "both" ]; then
        dongle_run_id=$(get_latest_run_id "$DONGLE_REPO")
        if [ -z "$dongle_run_id" ]; then
            print_error "No Dongle builds found"
            return 1
        fi
    fi

    if [ "$target" = "choc" ] || [ "$target" = "both" ]; then
        choc_run_id=$(get_latest_run_id "$CHOC_REPO")
        if [ -z "$choc_run_id" ]; then
            print_error "No Choc builds found"
            return 1
        fi
    fi

    # Wait for builds in parallel using background processes
    if [ "$target" = "both" ]; then
        print_info "Waiting for both builds in parallel..."

        # Start both watchers in background
        gh run watch "$dongle_run_id" --repo "$DONGLE_REPO" --exit-status &
        local dongle_pid=$!

        gh run watch "$choc_run_id" --repo "$CHOC_REPO" --exit-status &
        local choc_pid=$!

        # Wait for both
        local dongle_status=0
        local choc_status=0
        wait $dongle_pid || dongle_status=$?
        wait $choc_pid || choc_status=$?

        if [ $dongle_status -ne 0 ]; then
            print_error "Dongle build failed"
            return 1
        fi
        if [ $choc_status -ne 0 ]; then
            print_error "Choc build failed"
            return 1
        fi

        print_success "Both builds complete!"
    elif [ "$target" = "dongle" ]; then
        print_info "Waiting for Dongle build..."
        gh run watch "$dongle_run_id" --repo "$DONGLE_REPO" --exit-status
        print_success "Dongle build complete!"
    elif [ "$target" = "choc" ]; then
        print_info "Waiting for Choc build..."
        gh run watch "$choc_run_id" --repo "$CHOC_REPO" --exit-status
        print_success "Choc build complete!"
    fi
}

download_firmware() {
    local repo="$1"
    local output_subdir="$2"
    local repo_name="$3"

    print_info "Downloading $repo_name firmware..."

    # Get latest successful run
    local run_id
    run_id=$(gh run list --repo "$repo" --workflow=build.yml --status=success --limit 1 --json databaseId --jq '.[0].databaseId')

    if [ -z "$run_id" ]; then
        print_error "No successful builds found for $repo_name"
        return 1
    fi

    # Clear and download
    local dest="$OUTPUT_DIR/$output_subdir"
    rm -rf "$dest/firmware" "$dest"/*.uf2
    gh run download "$run_id" --repo "$repo" --dir "$dest"

    # Rename firmware files for easier access
    if [ "$output_subdir" = "dongle" ]; then
        # Dongle version
        cp "$dest/firmware/eyeslash_corne_central_dongle_oled.uf2" "$dest/dongle.uf2" 2>/dev/null || true
        cp "$dest/firmware/eyeslash_corne_peripheral_left nice_oled-nice_nano_v2-zmk.uf2" "$dest/left.uf2" 2>/dev/null || true
        cp "$dest/firmware/eyeslash_corne_peripheral_right nice_oled-nice_nano_v2-zmk.uf2" "$dest/right.uf2" 2>/dev/null || true
        cp "$dest/firmware/settings_reset-nice_nano_v2-zmk.uf2" "$dest/settings_reset.uf2" 2>/dev/null || true
    else
        # Choc version
        cp "$dest/firmware/eyelash_corne_studio_left.uf2" "$dest/left.uf2" 2>/dev/null || true
        cp "$dest/firmware/nice_view_custom-eyelash_corne_right-zmk.uf2" "$dest/right.uf2" 2>/dev/null || true
        cp "$dest/firmware/settings_reset.uf2" "$dest/settings_reset.uf2" 2>/dev/null || true
    fi

    # Clean up firmware subfolder
    rm -rf "$dest/firmware"

    print_success "$repo_name firmware downloaded to $dest/"
}

# ============================================
# FLASH COMMAND
# ============================================
wait_for_device() {
    local device_name="$1"
    local max_wait="${2:-60}"

    echo ""
    print_info "Waiting for $device_name to enter bootloader..."
    echo "    (Double-tap RESET button now)"

    local elapsed=0
    while [ ! -d "/Volumes/NICENANO" ] && [ $elapsed -lt $max_wait ]; do
        sleep 0.5
        elapsed=$((elapsed + 1))
    done

    if [ ! -d "/Volumes/NICENANO" ]; then
        print_error "Device not detected after ${max_wait}s"
        return 1
    fi

    print_success "Device detected!"
    sleep 2  # Wait for filesystem to be ready
}

flash_file() {
    local device_name="$1"
    local firmware_file="$2"

    if [ ! -f "$firmware_file" ]; then
        print_error "Firmware not found: $firmware_file"
        return 1
    fi

    wait_for_device "$device_name"

    print_info "Copying firmware..."
    cp "$firmware_file" /Volumes/NICENANO/ 2>/dev/null || true

    print_success "$device_name firmware sent!"

    # Wait for device to disconnect
    sleep 1
    local timeout=0
    while [ -d "/Volumes/NICENANO" ] && [ $timeout -lt 10 ]; do
        sleep 0.5
        timeout=$((timeout + 1))
    done

    echo "    (Wait for LED to stop flashing before continuing)"
    sleep 2
}

cmd_flash() {
    print_header "Flash Firmware"

    # Select keyboard type
    echo "Select keyboard:"
    echo "  1) Dongle (OLED) - dongle + left + right"
    echo "  2) Choc (LCD) - left + right only"
    echo ""
    read -n 1 -p "Choice [1-2]: " kb_choice
    echo ""

    local firmware_dir
    local devices=()

    case "$kb_choice" in
        1)
            firmware_dir="$OUTPUT_DIR/dongle"
            devices=("dongle" "left" "right")
            ;;
        2)
            firmware_dir="$OUTPUT_DIR/choc"
            devices=("left" "right")
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac

    # Check firmware exists
    for device in "${devices[@]}"; do
        if [ ! -f "$firmware_dir/$device.uf2" ]; then
            print_error "Firmware not found: $firmware_dir/$device.uf2"
            print_info "Run '$0 download' first"
            exit 1
        fi
    done

    # Ask about settings reset
    local do_reset=false
    echo ""
    read -n 1 -p "Reset settings first? (recommended for first flash) [y/N]: " reset_choice
    echo ""

    if [ "$reset_choice" = "y" ] || [ "$reset_choice" = "Y" ]; then
        if [ -f "$firmware_dir/settings_reset.uf2" ]; then
            do_reset=true
        else
            print_error "settings_reset.uf2 not found, skipping reset"
        fi
    fi

    # Flash each device (reset + flash in one go per device)
    for device in "${devices[@]}"; do
        if [ "$do_reset" = true ]; then
            print_header "Flash $device (reset + firmware)"
            # First: reset
            print_info "Step 1: Flashing settings_reset..."
            flash_file "$device (reset)" "$firmware_dir/settings_reset.uf2"
            # Second: firmware (same device, need to enter bootloader again)
            print_info "Step 2: Flashing firmware..."
            flash_file "$device" "$firmware_dir/$device.uf2"
        else
            print_header "Flash $device"
            flash_file "$device" "$firmware_dir/$device.uf2"
        fi
    done

    print_header "Complete!"
    print_success "All devices flashed successfully"
}

# ============================================
# STATUS COMMAND
# ============================================
cmd_status() {
    print_header "Build Status"

    echo "Dongle (OLED):"
    gh run list --repo "$DONGLE_REPO" --workflow=build.yml --limit 3

    echo ""
    echo "Choc (LCD):"
    gh run list --repo "$CHOC_REPO" --workflow=build.yml --limit 3

    echo ""
    print_header "Local Firmware"

    echo "Dongle:"
    ls -la "$OUTPUT_DIR/dongle/"*.uf2 2>/dev/null || echo "  (none)"

    echo ""
    echo "Choc:"
    ls -la "$OUTPUT_DIR/choc/"*.uf2 2>/dev/null || echo "  (none)"
}

# ============================================
# MAIN
# ============================================
cmd_help() {
    echo "ZMK Corne Firmware Manager"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  build [dongle|choc|both]     Build firmware (auto-syncs keymap, waits, downloads)"
    echo "  flash                        Flash firmware to keyboard"
    echo "  status                       Show build status and local firmware"
    echo "  help                         Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 build                     # Build both keyboards"
    echo "  $0 build dongle              # Build only dongle"
    echo "  $0 flash                     # Flash firmware (interactive)"
}

case "${1:-help}" in
    build)
        shift
        cmd_build "$@"
        ;;
    flash)
        cmd_flash
        ;;
    status)
        cmd_status
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        print_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
