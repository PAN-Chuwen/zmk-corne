# ZMK Corne Dongle Configuration

Custom ZMK firmware configuration for the Eyeslash Corne split keyboard with USB dongle.

**Repository**: Forked from [tokyo2006/zmk-corne-dongle](https://github.com/tokyo2006/zmk-corne-dongle)

## Hardware

- **LEFT/RIGHT keyboards**: Bluetooth peripherals with OLED displays
- **USB Dongle**: Bluetooth central (connects to Mac via USB)
- **Connection**: Keyboards → Dongle (Bluetooth) → Mac (USB)

## Repository Structure

```
~/zmk-corne-config/
├── config/                       # ⭐ Edit these for customization
│   ├── eyeslash_corne.keymap    # Main keymap (layers, keys, behaviors)
│   ├── eyeslash_corne.conf      # Settings (display, Bluetooth, sleep)
│   ├── eyeslash_corne.json      # ZMK Studio configuration
│   └── west.yml                 # Dependencies manifest
│
├── build.yaml                    # ⭐ GitHub Actions build matrix
├── build-firmware.sh             # Local Docker build script
│
├── output/                       # Firmware outputs (gitignored)
│   ├── github/                   # Downloaded from GitHub Actions
│   └── local/                    # Built by local Docker
│
└── vendor/                       # Reference materials (git tracked)
    ├── docs/                     # English documentation from vendor
    └── firmware/                 # Stock firmware (nice_oled - LEFT OLED works)
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
# Wait ~2 minutes, download "firmware" artifact
# Extract to output/github/
```

**Option B: Local Docker**
```bash
./build-firmware.sh
# Output: output/local/*.uf2
# Latest builds: output/local/*_latest.uf2
```

### 3. Flash Devices

**Enter bootloader**: Double-press RESET button

**Flash firmware**:
```bash
# Using GitHub Actions builds
cp output/github/*.uf2 /Volumes/NICENANO/

# OR using local Docker builds
cp output/local/*_latest.uf2 /Volumes/NICENANO/

# OR use vendor stock firmware
cp vendor/firmware/*.uf2 /Volumes/NICENANO/
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
