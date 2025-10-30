# ZMK Corne Dongle Configuration

This repository contains custom ZMK firmware configuration for the Eyeslash Corne split keyboard with USB dongle.

## Hardware

- **LEFT/RIGHT keyboards**: Bluetooth peripherals with OLED displays
- **USB Dongle**: Bluetooth central (connects to Mac via USB)
- **Connection**: Keyboards → Dongle (Bluetooth) → Mac (USB)

## Repository Structure

```
~/zmk-corne-config/
├── config/
│   ├── eyeslash_corne.keymap    # Main keymap configuration
│   ├── eyeslash_corne.conf      # Keyboard settings
│   └── eyeslash_corne.json      # ZMK Studio config
├── firmware/                     # Custom-built firmware (from GitHub Actions)
├── vendor/
│   ├── docs/                     # Vendor documentation (English)
│   └── firmware/                 # Vendor stock firmware (nice_oled)
├── build.yaml                    # GitHub Actions build config
└── build-firmware.sh             # Local Docker build script
```

## Quick Workflow

### 1. Edit Keymap
```bash
cd ~/zmk-corne-config
vim config/eyeslash_corne.keymap
```

### 2. Build Firmware

**Option A: GitHub Actions (Recommended)**
```bash
git add config/eyeslash_corne.keymap
git commit -m "feat: update keymap"
git push
# Wait ~5 minutes, download from Actions
```

**Option B: Local Docker**
```bash
./build-firmware.sh
# Output: build/{left,right,dongle}/zephyr/zmk.uf2
```

### 3. Flash Devices

**Enter bootloader**: Double-press RESET button

**Flash firmware**:
```bash
# Dongle
cp firmware/eyeslash_corne_central_dongle_oled.uf2 /Volumes/NICENANO/

# LEFT
cp firmware/eyeslash_corne_peripheral_left*.uf2 /Volumes/NICENANO/

# RIGHT
cp firmware/eyeslash_corne_peripheral_right*.uf2 /Volumes/NICENANO/
```

**IMPORTANT**: Flash all 3 devices when updating keymap.

## Key Files

- `config/eyeslash_corne.keymap` - Edit this for custom keybindings
- `config/eyeslash_corne.conf` - Display, sleep, Bluetooth settings
- `build.yaml` - GitHub Actions build matrix
- `vendor/firmware/` - Stock firmware with working LEFT OLED

## Known Issues

**LEFT OLED not working with custom builds**:
- Custom builds use `nice_view_custom` shield
- LEFT OLED only works with vendor firmware (`nice_oled` shield)
- **Workaround**: Use vendor firmware for LEFT, or accept no OLED

## Vendor Documentation

See `vendor/docs/`:
- `dongle users readme.doc` - Dongle setup instructions
- `Modification of Keymap.doc` - Complete keymap guide
- `Split keyboard manual.doc` - General usage

## Troubleshooting

**Connection issues**: Flash `settings_reset-*.uf2` to all devices, then reflash firmware

**Keys not working**: Ensure all 3 devices have matching firmware versions

**Build errors**: Pull latest Docker image: `docker pull zmkfirmware/zmk-build-arm:stable`
