#!/usr/bin/env python3
"""
Migrate Vial keyboard layout to ZMK format - KEYS ONLY (no combos/macros yet)
"""

import json
import sys

# Vial to ZMK keycode mapping
KEYCODE_MAP = {
    'KC_NO': '&none',
    'KC_TRNS': '&trans',

    # Letters
    **{f'KC_{chr(i)}': f'&kp {chr(i)}' for i in range(ord('A'), ord('Z')+1)},

    # Numbers
    **{f'KC_{i}': f'&kp N{i}' for i in range(10)},

    # Function keys
    **{f'KC_F{i}': f'&kp F{i}' for i in range(1, 13)},

    # Modifiers
    'KC_LCTRL': '&kp LCTRL', 'KC_LSHIFT': '&kp LSHIFT', 'KC_LALT': '&kp LALT', 'KC_LGUI': '&kp LGUI',
    'KC_RCTRL': '&kp RCTRL', 'KC_RSHIFT': '&kp RSHIFT', 'KC_RALT': '&kp RALT', 'KC_RGUI': '&kp RGUI',

    # Special keys
    'KC_ENTER': '&kp ENTER', 'KC_ESC': '&kp ESC', 'KC_BSPACE': '&kp BSPC', 'KC_TAB': '&kp TAB',
    'KC_SPACE': '&kp SPACE', 'KC_CAPSLOCK': '&kp CAPS', 'KC_GRAVE': '&kp GRAVE',

    # Punctuation
    'KC_MINUS': '&kp MINUS', 'KC_EQUAL': '&kp EQUAL',
    'KC_LBRACKET': '&kp LBKT', 'KC_RBRACKET': '&kp RBKT',
    'KC_BSLASH': '&kp BSLH', 'KC_SCOLON': '&kp SEMI', 'KC_QUOTE': '&kp SQT',
    'KC_COMMA': '&kp COMMA', 'KC_DOT': '&kp DOT', 'KC_SLASH': '&kp FSLH',

    # Navigation
    'KC_UP': '&kp UP', 'KC_DOWN': '&kp DOWN', 'KC_LEFT': '&kp LEFT', 'KC_RIGHT': '&kp RIGHT',
    'KC_HOME': '&kp HOME', 'KC_END': '&kp END', 'KC_PGUP': '&kp PG_UP', 'KC_PGDOWN': '&kp PG_DN',
    'KC_INSERT': '&kp INS', 'KC_DELETE': '&kp DEL',
}

def convert_vial_keycode(vial_key):
    """Convert single Vial keycode to ZMK - simplified version"""
    if vial_key == -1 or vial_key is None:
        return None

    # Handle shifted keys
    if vial_key.startswith('LSFT(') and vial_key.endswith(')'):
        inner = vial_key[5:-1]
        if inner in KEYCODE_MAP:
            base = KEYCODE_MAP[inner].replace('&kp ', '')
            return f'&kp LS({base})'
        # Handle special cases
        keymap = {
            'KC_MINUS': 'UNDER', 'KC_EQUAL': 'PLUS', 'KC_LBRACKET': 'LBRC',
            'KC_RBRACKET': 'RBRC', 'KC_BSLASH': 'PIPE', 'KC_SCOLON': 'COLON',
            'KC_QUOTE': 'DQT', 'KC_COMMA': 'LT', 'KC_DOT': 'GT', 'KC_SLASH': 'QMARK',
            'KC_GRAVE': 'TILDE', 'KC_9': 'LPAR', 'KC_0': 'RPAR'
        }
        if inner in keymap:
            return f'&kp {keymap[inner]}'
        return f'&kp LS({inner})'

    # Layer switching
    if vial_key.startswith('TO('):
        return f'&to {vial_key[3:-1]}'
    if vial_key.startswith('MO('):
        return f'&mo {vial_key[3:-1]}'

    # Tap dance - skip for now, mark as TODO
    if vial_key.startswith('TD('):
        return f'&none /* TODO: TD{vial_key[3:-1]} */'

    # Macros - skip for now
    if vial_key.startswith('M') and len(vial_key) == 2:
        return f'&none /* TODO: MACRO{vial_key[1]} */'

    # One-shot mods - simplified
    if 'OSM(' in vial_key:
        return '&sk LSHIFT'

    # Special that we don't support yet
    if any(x in vial_key for x in ['ALL_T', 'HYPR', 'LCA', 'LCG', 'LCAG']):
        return '&none'

    # Direct mapping
    if vial_key in KEYCODE_MAP:
        return KEYCODE_MAP[vial_key]

    # Unknown
    return f'&none /* {vial_key} */'

def main():
    with open('vial.vil', 'r') as f:
        vial = json.load(f)

    print("=" * 70)
    print("Vial to ZMK Layout Migration - KEYS ONLY")
    print("=" * 70)

    # Process first 3 layers
    for layer_num in range(3):
        layer = vial['layout'][layer_num]

        print(f"\nLAYER {layer_num}:")
        print("-" * 70)

        # Vial layout: 4 rows per hand, 7 positions per row (some are -1)
        # Left hand: rows 0-3, Right hand: rows 4-7

        # Extract and print each row
        for row_idx, row in enumerate(layer):
            converted = []
            for key in row:
                if key != -1:
                    zmk_key = convert_vial_keycode(key)
                    if zmk_key:
                        converted.append(zmk_key)

            hand = "LEFT " if row_idx < 4 else "RIGHT"
            row_num = row_idx % 4
            print(f"  {hand} Row {row_num}: {' '.join(converted)}")

    print("\n" + "=" * 70)
    print("Next steps:")
    print("1. Review the output above")
    print("2. Manually map to Corne's 48-key layout (13+15+14+6)")
    print("3. Later: Add tap-dances, macros, combos")
    print("=" * 70)

if __name__ == '__main__':
    main()
