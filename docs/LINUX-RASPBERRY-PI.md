# Linux and Raspberry Pi 4 — NauticMixxx 1.5

## Is it possible, and is it free?

Yes: NauticMixxx is based on Mixxx 2.5.6, which supports Linux. The repository now
includes a native 64-bit Linux build recipe, using free software and distribution
packages. No paid compiler, Windows/macOS license, subscription, or cross compiler
is required. You still need an existing computer/Pi, storage, power and Internet
access; this does not make those physical costs disappear.

**Raspberry Pi 4 is an experimental target.** A successful ARM64 server build
does not prove that a Pi 4 can render the RX3 display and play two decks without
audio dropouts. GPU drivers, display resolution, cooling, available RAM, USB audio
and the particular controller must be tested on the actual Pi.

The source repository contains NauticMixxx overlays and patches, rather than a
complete Mixxx CMake tree. Running `cmake -S .` in its root will fail. The Linux
script downloads the official, SHA-256-checked Mixxx **2.5.6** archive, applies all
17 patches, compiles the native program and installs the RX3 components. A stock
Mixxx installation with only the skin does not include the native RX3 browser.
Without the user's original build log, the cause of their failure is unknown.

## Target systems and verification

| System | Status |
| --- | --- |
| Ubuntu 24.04 x86_64 | Native build and test workflow provided; see linked Actions results |
| Ubuntu 24.04 ARM64 | Native build and test workflow provided; not Pi hardware |
| Debian 12 ARM64 | Separate native Bookworm container workflow; closer to Raspberry Pi OS Bookworm's userland, not Pi hardware |
| Raspberry Pi OS 64-bit desktop, Debian 12 Bookworm / 13 Trixie | Native build recipe; physical Pi testing pending |
| 32-bit Raspberry Pi OS (`armv7l`/`armhf`) | Not supported by this initial recipe |
| Headless / Raspberry Pi OS Lite | Needs a graphical desktop and working OpenGL; not the initial target |

Prefer a 64-bit desktop OS on Pi 4. Check the installed userland, not only the
kernel: `getconf LONG_BIT` must return `64`, and `dpkg --print-architecture` must
return `arm64`. The recipe needs Qt **6.2 or newer**; older Bullseye-based images
are outside this recipe. Do not replace your OS just to diagnose an error; first
collect the information listed below.

### Build on your own Linux computer or Pi

Use the current `main` checkout. The original v1.5.0 macOS/Windows release source
archives and tag predate this Linux recipe and do not contain these scripts.
If Git is not installed, install it first with `sudo apt-get install git`.

```sh
git clone https://github.com/nauticsoftware/NauticMixxx.git
cd NauticMixxx
./scripts/install-linux-build-deps.sh
RX3_BUILD_JOBS=1 ./scripts/build-mixxx-rx3-linux.sh 2>&1 | tee linux-build.log
```

The dependency step uses `sudo apt-get` and installs packages; the build and app
run as your ordinary user. On a minimal Ubuntu install, enable the distribution's
`universe` repository if required packages are unavailable. No third-party PPA is
needed. The recipe disables QML, Denon Engine export and local key detection to
avoid unnecessary builds; the RX3 XML skin, Rekordbox metadata/key display,
controller scripting, decoders and effects remain available. NauticMixxx already
disables local track analysis and scanning by design.

Start the resulting application **inside your desktop session**:

```sh
./build/test-candidate/1.5.0-linux-$(uname -m)/stage/bin/nauticmixxx
```

It uses the NauticMixxx icon, English by default and an isolated profile at
`${XDG_CONFIG_HOME:-$HOME/.config}/NauticMixxx`. Existing official Mixxx profiles
are not migrated. Your saved choices are preserved on subsequent launches.
You can use `NAUTICMIXXX_PROFILE=/another/path` for an isolated hardware test.

Optional desktop menu entry (keep the staged folder in its final location first):

