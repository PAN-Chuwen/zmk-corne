# ZMK Corne Dongle Configuration

Custom ZMK firmware configuration for the Eyeslash Corne split keyboard with USB dongle.

**Repository**: Forked from [tokyo2006/zmk-corne-dongle](https://github.com/tokyo2006/zmk-corne-dongle)

## Hardware

- **LEFT/RIGHT keyboards**: Bluetooth peripherals with OLED displays
- **USB Dongle**: Bluetooth central (connects to Mac via USB)
- **Connection**: Keyboards → Dongle (Bluetooth) → Mac (USB)

## Keyboard Layout

**Eyeslash Corne 48-key split keyboard with center column**:

```
    LEFT SPLIT (6 keys)      CENTER       RIGHT SPLIT (6 keys)
┌───┬───┬───┬───┬───┬───┐    ┌───┐    ┌───┬───┬───┬───┬───┬───┐
│TAB│ Q │ W │ E │ R │ T │    │ ↑ │    │ Y │ U │ I │ O │ P │BSP│  Row 0 (6+1+6 = 13)
├───┼───┼───┼───┼───┼───┤┌───┼───┼───┐├───┼───┼───┼───┼───┼───┤
│TD0│ A │ S │ D │ F │ G ││ ← │ENT│ → ││ H │ J │ K │ L │ . │ ' │  Row 1 (6+3+6 = 15)
├───┼───┼───┼───┼───┼───┤└───┼───┼───┘├───┼───┼───┼───┼───┼───┤
│SFT│ Z │ X │ C │ V │ B │    │SPC│    │ N │ M │ , │ ; │ / │ESC│  Row 2 (6+2+6 = 14)
└───┴───┴───┼───┼───┼───┤    └───┘    ├───┼───┼───┼───┴───┴───┘
            │GUI│ L1│ALT│              │ALT│ L2│BSP│              Thumbs (3+3 = 6)
            └───┴───┴───┘              └───┴───┴───┘

Total: 48 keys (6+6+6+3 LEFT, 1+3+2 CENTER, 6+6+6+3 RIGHT)
```

**Layers**:
- Layer 0 (QWERTY): Base typing layer with nav arrows in center column
- Layer 1 (NUMBER): Numbers, Bluetooth/RGB controls, mouse movement
- Layer 2 (SYMBOL): Symbols, brackets, output switching (USB/BLE)
- Layer 3 (Fn): Function keys, bootloader, system reset

**Layer 0 Thumb Keys**:
- LEFT: LGUI, SPACE, ENTER
- RIGHT: BSPC, mo(1), none

**Advanced Features Implemented**:
- **Tap-Dance**: Top-left key (was TAB) - single tap: `` ` ``, double tap: `~`
- **Combo Keys**: Q+W simultaneously outputs ESC (50ms timeout)
- **Momentary Layer**: Right thumb 2nd key - hold for Layer 1 (NUMBER), release returns to base
- **Macros**: Basic macro support tested and working

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

### Key Position Reference

48-key layout positions (0-indexed, left-to-right):
```
Row 0: 0-12   (6 LEFT + 1 CENTER + 6 RIGHT)
Row 1: 13-27  (6 LEFT + 3 CENTER + 6 RIGHT)
Row 2: 28-41  (6 LEFT + 2 CENTER + 6 RIGHT)
Row 3: 42-47  (3 LEFT thumbs + 3 RIGHT thumbs)
```

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
