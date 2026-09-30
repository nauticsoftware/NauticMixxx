# Install NauticMixxx 1.2.0

## macOS Apple Silicon

Requires macOS 11 or later and an Apple Silicon Mac.

1. Put `NauticMixxx-1.2.0-macOS-arm64.dmg` and `SHA256SUMS.txt` in the same directory. Run `shasum -a 256 NauticMixxx-1.2.0-macOS-arm64.dmg` and compare the result with the DMG entry in `SHA256SUMS.txt`.
2. Open the DMG and drag **NauticMixxx.app** to Applications. The alternative ZIP includes the same app and `CONFIGURE-AND-OPEN.command` to prepare its profile and launch it.
3. On first launch, macOS may ask you to confirm opening this ad hoc signed community build. Right-click the app and choose **Open**.
4. Select your audio output and, if applicable, microphone input under **Preferences → Sound Hardware**.

The native app browses Rekordbox USB media and does not request or scan a local music folder. macOS may ask for access to the USB root. The separate profile is stored under `~/Library/Containers/org.mixxx.mixxx/Data/Library/Application Support/NauticMixxx`; back it up before replacing an older version.

The Inpulse 500 custom RX3 mapping is selected automatically when the device is detected. Connecting another controller while one is already active may require restarting the app. Check audio, CUE, jog wheels and loops before a live set.

First-sound loading uses an existing marker. A USB track without that marker loads at its beginning because NauticMixxx 1.2 does not analyze audio to create one.

## Windows x64

The 1.2.0 source, patches and native Windows build recipe are ready. **The Windows 1.2.0 executable has not yet been built or tested on Windows.** A skin package on official Mixxx cannot enforce the native USB, analysis and fixed-preference behavior.

The `NauticMixxx Windows x64` workflow or `scripts/build-mixxx-rx3-windows.ps1` builds, tests and packages the native edition on a Windows x64 machine with Visual Studio 2022. Distribute that ZIP after a successful build and tests with the physical controller and a Rekordbox USB drive.

## Uninstall on macOS

Remove `NauticMixxx.app`. The profile remains to prevent data loss; delete it only after making a backup if you no longer need it.
