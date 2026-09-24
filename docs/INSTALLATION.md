# Install NauticMixxx 1.0.0

## macOS Apple Silicon

Requirements: macOS 11 or later and a Mac with Apple Silicon chip.

1. Download `NauticMixxx-1.0.0-macOS-arm64.dmg` and `SHA256SUMS.txt`.

2. Check the file: `shasum -a 256 -c SHA256SUMS.txt`.

3. Open the DMG and drag **NauticMixxx.app** to Applications.

4. The alternative ZIP includes `CONFIGURAR-Y-ABRIR.command`, which installs the profile
RX3 and automatically assign the Inpulse 500 before opening the app.

5. You can also use `install-nauticmixxx-macos.sh`; the installer applies the
Profile and retains at most a previous version.

6. If macOS warns that it is an unnotarised community build, use right-click

→ **Open** in the first execution.

NauticMixxx should not open the music folder selector: the wizard, the
Scan and the registration of directories from the local library are blocked. If
A window appears located in Music, you are running a previous build.
The only folder selection allowed is a macOS authorisation on the
Root of the USB Rekordbox itself when the operating system requires it.
The profile leaves assigned **Hercules DJControl Inpulse 500 - XDJ-RX3 Browse** and
Keeps the mapping in the user folder, so moving or replacing the
`.app` does not break the assignment. It does not modify audio devices or recordings.
The engine retains an internal base for status and history, but does not expose it
As a music source or scan local directories.
The application preserves the Mixxx data identifier to keep the
Access to the profile and sandbox used by the base engine. Before trying a
New version, back up:

`~/Library/Containers/org.mixxx.mixxx/Data/Library/Application Support/NauticMixxx`

The NauticMixxx profile is independent of the existing Mixxx profile. The app opens
The default NauticMixxx interface in a new installation.
NauticMixxx opens the USB Rekordbox in read mode and does not modify its music.
The first selection of the device may cause a request for authorisation
Of macOS; select the root of the USB, never a local Music folder.

## Windows x64

The native version is produced by the **NauticMixxx Windows x64** workflow.
Fully extract the ZIP and run only `INSTALL-WINDOWS.cmd`. The package already
contains the modified application, skin, mapping, effects, corresponding source
and test results; it does not download and patch an official installation.

The installer verifies hashes, detects Mixxx installations and checks the
latest stable version. If Mixxx is present, it offers:

- **Parallel (recommended):** installs to
  `%LOCALAPPDATA%\Programs\NauticMixxx\1.0.0` with the independent
  `%LOCALAPPDATA%\Mixxx-RX3` profile. The official installation remains intact.
- **Advanced replacement:** lets the user select a detected installation,
  requires the exact confirmation `REEMPLAZAR`, backs up the application and
  profile first, and requests administrator rights only when required. It never
  replaces a Mixxx version newer than the included 2.5.6 base.

If the Hercules ASIO driver is not detected, the assistant offers it as a
separate optional download with **No** as the default. Users of other
controllers or audio interfaces do not need it. Application backups are stored
under `%LOCALAPPDATA%\NauticMixxx-Backups\Applications`; profile backups are
stored under `%LOCALAPPDATA%\Mixxx-XDJ-RX3-Backups`.

Do not present a Windows ZIP as stable until the installer validation and native
tests have completed successfully in the workflow.

## Only the skin

`NauticMixxx-1.0.0-skin.zip` is for inspection or for compatible Mixxx. La

Complete experience requires the patched app: the skin alone does not incorporate the
RX3 browser, native scaling or engine corrections.

## Uninstall
