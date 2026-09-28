NAUTICMIXXX SKIN 1.1.0 FOR WINDOWS X64
Windows 10 version 1809 or later / Windows 11, Intel or AMD 64-bit

QUICK START
1. Extract the entire ZIP. Do not run files inside the ZIP viewer.
2. Double-click INSTALL-WINDOWS.bat in the extracted folder.
3. Keep the NauticMixxx-Files folder next to the BAT files.
4. Setup verifies every included file and shows progress.
5. If NauticMixxx 1.0 is installed, setup detects it and updates its existing
   skin folder and profile in place. It does not download Mixxx again.
6. If neither NauticMixxx nor Mixxx is installed, setup downloads official
   Mixxx 2.5.6 and verifies its SHA-256 and digital signature first.
7. For an existing standard Mixxx installation, choose P for a separate
   NauticMixxx profile (recommended), R to update the standard profile, or C.
8. Use the single NauticMixxx shortcut on the Desktop or Start menu.

The ZIP includes the skin, Inpulse 500 mapping, RX3 effect chains, profile
settings and the installer. It does not include mixxx.exe. An internet
connection is needed only if Mixxx must be downloaded or you choose to install
the optional Hercules ASIO driver.

DDJ-FLX6 MENU CONTROLS
An optional browser-only DDJ-FLX6 preset is installed but not selected.
VIEW toggles BROWSE; turn BROWSE to move; press BROWSE to enter; BACK returns;
LOAD 1/2 loads the selected track. SHIFT + VIEW opens SOURCE only in the native
NauticMixxx build. See DDJ-FLX6-EN.md in NauticMixxx-Files before selecting
the preset: it does not map PLAY/CUE, jog wheels, mixer or effects.

EXISTING SKIN VERSIONS
Setup detects the skin in both the standard and separate profiles. In the
profile you select, version 1.0.0 and later are backed up and updated to 1.1.0.
Setup refuses to overwrite a newer version with 1.1.0. Backups are kept in:
%LOCALAPPDATA%\NauticMixxx-Backups
When NauticMixxx 1.0 is present, setup also replaces its bundled skin in the
same application folder after creating a backup. The existing executable is
preserved because this is the skin-only edition.

PARALLEL OR STANDARD PROFILE
P uses %LOCALAPPDATA%\Mixxx-RX3 and keeps the standard Mixxx profile separate.
If a compatible standard profile already exists, its library and settings are
copied into the new profile before the skin is installed.
R uses %LOCALAPPDATA%\Mixxx and replaces only the previous RX3 skin, mapping,
effect chains and selected skin settings. The Mixxx application itself is not
replaced. Existing settings and skin files are backed up first.
The shortcut always uses the NauticMixxx name and icon. Obsolete Desktop
shortcuts named Mixxx or NauticMixxx Skin are moved to the backup folder.

Audio device and channel selection remain your responsibility in Mixxx
Preferences > Sound Hardware. For Hercules Inpulse 500, select the RX3 mapping
in Preferences > Controllers if the controller was not connected during setup.
Check PLAY/CUE, jog wheels, loop, pitch and cue monitoring before a live set.

COMPLETE NAUTICMIXXX REMOVAL
1. Close NauticMixxx and Mixxx.
2. Double-click UNINSTALL-WINDOWS.bat in this extracted folder.
3. Review the list of detected components and type UNINSTALL to proceed.
The uninstaller finds all versions under the NauticMixxx application folders,
the separate Mixxx-RX3 profile, NauticMixxx shortcuts, backups, logs and
download caches. It removes RX3 files and references from a shared Mixxx
profile without deleting that profile or its music library. The separate
profile and backups may contain library data and are deleted in full.
Music files outside these folders, official Mixxx and the separately installed
Hercules hardware driver remain installed. An administrator prompt may appear
for a NauticMixxx application under Program Files.
If an older native package replaced the executable inside an official Mixxx
application folder, restore the original application backup first. The
uninstaller stops in that case to avoid deleting the only restore copy.

COMPATIBILITY
This is the skin-only edition for official Mixxx. It does not include the
custom NauticMixxx audio engine or native patches. Native-only features such
as USB-only source browsing, the exact two-pixel playhead width and automatic
full-window reference fill require a separately built NauticMixxx application.
The red playhead color and visual layout are supplied by the skin where
supported by the installed Mixxx version.

Official Mixxx download: https://mixxx.org/download/
Official Hercules support: https://support.hercules.com/en/product/djcontrolinpulse500-en/
