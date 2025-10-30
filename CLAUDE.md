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
├── build.sh                      # Local Docker build script (parallel!)
├── flash.sh                      # Interactive firmware flash tool
├── docker-compose.yml            # Docker orchestration for builds
│
├── output/                       # Firmware outputs (gitignored)
│   ├── github/                   # Downloaded from GitHub Actions
│   ├── local/                    # Latest local builds (dongle.uf2, left.uf2, right.uf2)
│   └── backups/                  # Timestamped backups for rollback
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
./build.sh
# Output: output/local/{dongle,left,right}.uf2
# Backup: output/backups/YYYYMMDD_HHMMSS/
# ~3-5 minutes first build, ~27 seconds with caching (parallel builds!)
```

### 3. Flash Devices

**Interactive flash script (recommended)**:
```bash
./flash.sh
# Guides you through:
# - Selecting firmware source (local/github/backup/vendor)
# - Flashing each device step-by-step
# - Automatic detection of bootloader mode
```

**Manual flashing**:
```bash
# Enter bootloader: Double-press RESET button
# Then copy firmware:
cp output/local/*.uf2 /Volumes/NICENANO/

# OR rollback to backup
cp output/backups/20251031_043925/*.uf2 /Volumes/NICENANO/
```

**IMPORTANT**: Flash all 3 devices when updating keymap.

## Build System Details

**Docker Compose Workflow**:
- Uses `zmkfirmware/zmk-build-arm:stable` image
- Named volume `zmk-cache` persists west dependencies (~1GB)
- Separates west workspace (`/zmk-workspace`) from config (`/workspace`)
- Command sequence: `west init` → `west update` → `west zephyr-export` → parallel `west build`
- Builds dongle, left, and right firmware simultaneously for maximum speed

**Automatic Backups**:
- `./build.sh` backs up existing firmware before each build
- Backups saved with timestamp from previous build's file modification time
- Latest firmware always at `output/local/{dongle,left,right}.uf2`
- Full build history preserved in `output/backups/YYYYMMDD_HHMMSS/`

**Build Times**:
- First build: ~3-5 minutes (downloads dependencies)
- Subsequent builds: **~27 seconds** (parallel builds with cached dependencies)
- GitHub Actions: ~2 minutes (parallel builds in cloud)

## Key Files

- `config/eyeslash_corne.keymap` - Edit this for custom keybindings
- `config/eyeslash_corne.conf` - Display, sleep, Bluetooth settings
- `build.yaml` - GitHub Actions build matrix
- `build.sh` - Parallel build script with automatic backups
- `flash.sh` - Interactive firmware flashing tool
- `docker-compose.yml` - Docker orchestration configuration
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
