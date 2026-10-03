#!/bin/sh
# Debian 12/13 and Ubuntu 24.04; all dependencies come from free apt repositories.
set -eu
if [ "$(uname -s)" != Linux ] || ! command -v apt-get >/dev/null; then
  printf 'This dependency recipe requires Debian, Raspberry Pi OS or Ubuntu Linux.\n' >&2
  exit 1
fi
if [ "$(id -u)" -eq 0 ]; then elevation=; else elevation=sudo; fi
$elevation apt-get update
# Keep the installed JACK implementation, rather than removing JACK2 for JACK1.
jack=libjack-dev
if dpkg-query -W -f='${Status}' libjack-jackd2-0 2>/dev/null | grep -q 'install ok installed'; then
  jack=libjack-jackd2-dev
fi
$elevation apt-get install -y --no-install-recommends \
  build-essential cmake ninja-build pkg-config git curl ca-certificates python3 python3-pil fonts-open-sans \
  libavcodec-dev libavformat-dev libavutil-dev libswresample-dev \
  libchromaprint-dev libebur128-dev libfftw3-dev libflac-dev libgmock-dev libgtest-dev \
  libgl1-mesa-dev libhidapi-dev libid3tag0-dev liblilv-dev libmad0-dev libmodplug-dev \
  libmp3lame-dev libmsgsl-dev libogg-dev libopus-dev libopusfile-dev libportmidi-dev \
  libprotobuf-dev libqt6core5compat6-dev libqt6opengl6-dev libqt6sql6-sqlite \
  libqt6svg6-dev librubberband-dev libshout-idjc-dev libsndfile1-dev libsoundtouch-dev \
  libsqlite3-dev libssl-dev libtag1-dev libudev-dev libupower-glib-dev libusb-1.0-0-dev \
  libvorbis-dev libwavpack-dev libx11-dev lv2-dev portaudio19-dev protobuf-compiler \
  qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-qpa-plugins \
  qt6-shadertools-dev qt6-tools-dev-tools qtkeychain-qt6-dev "$jack"
# Newer Debian releases split Qt's SVG image-format plugin into this package.
if apt-cache show qt6-svg-plugins >/dev/null 2>&1; then
  $elevation apt-get install -y --no-install-recommends qt6-svg-plugins
fi
