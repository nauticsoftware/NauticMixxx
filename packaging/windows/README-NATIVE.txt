NAUTICMIXXX 1.2.0 FOR WINDOWS X64
Windows 10 version 1809 or later / Windows 11, Intel or AMD 64-bit

QUICK START
1. Extract the entire ZIP. Do not run files from inside the ZIP viewer.
2. Open the extracted NauticMixxx-1.2.0-Windows-x64 folder.
3. Double-click INSTALL-WINDOWS.bat. This is the only file you need to run.
   Keep the NauticMixxx-Files folder next to it.
4. Wait while setup verifies the files. It shows a running file count.
5. If another Mixxx installation is found, choose P for parallel installation
   (recommended), R to replace it after backups, or C to cancel.
6. Use the NauticMixxx desktop or Start menu shortcut.

The package contains the complete native NauticMixxx application, skin,
controller mapping and effects. You do not need an existing Mixxx installation,
a compiler, Git, Python or an internet connection for the main installation.

PARALLEL INSTALLATION
Installs the application to:
%LOCALAPPDATA%\Programs\NauticMixxx\1.2.0
It uses a separate profile at:
%LOCALAPPDATA%\Mixxx-RX3
If an existing Mixxx profile uses base version 2.5.6 or earlier, setup backs
it up and copies its library and settings to the separate profile. A profile
from a newer Mixxx version is not migrated backward.

ADVANCED REPLACEMENT
Choose R only if you want to replace a detected Mixxx installation. Setup
requires the exact word REPLACE. It backs up the complete application and
profile before copying. Windows requests administrator permission only when
the selected installation needs it. A Mixxx version newer than the bundled
base cannot be replaced.
Application backups: %LOCALAPPDATA%\NauticMixxx-Backups\Applications
Profile backups: %LOCALAPPDATA%\Mixxx-XDJ-RX3-Backups

AUDIO AND CONTROLLER
Select the appropriate audio device and channels in Preferences > Sound
Hardware. For Hercules Inpulse 500, ASIO may provide Master 1-2 and
Headphones 3-4. The Hercules driver download is optional and only offered if
the driver is not already installed. For other hardware, use its own setup.
If the controller was disconnected during setup, select the RX3 mapping in
Preferences > Controllers after connecting it, or run setup again.

The ZIP does not include your music, passwords, Mac library or Mac settings.
Import tracks from the Windows laptop or its USB drives. Before using it at
an event, check PLAY/CUE, jog wheels, loop, pitch, MASTER and cue monitoring
on each laptop.

This is a customized community build, not an official Mixxx release. The
NauticMixxx-Files folder contains the tested runtime, test results, SHA-256
manifest, corresponding source code and build recipe.

Mixxx source: https://github.com/mixxxdj/mixxx/tree/2.5.6
Hercules support: https://support.hercules.com/en/product/djcontrolinpulse500-en/
