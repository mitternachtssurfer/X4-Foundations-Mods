#!/usr/bin/env bash
#
# Packs a mod's "src" folder into a .cat/.dat pair using x4cat (pure-Python,
# native Linux reimplementation of Egosoft's XRCatTool - no wine needed).
# https://github.com/meethune/x4cat
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

MOD_DIR=""
OUT_CAT="ext_01.cat"
SRC_PATH=""
CLEAN=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [-m MOD_DIR] [-o OUT_CAT] [-s SRC_PATH] [-c] [-h]

  -m MOD_DIR   Mod directory (default: interactive selection from subfolders of this script's directory)
  -o OUT_CAT   Output .cat filename (default: $OUT_CAT)
  -s SRC_PATH  Source directory (default: MOD_DIR/src)
  -c           Remove existing .cat/.dat before building
  -h           Show this help
EOF
}

while getopts "m:o:s:ch" opt; do
    case "$opt" in
        m) MOD_DIR="$OPTARG" ;;
        o) OUT_CAT="$OPTARG" ;;
        s) SRC_PATH="$OPTARG" ;;
        c) CLEAN=1 ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

if ! command -v x4cat >/dev/null 2>&1; then
    echo "x4cat not found in PATH. Install with: uv tool install git+https://github.com/meethune/x4cat.git" >&2
    exit 1
fi

if [ -z "$MOD_DIR" ]; then
    candidates=()
    while IFS= read -r -d '' dir; do
        candidates+=("$dir")
    done < <(find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d -not -name '.git' -print0 | sort -z)

    if [ "${#candidates[@]}" -eq 0 ]; then
        echo "No subfolders under '$SCRIPT_DIR' found. Please specify -m MOD_DIR." >&2
        exit 1
    fi

    echo "Please choose a mod directory:"
    for i in "${!candidates[@]}"; do
        printf '%d. %s\n' "$((i + 1))" "$(basename "${candidates[$i]}")"
    done

    while true; do
        read -rp "Enter number: " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#candidates[@]}" ]; then
            break
        fi
    done

    MOD_DIR="${candidates[$((selection - 1))]}"
fi

if [ -z "$SRC_PATH" ]; then
    SRC_PATH="$MOD_DIR/src"
fi

if [ ! -d "$MOD_DIR" ]; then
    echo "Mod directory not found: $MOD_DIR" >&2
    exit 1
fi

if [ ! -d "$SRC_PATH" ]; then
    echo "Source directory not found: $SRC_PATH" >&2
    exit 1
fi

OUT_CAT_PATH="$MOD_DIR/$OUT_CAT"
OUT_DAT_PATH="${OUT_CAT_PATH%.*}.dat"

if [ "$CLEAN" -eq 1 ]; then
    rm -f "$OUT_CAT_PATH" "$OUT_DAT_PATH"
fi

x4cat pack "$SRC_PATH" -o "$OUT_CAT_PATH"

if [ ! -f "$OUT_CAT_PATH" ] || [ ! -f "$OUT_DAT_PATH" ]; then
    echo "Packing completed, but CAT/DAT not fully generated." >&2
    exit 1
fi

ls -l "$OUT_CAT_PATH" "$OUT_DAT_PATH"
