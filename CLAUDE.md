# ZMK Corne Configuration

Custom ZMK firmware configuration for the Eyeslash Corne split keyboard.

This repository manages **TWO keyboard variants**:

| Variant | Repository | Display | Devices |
|---------|------------|---------|---------|
| **Dongle (OLED)** | [zmk-corne-dongle](https://github.com/PAN-Chuwen/zmk-corne-dongle) | OLED | Dongle + Left + Right |
| **Choc (LCD)** | [zmk-corne-choc](https://github.com/PAN-Chuwen/zmk-corne-choc) | LCD (nice_view) | Left + Right only |

## Quick Start

```bash
# Build, wait, and download firmware (all automatic)
./zmk.sh build

# Flash firmware (interactive menu)
./zmk.sh flash

# Check build status
./zmk.sh status

# Generate keymap diagram (requires uv)
./zmk.sh draw
```

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
Row 0: 0=`~  1=Q  2=W  3=E   4=R   5=T   6=↑   7=Y  8=U  9=I  10=O  11=·  12=Fn
Row 1: 13=⇧ 14=A 15=S 16=D  17=F  18=G  19=←  20=⏎ 21=→  22=H 23=J 24=K 25=L 26=P 27=⇧
Row 2: 28=⇪ 29=Z 30=X 31=C  32=V  33=B  34=␣  35=↓  36=N 37=M 38=, 39=. 40=/ 41=⇧
Thumb: 42=⌘ 43=␣ 44=⏎  45=⌫  46=L1  47=L2
```

**Layers**:
- Layer 0 (QWERTY): Base typing layer with nav arrows in center column, Fn access at position 12
- Layer 1 (NUMBER): Numbers, symbols, mouse in center column
- Layer 2 (NAV): Mouse movement (ESDF on left), arrow keys, page nav, Hyper-key shortcuts (LG+LS+LC+LA) on Q/W/R/T/Y/U/I/A/G/H/N and Z/X/C/V/B
- Layer 3 (Fn): F1-F12 (left), Bluetooth profile select BT_SEL 0-3 (row 0 left), media/volume/brightness (right), BT_CLR on right thumb (pos 45)

**Thumb Keys**:
- LEFT (42-44): GUI, SPACE, ENTER
- RIGHT (45-47): BACKSPACE, mo(1) NUMBER, mo(2) NAV

**Advanced Features**:
- **Macros**: R+G combo triggers Ctrl+Space (Mac input switching)
- **Tap-Dance**: Backtick/Tilde, Colon/Semicolon, Quote/DoubleQuote, etc.
- **Combo Keys**: Q+W = ESC, Z+X = Shift+TAB, X+C = TAB
- **Modifier Combos** (with slow-release):
  - LEFT: S+D = CTRL, D+F = ALT, F+G = CMD
  - RIGHT: H+J = CMD, J+K = OPTION, K+L = CTRL
  - Multi-key: H+J+K = CMD+OPTION, J+K+L = OPTION+CTRL
- **Mouse Movement**: Layer 2 (NAV) - ESDF for directional control

## Repository Structure

```
~/zmk-corne/
├── config/                       # Edit these for customization
│   ├── eyeslash_corne.keymap    # Main keymap (layers, keys, behaviors)
│   ├── eyeslash_corne.conf      # Settings (display, Bluetooth, sleep)
│   ├── eyeslash_corne.json      # ZMK Studio configuration
│   ├── west.yml                 # Dependencies manifest (zmk pin, modules)
│   └── boards/shields/eyeslash_corne/
│                                 # Shield definition: dtsi, overlays,
│                                 # per-variant .conf files, Kconfig
│
├── .github/workflows/build.yml   # CI workflow (must pin to same zmk
│                                 # ref as west.yml — see Troubleshooting)
│
├── zmk.sh                        # Unified firmware management script
├── build.yaml                    # GitHub Actions build matrix
├── CLAUDE.md                     # This documentation
│
├── output/                       # Firmware outputs (gitignored)
│   ├── dongle/                   # dongle.uf2, left.uf2, right.uf2, settings_reset.uf2
│   └── choc/                     # left.uf2, right.uf2, settings_reset.uf2
│
└── vendor/                       # Reference materials
    ├── docs/                     # Vendor documentation
    ├── keymap-diagrams/          # Visual keymap references
    └── firmware/                 # Stock firmware backup
```

## Workflow

### 1. Edit Keymap
```bash
vim config/eyeslash_corne.keymap
```

### 2. Build

```bash
# Build both keyboards (waits and downloads automatically)
./zmk.sh build

# Build specific keyboard only
./zmk.sh build dongle
./zmk.sh build choc
```

### 3. Flash Firmware

```bash
./zmk.sh flash
# Interactive menu:
#   1) Dongle (OLED) - flashes dongle + left + right
#   2) Choc (LCD) - flashes left + right only
# Optional: Reset settings first (recommended for first flash)
```

**Manual Flash**:
1. Double-press RESET button (enters bootloader mode)
2. Device appears as NICENANO volume
3. Copy firmware: `cp output/dongle/dongle.uf2 /Volumes/NICENANO/`
4. Device automatically reboots

### 4. Generate Keymap Diagram

```bash
./zmk.sh draw
# Generates keymap.yaml, keymap.svg, and timestamped PNG
# Displays in terminal via chafa
# Requires: brew install uv librsvg
```

## zmk.sh Commands

| Command | Description |
|---------|-------------|
| `./zmk.sh build [dongle\|choc\|both]` | Build, wait, and download firmware (auto-syncs keymap) |
| `./zmk.sh flash` | Interactive firmware flashing |
| `./zmk.sh draw` | Generate keymap diagram (SVG + PNG) |
| `./zmk.sh status` | Show build status and local firmware |
| `./zmk.sh help` | Show help |

## Key Files

- `config/eyeslash_corne.keymap` - Main keymap (4 layers: QWERTY, NUMBER, NAV, Fn)
- `config/eyeslash_corne.conf` - Display, sleep, Bluetooth settings
- `config/eyeslash_corne.json` - ZMK Studio configuration (GUI editing)
- `build.yaml` - GitHub Actions build matrix
- `zmk.sh` - Unified firmware management script
- `vendor/firmware/` - Stock firmware backup

## ZMK Features Reference

### Tap-Dance
```c
td_backtick: td_backtick {
    compatible = "zmk,behavior-tap-dance";
    tapping-term-ms = <200>;
    bindings = <&kp GRAVE>, <&kp TILDE>;
};
```

### Combos
```c
combo_esc {
    timeout-ms = <50>;
    key-positions = <1 2>;  // Q+W
    bindings = <&kp ESC>;
};
```

### Macros
```c
input_switch: input_switch {
    compatible = "zmk,behavior-macro";
    bindings = <&macro_press &kp LCTRL>, <&macro_tap &kp SPACE>, <&macro_release &kp LCTRL>;
};
```

### Combo Positions Reference
- S+D (CTRL): `<15 16>`
- D+F (ALT): `<16 17>`
- F+G (CMD): `<17 18>`
- H+J (CMD): `<22 23>`
- J+K (ALT): `<23 24>`
- K+L (CTRL): `<24 25>`

## Troubleshooting

**Connection issues**: Flash `settings_reset.uf2` to all devices, then reflash firmware

**Keys not working**: Ensure all devices have matching firmware versions

**Build not triggering**: Check GitHub Actions is enabled on the repository

**Build fails with `KeyError: 'qualifiers'` / "Missing ZMK Compat"**: The `.github/workflows/build.yml` workflow ref must match `config/west.yml`'s `zmk` revision. If the workflow points at `@main` while `west.yml` pins an older release (e.g. `v0.3.0`), the GitHub Actions toolchain rolls forward to Zephyr 4.1 / HWMv2 and breaks. Pin both to the same tag.

**Choc right peripheral won't pair after a green build**: pinning the workflow to a release tag like `@v0.3.0` is *not* the same as pinning to the SHA that produced previously-working firmware. The workflow ref drives the entire build container/toolchain. To reproduce a known-working build, pin to its exact zmk@main SHA. Find the SHA from a date with successful runs:

```bash
gh api 'repos/zmkfirmware/zmk/commits?sha=main&until=2026-02-04T10:00:00Z&per_page=1' \
  --jq '.[0] | {sha, date: .commit.author.date}'
```

Then in `.github/workflows/build.yml`:
```yaml
uses: zmkfirmware/zmk/.github/workflows/build-user-config.yml@<sha>
```
