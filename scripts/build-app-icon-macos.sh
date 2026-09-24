#!/bin/sh
# Build a legacy .icns from the editable Icon Composer project.
set -eu

project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
# This is the canonical NauticMixxx application icon. Keep the exact source
# path in the release inputs so builds never fall back to Mixxx's native icon.
source_png="$project/packaging/DMG_PROJECT/iCon-macOS-Dark-1024x1024@1x.png"
output=${1:-"$project/build/NauticMixxx.icns"}

if [ ! -f "$source_png" ]; then
  printf 'No se encontró el icono canónico de NauticMixxx: %s\n' "$source_png" >&2
  exit 1
fi

icon_temp=$(mktemp -d "${TMPDIR:-/tmp}/nauticmixxx-icon.XXXXXX")
trap 'rm -rf "$icon_temp"' EXIT HUP INT TERM
iconset="$icon_temp/NauticMixxx.iconset"
mkdir -p "$iconset" "$(dirname -- "$output")"

render() {
  size=$1
  name=$2
  sips -s format png -z "$size" "$size" "$source_png" \
    --out "$iconset/$name" >/dev/null
}

render 16 icon_16x16.png
render 32 icon_16x16@2x.png
render 32 icon_32x32.png
render 64 icon_32x32@2x.png
render 128 icon_128x128.png
render 256 icon_128x128@2x.png
render 256 icon_256x256.png
render 512 icon_256x256@2x.png
render 512 icon_512x512.png
render 1024 icon_512x512@2x.png

iconutil --convert icns --output "$output" "$iconset"
printf 'Icono generado: %s\n' "$output"
