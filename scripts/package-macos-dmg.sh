#!/bin/sh
# Build the public macOS DMG from a packaged NauticMixxx ZIP.
set -eu

project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version=$(cat "$project/VERSION")
release_dir=${1:-"$project/release/$version"}
archive="$release_dir/NauticMixxx-$version-macOS-arm64.zip"
output="$release_dir/NauticMixxx-$version-macOS-arm64.dmg"
background="$project/packaging/DMG_PROJECT/DMG_BG.jpg"

command -v create-dmg >/dev/null 2>&1 || {
  printf 'Falta create-dmg. Instálalo con: brew install create-dmg\n' >&2
  exit 1
}
[ -f "$archive" ] || {
  printf 'No se encontró el paquete macOS: %s\n' "$archive" >&2
  exit 1
}

temp=$(mktemp -d "${TMPDIR:-/tmp}/nauticmixxx-dmg.XXXXXX")
trap 'rm -rf "$temp"' EXIT HUP INT TERM
ditto -x -k "$archive" "$temp"
source_dir="$temp/NauticMixxx-$version-macOS-arm64"
app="$source_dir/NauticMixxx.app"
[ -d "$app" ] || {
  printf 'El ZIP no contiene NauticMixxx.app.\n' >&2
  exit 1
}

codesign --verify --deep --strict "$app"
icon="$temp/NauticMixxx.icns"
"$project/scripts/build-app-icon-macos.sh" "$icon"
dmg_root="$temp/dmg-root"
mkdir -p "$dmg_root"
ditto "$app" "$dmg_root/NauticMixxx.app"

if [ -e "$output" ]; then
  mv "$output" "$temp/previous.dmg"
fi

# The artwork is 600×360 and is designed for the app on the left and the
# Applications link on the right.
create-dmg \
  --volname "NauticMixxx $version" \
  --volicon "$icon" \
  --background "$background" \
  --window-pos 200 120 \
  --window-size 600 360 \
  --icon-size 112 \
  --icon "NauticMixxx.app" 128 180 \
  --hide-extension "NauticMixxx.app" \
  --app-drop-link 472 180 \
  --format UDZO \
  "$output" \
  "$dmg_root"

python3 - "$release_dir" "$output" <<'PY'
import hashlib
import json
from pathlib import Path
import sys

release_dir = Path(sys.argv[1]).resolve()
dmg = Path(sys.argv[2]).resolve()

def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

manifest_path = release_dir / "release-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
artifact = {"name": dmg.name, "bytes": dmg.stat().st_size, "sha256": sha256(dmg)}
manifest["artifacts"] = [
    item for item in manifest.get("artifacts", []) if item.get("name") != dmg.name
] + [artifact]
manifest["artifacts"].sort(key=lambda item: item["name"])
manifest_path.write_text(
    json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
)

artifacts = sorted(
    path
    for path in release_dir.iterdir()
    if path.is_file()
    and path.name not in {"SHA256SUMS.txt", "release-manifest.json"}
    and not path.name.endswith(".previous")
)
(release_dir / "SHA256SUMS.txt").write_text(
    "".join(f"{sha256(path)}  {path.name}\n" for path in artifacts + [manifest_path]),
    encoding="utf-8",
)
PY

printf 'DMG generado: %s\n' "$output"
