#!/bin/sh
# Assemble a separate macOS test app from an existing native build.
set -eu

project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
candidate_name=${1:?Uso: package-test-candidate-macos.sh VERSION-REVISION [BUILD_DIR]}
case "$candidate_name" in
  *[!A-Za-z0-9._-]*|'') printf 'Nombre de candidato inválido.\n' >&2; exit 1 ;;
esac
build_dir=${2:-"$project/tmp/v1.1/build"}
candidate="$project/build/test-candidate/$candidate_name"
if [ -e "$candidate" ]; then
  printf 'El test candidate ya existe: %s\n' "$candidate" >&2
  exit 1
fi
mkdir -p "$candidate"
cmake --install "$build_dir" --prefix "$candidate"
app="$candidate/NauticMixxx.app"
resources="$app/Contents/Resources"
ditto "$project/skins/XDJ_RX3_Mixxx" "$resources/skins/XDJ_RX3_Mixxx"
ditto "$project/controllers/Hercules_DJControl_Inpulse_500_RX3" "$resources/controllers"
ditto "$project/controllers/Pioneer_DDJ_FLX6_RX3" "$resources/controllers"
ditto "$project/controllers/Pioneer_DDJ_FLX4_RX3" "$resources/controllers"
ditto "$project/controllers/Pioneer_Roland_RX3" "$resources/controllers"
mkdir -p "$resources/profiles" "$resources/effects/chains" "$resources/licenses"
cp "$project/profile/XDJ_RX3_Mixxx.profile.cfg" "$resources/profiles/"
ditto "$project/effects/chains" "$resources/effects/chains"
cp "$project/skins/XDJ_RX3_Mixxx/LICENSE" "$resources/licenses/NauticMixxx-GPL-3.0.txt"
cp "$project/THIRD_PARTY_NOTICES.md" "$resources/licenses/THIRD_PARTY_NOTICES.md"

# Always generate the icon from NauticMixxx branding; never inherit Mixxx's.
"$project/scripts/build-app-icon-macos.sh" "$candidate/NauticMixxx.icns"
cp "$candidate/NauticMixxx.icns" "$resources/application.icns"
if [ -d "$resources/osx" ]; then
  cp "$candidate/NauticMixxx.icns" "$resources/osx/application.icns"
fi
cmp "$candidate/NauticMixxx.icns" "$resources/application.icns"
rm "$candidate/NauticMixxx.icns"

plutil -replace CFBundleDisplayName -string "NauticMixxx $candidate_name Test" "$app/Contents/Info.plist"
plutil -replace CFBundleName -string "NauticMixxx $candidate_name Test" "$app/Contents/Info.plist"
version=$(cat "$project/VERSION")
plutil -replace CFBundleShortVersionString -string "$version" "$app/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$version" "$app/Contents/Info.plist"
python3 "$project/scripts/configure-nauticmixxx-profile.py" --app "$app" --profile-dir "$candidate/profile"
ditto "$candidate/profile" "$resources/nautic-test-profile"
python3 - "$resources/nautic-test-profile/mixxx.cfg" "$candidate/profile" <<'PY'
import pathlib
import sys
config = pathlib.Path(sys.argv[1])
config.write_text(config.read_text().replace(sys.argv[2], '@NAUTIC_TEST_PROFILE@'))
PY
safe_id=$(printf '%s' "$candidate_name" | tr '._' '-')
plutil -replace CFBundleIdentifier -string "org.nauticsoftware.nauticmixxx.test.v$safe_id" "$app/Contents/Info.plist"
codesign --force --deep --sign - --entitlements "$project/packaging/macos/mixxx-entitlements.plist" "$app"
codesign --verify --deep --strict "$app"
cp "$project/docs/DDJ-FLX4-EN.md" "$candidate/DDJ-FLX4-EN.md"
cp "$project/docs/CONTROLLERS-RX3-1.5.md" "$candidate/CONTROLLERS-RX3-1.5.md"
cp "$project/docs/JOG-CALIBRATION-1.5.md" "$candidate/JOG-CALIBRATION-1.5.md"
cp "$project/docs/CONTROLLERS-RX3-1.5-EN.md" "$candidate/CONTROLLERS-RX3-1.5-EN.md"
cp "$project/docs/JOG-CALIBRATION-1.5-EN.md" "$candidate/JOG-CALIBRATION-1.5-EN.md"
app_name="NauticMixxx-$candidate_name-test.app"
mv "$app" "$candidate/$app_name"

cat > "$candidate/ABRIR-PRUEBA.command" <<EOF
#!/bin/sh
set -eu
candidate_dir=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)
app="\$candidate_dir/$app_name"
if [ ! -x "\$app/Contents/MacOS/NauticMixxx" ]; then
  printf 'Falta la aplicación de prueba en %s\n' "\$candidate_dir" >&2
  exit 1
fi
open -n -a "\$app"
EOF
chmod +x "$candidate/ABRIR-PRUEBA.command"
printf 'Test candidate: %s\n' "$candidate"
