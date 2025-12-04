# ZMK Corne Configuration

Custom ZMK firmware configuration for the Eyeslash Corne split keyboard.

This repository supports **TWO keyboard variants**:

| Variant | Repository | Display | Connection |
|---------|------------|---------|------------|
| **Dongle (OLED)** | [zmk-corne-dongle](https://github.com/PAN-Chuwen/zmk-corne-config) | OLED | Dongle + Left + Right |
| **Choc (LCD)** | [zmk-choc-corne](https://github.com/PAN-Chuwen/zmk-choc-corne) | LCD (nice_view) | Left + Right only |

## Hardware

### Dongle Version (OLED)
- **LEFT/RIGHT keyboards**: Bluetooth peripherals with OLED displays
- **USB Dongle**: Bluetooth central (connects to Mac via USB)
- **Connection**: Keyboards → Dongle (Bluetooth) → Mac (USB)

### Choc Version (LCD) - Low Profile
- **LEFT keyboard**: USB connection to Mac, Bluetooth central
- **RIGHT keyboard**: Bluetooth peripheral
- **Connection**: RIGHT → LEFT (Bluetooth) → Mac (USB)
- **Display**: LCD (nice_view)

## Keyboard Layout

**Eyeslash Corne 48-key split keyboard with center column**:

**PHYSICAL LAYOUT (ZMK Position IDs 0-47)**:

```
     LEFT SPLIT (6)           CENTER            RIGHT SPLIT (6)
┌────┬────┬────┬────┬────┬────┐   ┌────┐   ┌────┬────┬────┬────┬────┬────┐
│ 0  │ 1  │ 2  │ 3  │ 4  │ 5  │   │ 6  │   │ 7  │ 8  │ 9  │ 10 │ 11 │ 12 │  Row 0 (13)
├────┼────┼────┼────┼────┼────┤┌──┼────┼──┐├────┼────┼────┼────┼────┼────┤
│ 13 │ 14 │ 15 │ 16 │ 17 │ 18 ││19│ 20 │21││ 22 │ 23 │ 24 │ 25 │ 26 │ 27 │  Row 1 (15)
├────┼────┼────┼────┼────┼────┤└──┼────┼──┘├────┼────┼────┼────┼────┼────┤
│ 28 │ 29 │ 30 │ 31 │ 32 │ 33 │   │ 34 │ 35│ 36 │ 37 │ 38 │ 39 │ 40 │ 41 │  Row 2 (14)
└────┴────┴────┼────┼────┼────┤   └────┴───┘────┼────┼────┼────┴────┴────┘
               │ 42 │ 43 │ 44 │            │ 45 │ 46 │ 47 │                 Thumbs (6)
               └────┴────┴────┘            └────┴────┴────┘

Total: 48 keys | Positions 0-47 (left-to-right, 0-indexed)
```

**Layer 0 (QWERTY) Current Mapping**:
```
Row 0: 0=`~  1=Q  2=W  3=E   4=R   5=T   6=↑   7=Y  8=U  9=I  10=O  11=←  12=→
Row 1: 13=⇧ 14=A 15=S 16=D  17=F  18=G  19=←  20=⏎ 21=→  22=H 23=J 24=K 25=L 26=P 27=⇧
Row 2: 28=⇪ 29=Z 30=X 31=C  32=V  33=B  34=␣  35=↓  36=N 37=M 38=, 39=. 40=/ 41=⇧
Thumb: 42=⌘ 43=␣ 44=⏎  45=⌫  46=L1  47=L2
```

**Layers**:
- Layer 0 (QWERTY): Base typing layer with nav arrows in center column
- Layer 1 (NUMBER): Numbers, Bluetooth/RGB controls
- Layer 2 (NAV): Mouse movement (ESDF), symbols, output switching (USB/BLE)
- Layer 3 (Fn): Function keys, bootloader, system reset

**Layer 0 Thumb Keys**:
- LEFT (42-44): GUI, SPACE, ENTER
- RIGHT (45-47): BACKSPACE, mo(1) NUMBER, mo(2) NAV

**Advanced Features Implemented**:
- **Macros**: Top-left key triggers Ctrl+Space (Mac input switching)
- **Tap-Dance**: td0 on left (Shift/Layer2) - originally TAB was backtick/tilde
- **Combo Keys**: Q+W = ESC (50ms timeout)
- **Modifier Combos** (RIGHT split, with slow-release):
  - H+J = CMD, J+K = OPTION, K+L = CTRL
  - H+J+K = CMD+OPTION, J+K+L = OPTION+CTRL, ,+. = CMD+CTRL
- **Mouse Movement**: Layer 2 (NAV) - E=UP, S=LEFT, D=DOWN, F=RIGHT (continuous while held)

**Important**: ZMK keymap arrays are defined **left-to-right**:
- Each row: LEFT (6 keys) + CENTER + RIGHT (6 keys)
- Center column has physical keys, not empty space
- See `vendor/keymap-diagrams/corne/` for visual reference

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
    ├── docs/                     # Documentation from vendor
    │   ├── *.doc                 # English documentation
    │   └── 中文说明/              # Chinese documentation (comprehensive guides)
    ├── keymap-diagrams/          # Visual keymap references
    │   └── corne/                # Layer diagrams (layer0-3.jpg)
    └── firmware/                 # Stock firmware (nice_oled - LEFT OLED works)
```

## Python Environment

This project uses Python tools for keymap visualization. Always activate the conda environment first:

```bash
source ~/.zshrc && conda activate base
```

## Quick Workflow

### 1. Edit Keymap
```bash
cd ~/zmk-corne-config
vim config/eyeslash_corne.keymap
```

### 2. Build Firmware via GitHub Actions (Recommended)

**Workflow:**
```bash
git add config/eyeslash_corne.keymap
git commit -m "feat: update keymap"
git push
```

**What happens automatically:**
1. **Draw Keymap workflow** (~30s):
   - Parses keymap and generates visual diagram
   - Commits `keymap-drawer/eyeslash_corne.svg` to repo
   - View updated layout before building firmware!

2. **Build ZMK firmware workflow** (~2 minutes):
   - Builds in parallel: dongle, left, right (4 jobs)
   - Uses cached west modules for speed
   - Creates "firmware" artifact with all .uf2 files

**Download firmware:**
```bash
# Method 1: Using gh CLI (fastest)
gh run list --limit 1  # Get latest run ID
gh run download <RUN_ID> --dir output/github

# Method 2: Via GitHub web UI
# Go to Actions tab → Click latest "Build ZMK firmware" → Download "firmware" artifact

# Copy for easier access
cp output/github/firmware/*.uf2 output/github/
# Results: dongle.uf2, left.uf2, right.uf2
```

**Why GitHub Actions?**
- ✅ No local Docker setup needed
- ✅ Parallel builds (faster than local)
- ✅ Automatic keymap visualization
- ✅ Build history and artifacts preserved
- ✅ Works from any machine

**Local Docker Build (Alternative):**
```bash
./build.sh
# Output: output/local/{dongle,left,right}.uf2
# Backup: output/backups/YYYYMMDD_HHMMSS/
# ~3-5 minutes first build, ~27 seconds with caching
```

### 3. Flash Firmware

**Complete Flash Workflow:**
```bash
# 1. Download firmware (if using GitHub Actions)
gh run download <RUN_ID> --dir output/github
cp output/github/firmware/eyeslash_corne_central_dongle_oled.uf2 output/github/dongle.uf2
cp "output/github/firmware/eyeslash_corne_peripheral_left nice_oled-nice_nano_v2-zmk.uf2" output/github/left.uf2
cp "output/github/firmware/eyeslash_corne_peripheral_right nice_oled-nice_nano_v2-zmk.uf2" output/github/right.uf2

# 2. Flash each device
# For each device (dongle, left, right):
#   a. Double-press RESET button (enters bootloader mode)
#   b. Device appears as NICENANO volume
#   c. Copy firmware:
cp output/github/dongle.uf2 /Volumes/NICENANO/
#   d. Device automatically reboots after copy
#   e. Repeat for left and right keyboards
```

**Interactive Flash Script (Alternative):**
```bash
./flash.sh
# Guides you through:
# - Selecting firmware source (local/github/backup/vendor)
# - Flashing each device step-by-step
# - Automatic detection of bootloader mode
```

**IMPORTANT**:
- Flash all 3 devices when updating keymap
- Flash order doesn't matter
- If a device doesn't work, try settings_reset.uf2 first, then reflash

---

## Choc (LCD) Keyboard Workflow

The Choc version uses a separate GitHub repository with the same keymap.

### 1. Edit Keymap (Same keymap file!)
The keymap is shared. Edit locally and push to both repos:
```bash
# Edit keymap
vim config/eyeslash_corne.keymap

# Push to Choc repo
cd ~/zmk-choc-corne  # Clone from PAN-Chuwen/zmk-choc-corne
cp ~/zmk-corne-config/config/eyeslash_corne.keymap config/eyelash_corne.keymap
git add . && git commit -m "feat: update keymap" && git push
```

### 2. Download Choc Firmware
```bash
# From this repo, download from Choc GitHub Actions
./download-choc-firmware.sh

# Or manually:
gh run list --repo PAN-Chuwen/zmk-choc-corne --limit 1
gh run download <RUN_ID> --repo PAN-Chuwen/zmk-choc-corne --dir output/choc/github
```

### 3. Flash Choc Firmware
```bash
./flash-choc.sh
# Only flashes LEFT and RIGHT (no dongle needed)
# LEFT connects via USB, RIGHT connects via Bluetooth to LEFT
```

---

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

- `config/eyeslash_corne.keymap` - **Main keymap configuration (4 layers: QWERTY, NUMBER, NAV, Fn)**
- `config/eyeslash_corne.conf` - Display, sleep, Bluetooth settings
- `config/eyeslash_corne.json` - ZMK Studio configuration (GUI editing)
- `build.yaml` - GitHub Actions build matrix
- `build.sh` - Parallel build script with automatic backups
- `flash.sh` - Interactive firmware flashing tool
- `docker-compose.yml` - Docker orchestration configuration
- `vendor/firmware/` - Stock firmware with working LEFT OLED
- `keymap.yaml` - Auto-generated parsed keymap (for visualization)
- `keymap.svg` - Auto-generated visual diagram of all layers

## Known Issues

**LEFT OLED not working with custom builds**:
- Custom builds use `nice_view_custom` shield
- LEFT OLED only works with vendor firmware (`nice_oled` shield)
- **Workaround**: Use vendor firmware for LEFT, or accept no OLED

## ZMK Advanced Features Guide

### Tap-Dance (Multiple actions on one key)

**Example: Backtick/Tilde key**
```c
behaviors {
    td_backtick: td_backtick {
        compatible = "zmk,behavior-tap-dance";
        #binding-cells = <0>;
        tapping-term-ms = <200>;
        bindings = <&kp GRAVE>, <&kp TILDE>;
    };
};
```
Usage: `&td_backtick` in keymap bindings
- Single tap: `` ` ``
- Double tap: `~`
- `tapping-term-ms`: Maximum time between taps (default 200ms)

### Combo Keys (Press multiple keys simultaneously)

**Example: Q+W = ESC**
```c
combos {
    compatible = "zmk,combos";
    combo_esc {
        timeout-ms = <50>;
        key-positions = <1 2>;  // Q=1, W=2
        bindings = <&kp ESC>;
    };
};
```
- `timeout-ms`: All keys must be pressed within this time
- `key-positions`: Array of key position indices (0-based, left-to-right)
- **Finding key positions**: Count from 0, left-to-right for each row including center column

### Macros (Automated key sequences)

**Example: Simple macro typing "aa" with delay**
```c
macros {
    test_aa: test_aa {
        compatible = "zmk,behavior-macro";
        #binding-cells = <0>;
        wait-ms = <1000>;  // Delay between actions
        tap-ms = <50>;     // How long to hold each tap
        bindings
            = <&macro_tap &kp A>
            , <&macro_tap &kp A>
            ;
    };
};
```
Usage: `&test_aa` in keymap bindings

**Macro modes**:
- `&macro_tap`: Press and release (like typing)
- `&macro_press`: Hold down (for modifiers)
- `&macro_release`: Release held key

**Example: Modifier macro (Ctrl+Space)**
```c
macros {
    ctrl_space: ctrl_space {
        compatible = "zmk,behavior-macro";
        #binding-cells = <0>;
        wait-ms = <50>;
        tap-ms = <50>;
        bindings
            = <&macro_press &kp LCTRL>
            , <&macro_tap &kp SPACE>
            , <&macro_release &kp LCTRL>
            ;
    };
};
```

### Momentary Layer Switch

**Usage**: `&mo <layer_number>`
- Hold: Activates layer
- Release: Returns to base layer
- Example: `&mo 1` switches to Layer 1 while held

### Example Combo Positions

For reference when defining combos:
- S+D (CTRL): `<15 16>`
- D+F (ALT): `<16 17>`
- F+G (CMD): `<17 18>`
- H+J (CMD): `<22 23>`
- J+K (ALT): `<23 24>`
- K+L (CTRL): `<24 25>`
- R+G (Input Switch): `<4 18>`

**Important**: Center column occupies positions 6, 19-21, 34-35.

## Keymap Visualization

Generate visual diagrams of your keymap using keymap-drawer:

```bash
# Install (first time only)
source ~/.zshrc && conda activate base
pip install keymap-drawer

# Generate visualization
keymap parse -z config/eyeslash_corne.keymap > keymap.yaml
keymap draw keymap.yaml > keymap.svg
```

Output: `keymap.svg` - Visual diagram of all layers

## Vendor Documentation

See `vendor/docs/`:
- `dongle users readme.doc` - Dongle setup instructions
- `Modification of Keymap.doc` - Complete keymap guide
- `Split keyboard manual.doc` - General usage

## Troubleshooting

**Connection issues**: Flash `settings_reset-*.uf2` to all devices, then reflash firmware

**Keys not working**: Ensure all 3 devices have matching firmware versions

**Build errors**: Pull latest Docker image: `docker pull zmkfirmware/zmk-build-arm:stable`
