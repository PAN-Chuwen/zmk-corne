# ZMK Corne Configuration

[English](README.md) | [中文](README_CN.md)

Custom ZMK firmware for the Eyeslash Corne 42-key split keyboard.

## Keyboard Variants

| Variant | Display | Connection | Firmware | Buy |
|---------|---------|------------|----------|-----|
| **Dongle (OLED)** | OLED | Keyboards → Dongle (BT) → Mac (USB) | [zmk-corne-dongle](https://github.com/PAN-Chuwen/zmk-corne-dongle) | [Keyboard](https://e.tb.cn/h.74bzHdyUEMXPbX6?tk=cd7PfxaLxbs) + [Dongle](https://e.tb.cn/h.7VsTwLbeqbA7mkb?tk=IM08fxaOSZd) |
| **Choc (LCD)** | nice_view LCD | Right → Left (BT) → Mac (USB) | [zmk-corne-choc](https://github.com/PAN-Chuwen/zmk-corne-choc) | [Taobao](https://e.tb.cn/h.74bHNHPbyg9pZ7X?tk=Pt48fxaQkwL) |

## Keymap

> This is my personal keymap. Fork this repo and edit `config/eyeslash_corne.keymap` to customize your own layout.

![Keymap](keymap/keymap.svg)

## Quick Start

```bash
# Build firmware (triggers GitHub Actions)
./zmk.sh build

# Flash firmware (interactive)
./zmk.sh flash

# Generate keymap diagram
./zmk.sh draw
```

## Features

- **4 Layers**: QWERTY, Numbers/Symbols, Navigation, Function keys
- **Tap-Dance**: Backtick/Tilde, Colon/Semicolon, Quote/DoubleQuote
- **Combos**: Q+W = ESC, modifier combos on home row (S+D = Ctrl, etc.)
- **Macros**: R+G triggers Ctrl+Space (input switching)

## License

MIT
