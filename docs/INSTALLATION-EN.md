# Install NauticMixxx 1.4.0

## macOS Apple Silicon

Requires macOS 11 or later and an Apple Silicon Mac.

1. Put `NauticMixxx-1.4.0-macOS-arm64.dmg` and `SHA256SUMS.txt` in the same directory. Run `shasum -a 256 NauticMixxx-1.4.0-macOS-arm64.dmg` and compare the result with the DMG entry in `SHA256SUMS.txt`.
2. Open the DMG and drag **NauticMixxx.app** to Applications. The alternative ZIP includes the same app and `CONFIGURE-AND-OPEN.command` to prepare its profile and launch it.
3. On first launch, macOS may ask you to confirm opening this ad hoc signed community build. Right-click the app and choose **Open**.
4. Select your audio output and, if applicable, microphone input under **Preferences → Sound Hardware**.

The native app browses Rekordbox USB media and does not request or scan a local music folder. macOS may ask for access to the USB root. The separate profile is stored under `~/Library/Containers/org.mixxx.mixxx/Data/Library/Application Support/NauticMixxx`; back it up before replacing an older version.

The Inpulse 500 custom RX3 mapping is selected automatically when the device is detected. Connecting another controller while one is already active may require restarting the app. Check audio, CUE, jog wheels and loops before a live set.

SOURCE waits for the USB catalog to finish loading before opening the drive. In PLAYLIST, highlight a playlist to preview its tracks on the right, then press ENTER to open the full track table. First-sound loading uses an existing marker. A USB track without that marker loads at its beginning because NauticMixxx does not analyze audio to create one.

## Windows x64 — version 1.4.0

Download [NauticMixxx-1.4.0-Windows-x64-Setup.exe](https://github.com/nauticsoftware/NauticMixxx/releases/download/v1.4.0/NauticMixxx-1.4.0-Windows-x64-Setup.exe) and run it directly on Windows 10/11 x64. The installer is a native NSIS EXE and includes the complete NauticMixxx application. It does not need an existing Mixxx install or another download.

In 1.4.0, SOURCE waits for the USB catalog to finish loading before opening the drive; highlighting a playlist previews its tracks and ENTER opens the full table.

Setup installs the app under `%LOCALAPPDATA%\Programs\NauticMixxx` and applies the macOS RX3 settings to a separate profile under `%LOCALAPPDATA%\NauticMixxx`. It installs the XDJ RX3 skin, custom Hercules Inpulse 500 mapping, optional FLX6 browser mapping, four Sound Color FX chains, 3-Band waveform default, Rekordbox USB-only browsing, disabled analysis and ReplayGain, Pioneer Cue, ±6% tempo, and the other portable preferences. Existing personal settings are backed up before the managed RX3 preferences are merged. Audio devices, channel routing and music paths depend on the Windows laptop and must be selected there.

The Start menu and desktop shortcuts open `NauticMixxx.exe`. To uninstall, use Windows Settings → Installed apps. The uninstall leaves the user profile in place to avoid losing library data. The EXE is unsigned, so Windows SmartScreen may ask for confirmation on first launch. Physical controller and Rekordbox USB tests should be done on the target laptop before a live set.

## Uninstall on macOS

Remove `NauticMixxx.app`. The profile remains to prevent data loss; delete it only after making a backup if you no longer need it.
