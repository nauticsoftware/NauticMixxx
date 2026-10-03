#!/bin/sh
# Native Linux build. Does not use macOS/Windows dependencies or cross compilation.
set -eu
project=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version=$(cat "$project/VERSION")
work=${RX3_BUILD_ROOT:-"$project/build/test-candidate/$version-linux-$(uname -m)"}
jobs=${RX3_BUILD_JOBS:-1}
tests=${RX3_BUILD_TESTING:-ON}
case "$(uname -s)/$(uname -m)" in
  Linux/aarch64|Linux/x86_64) ;;
  *) printf 'Use 64-bit Linux (aarch64 or x86_64). See docs/LINUX-RASPBERRY-PI.md.\n' >&2; exit 1 ;;
esac
case "$jobs" in ''|*[!0-9]*|0) printf 'RX3_BUILD_JOBS must be a positive integer.\n' >&2; exit 1 ;; esac
case "$tests" in ON|OFF) ;; *) printf 'RX3_BUILD_TESTING must be ON or OFF.\n' >&2; exit 1 ;; esac
mkdir -p "$work"
work=$(CDPATH= cd -- "$work" && pwd)
archive="$work/mixxx-2.5.6.tar.gz"
if [ ! -f "$archive" ]; then
  curl --fail --location --retry 3 https://github.com/mixxxdj/mixxx/archive/refs/tags/2.5.6.tar.gz -o "$archive"
fi
printf '%s  %s\n' 9cfc9025d50d2511767ee52a07b8854f75c581f0585197d043bc219fcf9f9050 "$archive" | sha256sum -c -
source_tree="$work/mixxx-2.5.6"
digest=$(cat "$project"/patches/00[0-9][0-9]-*.patch | sha256sum | cut -d ' ' -f 1)
if [ ! -d "$source_tree" ]; then tar -xzf "$archive" -C "$work"; fi
marker="$source_tree/.rx3-patched"
if [ ! -f "$marker" ]; then
  for patch in "$project"/patches/00[0-9][0-9]-*.patch; do
    (cd "$source_tree" && GIT_CEILING_DIRECTORIES="$work" git apply --no-index "$patch")
  done
  printf '%s\n' "$digest" > "$marker"
fi
if [ "$(cat "$marker")" != "$digest" ] || [ ! -f "$source_tree/src/test/trackcapabilitypolicy_test.cpp" ]; then
  printf 'Source patches changed; choose a fresh RX3_BUILD_ROOT.\n' >&2; exit 1
fi
# Branding must be applied before Qt compiles its resource collection.
python3 "$project/packaging/linux/prepare-branding.py" "$source_tree" "$project"
cmake -S "$source_tree" -B "$work/native" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_INSTALL_PREFIX="$work/stage" -DCMAKE_INSTALL_LIBDIR=lib \
  -DQT6=ON -DQML=OFF -DOPTIMIZE=portable -DENGINEPRIME=OFF -DKEYFINDER=OFF \
  -DBUILD_LOW_MEMORY=ON -DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON \
  -DBUILD_TESTING="$tests" -DBUILD_BENCH=OFF
cmake --build "$work/native" --target mixxx --parallel "$jobs"
if [ "$tests" = ON ]; then
  cmake --build "$work/native" --target mixxx-test --parallel "$jobs"
  (cd "$source_tree" && QT_QPA_PLATFORM=offscreen "$work/native/mixxx-test" \
    --gtest_filter='Rx3*:RekordboxDecoderTimingTest.*:RekordboxUsbSessionAudioTest.*:RekordboxWaveformImporterTest.*' \
    --gtest_output="xml:$work/rx3-tests.xml")
fi
cmake --install "$work/native"
python3 "$project/packaging/linux/stage-package.py" "$work/stage" "$source_tree" "$project"
printf '\nBuilt NauticMixxx for %s. Start from a desktop session:\n  "%s/stage/bin/nauticmixxx"\n' "$(uname -m)" "$work"
