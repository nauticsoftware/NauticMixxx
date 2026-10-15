#!/bin/sh
# Rebuild NauticMixxx from official Mixxx 2.5.6 sources.
set -eu
project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
# macOS arch selection: arm64 (Apple Silicon) or x64 (Intel).
# Override with RX3_MACOS_ARCH=x64|arm64. Defaults to the host machine.
host_machine=$(uname -m)
case "${RX3_MACOS_ARCH:-$host_machine}" in
  arm64|aarch64) macos_arch=arm64 ;;
  x86_64|x64) macos_arch=x64 ;;
  *) printf 'RX3_MACOS_ARCH no soportado: %s (usa arm64 o x64)\n' "${RX3_MACOS_ARCH:-$host_machine}" >&2; exit 1 ;;
esac
case "$macos_arch" in
  arm64)
    deps_name=mixxx-deps-2.5-arm64-osx-min1100-release-40c29ff
    deps_sha=b76685e77f681baf8fdc5037297b0f16d323a405d09ce276d8844304530278e1
    vcpkg_target_triplet=arm64-osx-min1100-release
    ;;
  x64)
    deps_name=mixxx-deps-2.5-x64-osx-min1100-release-40c29ff
    deps_sha=a9b7dd2cb9ab00db6d05ac1f05aab933ed0ab2697f71db1a1bad70305befcf1b
    vcpkg_target_triplet=x64-osx-min1100-release
    ;;
esac
vcpkg_host_triplet=x64-osx-min1100-release
# Qt6 links the legacy AGL framework, which Apple removed from recent SDKs
# (macOS 26+). Pin the build to the newest installed SDK that still provides
# it. Override with RX3_MACOS_SDK=/path/to/MacOSXxx.x.sdk. Unset means
# auto-detect; without an AGL-bearing SDK the link step is expected to fail.
if [ -n "${RX3_MACOS_SDK:-}" ]; then
  macos_sdk="$RX3_MACOS_SDK"
else
  macos_sdk=""
  for candidate_sdk in MacOSX15.4.sdk MacOSX15.sdk MacOSX14.4.sdk MacOSX14.sdk MacOSX13.3.sdk MacOSX13.sdk; do
    if [ -d "/Library/Developer/CommandLineTools/SDKs/$candidate_sdk/System/Library/Frameworks/AGL.framework" ]; then
      macos_sdk="/Library/Developer/CommandLineTools/SDKs/$candidate_sdk"
      break
    fi
  done
fi
if [ -n "$macos_sdk" ]; then
  printf 'macOS SDK: %s\n' "$macos_sdk"
  sdk_cmake_arg="-DCMAKE_OSX_SYSROOT=$macos_sdk"
else
  printf 'Aviso: ningún SDK instalado provee AGL.framework; el enlazado puede fallar.\n' >&2
  sdk_cmake_arg=""
fi
work=${RX3_BUILD_ROOT:-"$project/build/test-candidate/$(cat "$project/VERSION")-macOS-$macos_arch"}
printf 'Arquitectura macOS: %s (%s)\n' "$macos_arch" "$vcpkg_target_triplet"
mkdir -p "$work"
fetch() {
  if [ ! -f "$2" ]; then curl --fail --location --retry 3 "$1" -o "$2"; fi
  actual=$(shasum -a 256 "$2" | awk '{print $1}')
  if [ "$actual" != "$3" ]; then printf 'SHA-256 incorrecto: %s\n' "$2" >&2; exit 1; fi
}
fetch https://github.com/mixxxdj/mixxx/archive/refs/tags/2.5.6.tar.gz \
  "$work/mixxx-2.5.6.tar.gz" 9cfc9025d50d2511767ee52a07b8854f75c581f0585197d043bc219fcf9f9050
fetch "https://downloads.mixxx.org/dependencies/2.5-rel/macOS/$deps_name.zip" \
  "$work/dependencies.zip" "$deps_sha"
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
  printf 'La carpeta fuente no coincide con el conjunto de parches NauticMixxx; usa otro RX3_BUILD_ROOT.\n' >&2
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
  printf 'La carpeta fuente no coincide con el conjunto de parches NauticMixxx; usa otro RX3_BUILD_ROOT.\n' >&2
  exit 1