```sh
./build/test-candidate/1.5.0-linux-$(uname -m)/stage/bin/nauticmixxx --install-desktop
```

The stage can be moved as a whole. It depends on the host distribution's shared
libraries and Python 3; it is **not an AppImage or universal installer**. An Ubuntu
ARM64 build must not be advertised as a Raspberry Pi OS Bookworm binary: both
use ARM64 but can have incompatible glibc, Qt and codec library versions. Building
directly on the target OS avoids that mismatch. The standard dependency recipe
also works for a native rebuild on the target.

### RAM, storage and compiler settings

Start with one compiler job on Pi 4. The recipe disables precompiled headers and
compiler pipes to lower peak build memory, and uses portable CPU optimization
instead of `-march=native`. A build produced on an ARM server should not inherit
that server's optional instructions.

Allow roughly **10–15 GB of free build space** as a planning estimate, including
dependencies and temporary files. This is not a measured Pi requirement. A Pi
with 4/8 GB RAM is a more practical build candidate than a 1/2 GB model; even a
single compiler job may need swap on a low-memory machine. Compile time and audio
performance have not been measured on Pi. Cooling and stable power matter.
Do not repeatedly increase jobs when `cc1plus` is killed: check the kernel's OOM
log and reduce memory pressure first.

For a smaller build, omit the native test executable with
`RX3_BUILD_TESTING=OFF`. This skips native tests, so report that when sharing a
build. To reclaim space after a successful build, keep `stage/` and the evidence
files, and remove only that build folder's `native/`, `mixxx-2.5.6/` and downloaded
source archive. Leave your profile and music untouched.

## Free remote builds

The manual [Linux workflow](../.github/workflows/linux-native.yml) uses standard
GitHub-hosted `ubuntu-24.04` and `ubuntu-24.04-arm` runners. GitHub documents these
standard runners as free for **public repositories**. No larger/paid runner is
requested. Fork the repository publicly, open **Actions → NauticMixxx Linux →
Run workflow**. The workflow builds both architectures, runs RX3 native tests,
checks packaged identity/profile behavior and starts the GUI under Xvfb/Mesa.

By default, **no build artifacts or caches are uploaded**. Build/test results
remain in the workflow log. This avoids accumulating artifact storage, which has
a separate quota: GitHub Free includes 500 MB shared with Packages; excess
storage can be billed when payment is enabled. Public runner minutes being free
does not make artifact storage unlimited. A completely local build needs no
GitHub Actions allowance at all.

The optional `keep_artifacts` checkbox retains distribution-specific staged
programs, test XML, build metadata and checksums for **one day**. Enable it only
within your account's available storage allowance, or keep it off for this
zero-artifact-storage route. A short retention period alone does not guarantee
zero charges. These packages are test candidates, not verified Pi installers.
A virtual Mesa render does not validate the Pi GPU or low-latency USB audio.
Private forks have different GitHub billing limits; this remote build plan
assumes a public repository.

