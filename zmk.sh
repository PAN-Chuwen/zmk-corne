#!/bin/bash
set -e

# ZMK Corne Firmware Management Script
# Single repo builds both Dongle (OLED) and Choc (LCD) versions

REPO="PAN-Chuwen/zmk-corne"
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
cmd_build() {
    print_header "Triggering GitHub Actions Build"

    print_info "Triggering build..."
    gh workflow run build.yml --repo "$REPO"
    print_success "Build triggered"

    # Wait for build to register then download
    echo ""
    print_info "Waiting 5 seconds for build to register..."
    sleep 5

    ensure_output_dirs

    # Wait for build
    print_info "Waiting for build to complete..."
    local run_id
    run_id=$(gh run list --repo "$REPO" --workflow=build.yml --limit 1 --json databaseId --jq '.[0].databaseId')

    if [ -z "$run_id" ]; then
        print_error "No builds found"
        exit 1
    fi

    gh run watch "$run_id" --repo "$REPO" --exit-status
    print_success "Build complete!"

    # Download firmware
    print_header "Downloading Firmware"
    download_firmware

    echo ""
    print_success "Build complete! Use '$0 flash' to flash the firmware."
}

# ============================================
# HELPER FUNCTIONS FOR BUILD
# ============================================
download_firmware() {
    print_info "Downloading firmware..."

    # Get latest successful run
    local run_id
    run_id=$(gh run list --repo "$REPO" --workflow=build.yml --status=success --limit 1 --json databaseId --jq '.[0].databaseId')

    if [ -z "$run_id" ]; then
        print_error "No successful builds found"
        return 1
    fi

    # Clear and download
    rm -rf "$OUTPUT_DIR/dongle/firmware" "$OUTPUT_DIR/dongle"/*.uf2
    rm -rf "$OUTPUT_DIR/choc/firmware" "$OUTPUT_DIR/choc"/*.uf2
    gh run download "$run_id" --repo "$REPO" --dir "$OUTPUT_DIR"

    local dongle_dir="$OUTPUT_DIR/dongle"
    local choc_dir="$OUTPUT_DIR/choc"

    # Process firmware folder (GitHub Actions merges all artifacts into 'firmware')
    if [ -d "$OUTPUT_DIR/firmware" ]; then
        # Dongle firmware
        cp "$OUTPUT_DIR/firmware/eyeslash_corne_central_dongle_oled.uf2" "$dongle_dir/dongle.uf2" 2>/dev/null || true
        cp "$OUTPUT_DIR/firmware/eyeslash_corne_peripheral_left nice_oled-nice_nano_v2-zmk.uf2" "$dongle_dir/left.uf2" 2>/dev/null || true
        cp "$OUTPUT_DIR/firmware/eyeslash_corne_peripheral_right nice_oled-nice_nano_v2-zmk.uf2" "$dongle_dir/right.uf2" 2>/dev/null || true
        cp "$OUTPUT_DIR/firmware/settings_reset-nice_nano_v2-zmk.uf2" "$dongle_dir/settings_reset.uf2" 2>/dev/null || true

        # Choc firmware
        cp "$OUTPUT_DIR/firmware/eyeslash_corne_choc_left.uf2" "$choc_dir/left.uf2" 2>/dev/null || true
        cp "$OUTPUT_DIR/firmware/eyeslash_corne_choc_right.uf2" "$choc_dir/right.uf2" 2>/dev/null || true
        cp "$OUTPUT_DIR/firmware/settings_reset-nice_nano_v2-zmk.uf2" "$choc_dir/settings_reset.uf2" 2>/dev/null || true

        rm -rf "$OUTPUT_DIR/firmware"
    fi

    # Check what was downloaded
    if [ -f "$dongle_dir/dongle.uf2" ]; then
        print_success "Dongle firmware downloaded to $dongle_dir/"
    fi
    if [ -f "$choc_dir/left.uf2" ]; then
        print_success "Choc firmware downloaded to $choc_dir/"
    fi
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
            print_info "Run '$0 build' first"
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
# DRAW COMMAND
# ============================================
cmd_draw() {
    local keys_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --keys-only)
                keys_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Usage: $0 draw [--keys-only]"
                exit 1
                ;;
        esac
    done

    print_header "Generate Keymap Diagram"

    local keymap_file="config/eyeslash_corne.keymap"
    local layout_file="config/eyeslash_corne.json"
    local output_dir="$(dirname "$0")/keymap"
    local yaml_file="$output_dir/keymap.yaml"
    local svg_file="$output_dir/keymap.svg"
    local png_file="$output_dir/keymap.png"

    # Ensure output directory exists
    mkdir -p "$output_dir"

    # Check if uv is installed
    if ! command -v uvx &> /dev/null; then
        print_error "uv not installed"
        echo ""
        echo "Install with:"
        echo "  brew install uv"
        exit 1
    fi

    if [ ! -f "$keymap_file" ]; then
        print_error "Keymap not found: $keymap_file"
        exit 1
    fi

    if [ ! -f "$layout_file" ]; then
        print_error "Layout not found: $layout_file"
        exit 1
    fi

    # Parse keymap to YAML
    # Note: tree-sitter<0.23 required for keymap-drawer compatibility
    print_info "Parsing keymap..."
    uvx --from keymap-drawer --with "tree-sitter<0.23" keymap parse -z "$keymap_file" > "$yaml_file"
    print_success "Generated $yaml_file"

    # Draw SVG with layout JSON
    print_info "Drawing SVG..."
    local draw_opts=""
    if [ "$keys_only" = true ]; then
        draw_opts="--keys-only"
        print_info "Excluding combos (--keys-only)"
    fi
    uvx --from keymap-drawer --with "tree-sitter<0.23" keymap draw "$yaml_file" -j "$layout_file" $draw_opts > "$svg_file"
    print_success "Generated $svg_file"

    # Convert to PNG and display
    if command -v rsvg-convert &> /dev/null; then
        print_info "Converting to PNG..."
        rsvg-convert "$svg_file" -o "$png_file"
        print_success "Generated $png_file"

        # Display in terminal with chafa
        if command -v chafa &> /dev/null; then
            echo ""
            # Use passthrough mode in tmux for proper graphics rendering
            if [ -n "$TMUX" ]; then
                chafa --size=120 --passthrough=tmux "$png_file"
            else
                chafa --size=120 "$png_file"
            fi
        else
            print_info "Install chafa for terminal preview: brew install chafa"
            open "$png_file"
        fi
    else
        print_info "Install librsvg for PNG: brew install librsvg"
        if command -v chafa &> /dev/null; then
            if [ -n "$TMUX" ]; then
                chafa --size=120 --passthrough=tmux "$svg_file"
            else
                chafa --size=120 "$svg_file"
            fi
        else
            open "$svg_file"
        fi
    fi

    echo ""
    print_success "Output: $output_dir/"
}

# ============================================
# STATUS COMMAND
# ============================================
cmd_status() {
    print_header "Build Status"

    gh run list --repo "$REPO" --workflow=build.yml --limit 5

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
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  build      Build firmware (triggers GitHub Actions, waits, downloads)"
    echo "  flash      Flash firmware to keyboard (interactive)"
    echo "  draw       Generate keymap SVG diagram"
    echo "  status     Show build status and local firmware"
    echo "  help       Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 build        # Build both dongle and choc firmware"
    echo "  $0 flash        # Flash firmware (select dongle or choc)"
    echo "  $0 draw         # Generate keymap.svg with combos"
    echo "  $0 draw --keys-only  # Generate keymap.svg without combos"
}

case "${1:-help}" in
    build)
        cmd_build
        ;;
    flash)
        cmd_flash
        ;;
    draw)
        shift
        cmd_draw "$@"
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
