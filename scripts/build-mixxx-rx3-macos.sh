#!/bin/sh
# Rebuild NauticMixxx from official Mixxx 2.5.6 sources.
set -eu
project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=${RX3_BUILD_ROOT:-"$project/tmp/mixxx-native-rebuild"}
deps_name=mixxx-deps-2.5-arm64-osx-min1100-release-40c29ff
mkdir -p "$work"
fetch() {
  if [ ! -f "$2" ]; then curl --fail --location --retry 3 "$1" -o "$2"; fi
  actual=$(shasum -a 256 "$2" | awk '{print $1}')
  if [ "$actual" != "$3" ]; then printf 'SHA-256 incorrecto: %s\n' "$2" >&2; exit 1; fi
}
fetch https://github.com/mixxxdj/mixxx/archive/refs/tags/2.5.6.tar.gz \
  "$work/mixxx-2.5.6.tar.gz" 9cfc9025d50d2511767ee52a07b8854f75c581f0585197d043bc219fcf9f9050
fetch "https://downloads.mixxx.org/dependencies/2.5-rel/macOS/$deps_name.zip" \
  "$work/dependencies.zip" b76685e77f681baf8fdc5037297b0f16d323a405d09ce276d8844304530278e1
if [ ! -d "$work/buildenv/$deps_name" ]; then
  mkdir -p "$work/buildenv"
  unzip -q "$work/dependencies.zip" -d "$work/buildenv"
fi
patch_digest=$(cat "$project"/patches/00[0-9][0-9]-*.patch | shasum -a 256 | awk '{print $1}')
source_tree="$work/mixxx-2.5.6"
patch_marker="$source_tree/.rx3-patched"
patch_signature="$source_tree/src/test/trackcapabilitypolicy_test.cpp"
if [ ! -d "$source_tree" ]; then
  tar -xzf "$work/mixxx-2.5.6.tar.gz" -C "$work"
fi
if [ -f "$patch_marker" ] && [ "$(cat "$patch_marker")" != "$patch_digest" ]; then
  printf 'La carpeta fuente no coincide con los diez parches NauticMixxx; usa otro RX3_BUILD_ROOT.\n' >&2
  exit 1
fi
if [ ! -f "$patch_signature" ]; then
  for patch in "$project"/patches/00[0-9][0-9]-*.patch; do
    # The extracted tarball is nested inside the Mixxx working tree but is not
    # a repository. --no-index plus the ceiling keeps paths relative to this
    # source tree instead of accidentally applying them to the parent repo.
    (cd "$source_tree" && GIT_CEILING_DIRECTORIES="$work" git apply --no-index "$patch")
  done
  printf '%s\n' "$patch_digest" > "$patch_marker"
fi
if [ ! -f "$patch_marker" ] || [ ! -f "$patch_signature" ] || [ "$(cat "$patch_marker")" != "$patch_digest" ]; then
  printf 'La carpeta fuente no coincide con los diez parches NauticMixxx; usa otro RX3_BUILD_ROOT.\n' >&2
  exit 1
fi
deps="$work/buildenv/$deps_name"
cmake -S "$work/mixxx-2.5.6" -B "$work/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_TOOLCHAIN_FILE="$deps/scripts/buildsystems/vcpkg.cmake" \
  -DMIXXX_VCPKG_ROOT="$deps" -DVCPKG_TARGET_TRIPLET=arm64-osx-min1100-release \
  -DVCPKG_HOST_TRIPLET=x64-osx-min1100-release \
  -DQT6=ON -DQML=OFF -DAU_EFFECTS=OFF -DMACOS_BUNDLE=ON \
  '-DMACOS_BUNDLE_NAME=NauticMixxx' \
  '-DMACOS_BUNDLE_IDENTIFIER=org.mixxx.mixxx' \
  -DBUILD_TESTING=ON -DBUILD_BENCH=OFF
cmake --build "$work/build" --target mixxx mixxx-test --parallel "${RX3_BUILD_JOBS:-6}"
(cd "$work/build" && QT_QPA_PLATFORM=offscreen ./mixxx-test \
  --gtest_filter='Rx3*')
cmake --install "$work/build" --prefix "$work/stage"
app="$work/stage/NauticMixxx.app"
ditto "$project/skins/XDJ_RX3_Mixxx" "$app/Contents/Resources/skins/XDJ_RX3_Mixxx"
ditto "$project/controllers/Hercules_DJControl_Inpulse_500_RX3" "$app/Contents/Resources/controllers"
mkdir -p "$app/Contents/Resources/effects/chains" "$app/Contents/Resources/licenses"
ditto "$project/effects/chains" "$app/Contents/Resources/effects/chains"
cp "$project/skins/XDJ_RX3_Mixxx/LICENSE" "$app/Contents/Resources/licenses/NauticMixxx-GPL-3.0.txt"
cp "$work/mixxx-2.5.6/LICENSE" "$app/Contents/Resources/licenses/Mixxx-LICENSE.txt"
cp "$project/THIRD_PARTY_NOTICES.md" "$app/Contents/Resources/licenses/THIRD_PARTY_NOTICES.md"
"$project/scripts/build-app-icon-macos.sh" "$app/Contents/Resources/application.icns"
# Mixxx also installs a secondary copy under Resources/osx. Keep both copies
# identical, while CFBundleIconFile resolves the root Resources copy.
cp "$app/Contents/Resources/application.icns" "$app/Contents/Resources/osx/application.icns"
plutil -replace CFBundleDisplayName -string NauticMixxx "$app/Contents/Info.plist"
plutil -replace CFBundleName -string NauticMixxx "$app/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string 1.0.0 "$app/Contents/Info.plist"
plutil -replace CFBundleVersion -string 1.0.0 "$app/Contents/Info.plist"
plutil -replace NSHumanReadableCopyright -string 'NauticMixxx contributors and Mixxx Development Team' "$app/Contents/Info.plist"
signing_identity=${NAUTIC_SIGNING_IDENTITY:--}
codesign --force --deep --sign "$signing_identity" --entitlements "$project/packaging/macos/mixxx-entitlements.plist" "$app"
codesign --verify --deep --strict "$app"
printf 'Aplicación reconstruida: %s\n' "$app"