Results: [Linux workflow runs](https://github.com/nauticsoftware/NauticMixxx/actions/workflows/linux-native.yml).

For Raspberry Pi OS **Bookworm**, the separate **NauticMixxx Debian ARM64**
[workflow](../.github/workflows/raspberry-pi-build.yml) builds natively in a Debian
12 ARM64 container on the same free standard ARM runner. This avoids building
against Ubuntu's newer userland. It is a more appropriate starting point for
Bookworm, but the package still needs a real Pi test with its installed libraries,
GPU and audio device. It is not a Raspberry Pi disk image and is not certified
for Trixie. The same no-artifact default and optional one-day retention apply.

## First hardware test on Pi 4

1. Use the normal desktop session and verify hardware-accelerated Mesa/OpenGL.
   `glxinfo -B` from `mesa-utils` can help diagnose the driver. Software rendering
   may start the app but is not evidence of adequate DJ performance.
   Mesa documents the Pi 4's V3D driver, but desktop OpenGL and OpenGL ES are
   different APIs. The Qt build and desktop session must provide the context
   used by this app; GLES support alone does not establish RX3 compatibility.
2. Start at a moderate display resolution and lower waveform refresh rate if
   necessary. The RX3 skin uses shader waveforms; do not assume a Pi can sustain
   the default 60 fps. Record the actual resolution, frame rate and CPU load.
3. Select your USB audio interface in Preferences and test master plus headphones.
   As a starting point, try 44.1/48 kHz and a 512/1024-frame buffer, then adjust
   against measured dropouts and jog latency. These are test settings, not an
   established Pi performance preset. Key lock and effects add CPU load.
4. Connect a Rekordbox-exported USB. Linux discovery checks `/media`,
   `/media/$USER` and `/run/media/$USER`; use manual source authorization for an
   unusual mount location. Ensure the current user can read the mount. Newer
   Rekordbox Device Library Plus compatibility is not implied; use the supported
   exported catalog format.
5. Test the controller's MIDI/HID ports, browser exit, load protection, jog rim and
   top touch using the [v1.5 controller guide](CONTROLLERS-RX3-1.5-EN.md).
   OS-level USB audio support and mapping support are separate questions.

If a HID controller is denied access, the staged upstream udev rules are under
`stage/share/mixxx/udev/rules.d/mixxx-usb-uaccess.rules`. Inspect the rule for your
model, then install it with administrator privileges if needed; reload udev and
reconnect the device. Do not run the DJ app as root to bypass permissions.

Linux uses its own audio decoders. The v1.4 CoreAudio-specific MP3 correction and
macOS timing measurements cannot certify Linux timing. Check WAV and MP3 cues,
beatgrids and loops on the target system before using it in a performance.

## Report a failure

Include the first compiler/configure error and the last ~100 lines of
`linux-build.log`, plus:

```sh
cat /etc/os-release
uname -m
getconf LONG_BIT
dpkg --print-architecture
free -h
df -h .
cmake --version
c++ --version
```

State the Pi model/RAM, controller, audio device and desktop session. Redact any
personal paths or secrets before publishing logs. A missing `CMakeLists.txt`
usually means the build was attempted in the overlay repository root; a Qt package
error suggests missing development packages or an old OS; `Killed cc1plus` often
indicates insufficient memory. `GLIBC_* not found` usually means a binary built
on a different distribution; rebuild on the target. These are diagnostic leads,
not a conclusion without the log.

## Suggested reply to the Reddit user

> Yes, Linux is possible. I've added a free native Linux build guide and scripts
> to the repo, including a 64-bit Raspberry Pi OS route. The repo contains patches
> on top of Mixxx, so compiling its root directly won't work; the new script
> downloads Mixxx 2.5.6 and applies the changes. Pi 4 performance is still
> experimental and needs a real hardware test. Could you share your OS version,
> whether it's 32/64-bit, your Pi's RAM, and the first build error?

Guide: https://github.com/nauticsoftware/NauticMixxx/blob/main/docs/LINUX-RASPBERRY-PI.md

## Primary references

- [Mixxx: compiling on Linux](https://github.com/mixxxdj/mixxx/wiki/Compiling-On-Linux)
- [Mixxx 2.5.6 dependency recipe](https://github.com/mixxxdj/mixxx/blob/2.5.6/tools/debian_buildenv.sh)
- [Mixxx hardware compatibility](https://github.com/mixxxdj/mixxx/wiki/Hardware-Compatibility)
- [Mixxx shader waveform architecture](https://mixxx.org/news/2024-02-23-improved-waveforms/)
- [Mesa V3D driver](https://docs.mesa3d.org/drivers/v3d.html)
- [Raspberry Pi OS documentation](https://www.raspberrypi.com/documentation/computers/os.html)
- [GitHub standard runners and public repository pricing](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [GitHub Actions artifact storage quotas and billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
