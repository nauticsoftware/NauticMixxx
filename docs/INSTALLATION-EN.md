# Install NauticMixxx 1.1.0

## macOS Apple Silicon

Requires macOS 11 or later and an Apple Silicon Mac. Download `NauticMixxx-1.1.0-macOS-arm64.dmg` and `SHA256SUMS.txt`, then verify the download with `shasum -a 256 -c SHA256SUMS.txt`. Open the DMG, drag `NauticMixxx.app` to Applications, and launch it. On first launch, macOS may ask you to confirm opening this ad-hoc-signed community build; right-click the app and choose **Open**.

The alternative macOS ZIP includes the app and `CONFIGURE-AND-OPEN.command`, which configures the RX3 profile and opens the app. The separate `install-nauticmixxx-macos.sh` verifies the ZIP checksum, backs up one previous app and configures the profile. The installer and profile messages are in English.

The native app browses Rekordbox USB media and does not scan local music folders. macOS may ask for access to the USB root. The profile is stored independently under `~/Library/Containers/org.mixxx.mixxx/Data/Library/Application Support/NauticMixxx`; back it up before replacing an older version. Audio hardware still needs to be selected in **Preferences → Sound Hardware**.

## Windows x64

Extract all of `NauticMixxx-1.1.0-Windows-x64-Skin.zip`. Double-click **INSTALL-WINDOWS.bat** and keep `NauticMixxx-Files` beside it. The installer is in English. It detects NauticMixxx 1.0 and updates the skin in place. If only official Mixxx exists, it offers a separate profile or the standard profile. If neither exists, it downloads verified Mixxx 2.5.6. The Desktop and Start menu shortcut is named NauticMixxx and uses the NauticMixxx icon.

This Windows package contains the 1.1 skin, profile, controller mappings and effects. It does not contain a new `mixxx.exe`, so native RX3 engine features are unavailable when used with official Mixxx. To remove NauticMixxx, close it and run **UNINSTALL-WINDOWS.bat** from the same extracted folder. The uninstaller lists what it found and asks you to type `UNINSTALL`.

## DDJ-FLX6 menu controls

An optional DDJ-FLX6 **browser-only** preset is included on both platforms. VIEW opens or closes BROWSE; turn BROWSE to move; press BROWSE to enter; BACK returns; SHIFT + VIEW opens SOURCE in the native macOS build; LOAD 1/2 loads the selected track. It is not selected automatically and does not map the rest of the controller. See [DDJ-FLX6-EN.md](DDJ-FLX6-EN.md) before selecting it or merging its controls into a full FLX6 mapping.