fi
deps="$work/buildenv/$deps_name"
python3 "$project/scripts/sparkle-sdk.py" --destination "$work/sparkle"
python3 "$project/scripts/prepare-app-branding.py" "$source_tree" "$project"
"$project/scripts/build-app-icon-macos.sh" "$source_tree/res/osx/application.icns"
cmake -S "$work/mixxx-2.5.6" -B "$work/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DNAUTICMIX_VERSION="$(cat "$project/VERSION")" \
  -DNAUTIC_SPARKLE_FRAMEWORK="$work/sparkle/Sparkle.framework" \
  -DCMAKE_TOOLCHAIN_FILE="$deps/scripts/buildsystems/vcpkg.cmake" \
  -DMIXXX_VCPKG_ROOT="$deps" -DVCPKG_TARGET_TRIPLET="$vcpkg_target_triplet" \
  -DVCPKG_HOST_TRIPLET="$vcpkg_host_triplet" \
  -DQT6=ON -DQML=OFF -DAU_EFFECTS=OFF -DMACOS_BUNDLE=ON \
  '-DMACOS_BUNDLE_NAME=NauticMixxx' \
  '-DMACOS_BUNDLE_IDENTIFIER=org.mixxx.mixxx' \
  -DBUILD_TESTING=ON -DBUILD_BENCH=OFF ${sdk_cmake_arg:+"$sdk_cmake_arg"}
cmake --build "$work/build" --target mixxx mixxx-test --parallel "${RX3_BUILD_JOBS:-6}"
(cd "$work/build" && QT_QPA_PLATFORM=offscreen NAUTIC_SKIN_DIR="$project/skins/XDJ_RX3_Mixxx" NAUTIC_RX3_STYLESHEET="$project/skins/XDJ_RX3_Mixxx/style.qss" ./mixxx-test \
  --gtest_filter='IntegratedUpdaterTest.*:UpdatePayloadTest.*:StartupUpdateCheckerTest.*:StartupUpdateDialogTest.*:StreamCompletionTest.*:LibraryTableViewStateTest.*:Rx3*:RekordboxDecoderTimingTest.*:RekordboxUsbSessionAudioTest.*:RekordboxWaveformImporterTest.*' \
  --gtest_output=xml:rx3-tests.xml)
cmake --install "$work/build" --prefix "$work/stage"
app="$work/stage/NauticMixxx.app"
ditto "$project/skins/XDJ_RX3_Mixxx" "$app/Contents/Resources/skins/XDJ_RX3_Mixxx"
ditto "$project/controllers/Hercules_DJControl_Inpulse_500_RX3" "$app/Contents/Resources/controllers"
ditto "$project/controllers/Pioneer_DDJ_FLX4_RX3" "$app/Contents/Resources/controllers"
ditto "$project/controllers/Pioneer_DDJ_FLX6_RX3" "$app/Contents/Resources/controllers"
ditto "$project/controllers/Pioneer_Roland_RX3" "$app/Contents/Resources/controllers"
mkdir -p "$app/Contents/Resources/effects/chains" "$app/Contents/Resources/licenses"
ditto "$project/effects/chains" "$app/Contents/Resources/effects/chains"
cp "$project/skins/XDJ_RX3_Mixxx/LICENSE" "$app/Contents/Resources/licenses/NauticMixxx-GPL-3.0.txt"
cp "$work/mixxx-2.5.6/LICENSE" "$app/Contents/Resources/licenses/Mixxx-LICENSE.txt"
cp "$project/THIRD_PARTY_NOTICES.md" "$app/Contents/Resources/licenses/THIRD_PARTY_NOTICES.md"
"$project/scripts/build-app-icon-macos.sh" "$app/Contents/Resources/application.icns"
# Mixxx also installs a secondary copy under Resources/osx. Keep both copies
# identical, while CFBundleIconFile resolves the root Resources copy.
mkdir -p "$app/Contents/Resources/osx"
cp "$app/Contents/Resources/application.icns" "$app/Contents/Resources/osx/application.icns"
plutil -replace CFBundleDisplayName -string NauticMixxx "$app/Contents/Info.plist"
plutil -replace CFBundleName -string NauticMixxx "$app/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$(cat "$project/VERSION")" "$app/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$(cat "$project/VERSION")" "$app/Contents/Info.plist"
plutil -replace NSHumanReadableCopyright -string 'NauticMixxx contributors and Mixxx Development Team' "$app/Contents/Info.plist"
signing_identity=${NAUTIC_SIGNING_IDENTITY:--}
NAUTIC_SIGNING_IDENTITY="$signing_identity" python3 "$project/scripts/configure-updater-macos.py" --app "$app" --sdk "$work/sparkle"
codesign --verify --deep --strict "$app"
printf 'Aplicación reconstruida: %s\n' "$app"
