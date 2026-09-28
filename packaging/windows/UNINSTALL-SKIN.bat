@echo off
setlocal EnableExtensions
set "RX3_FILES=%~dp0NauticMixxx-Files"
set "RX3_UNINSTALLER=%RX3_FILES%\uninstall-nauticmixxx.ps1"
echo NauticMixxx complete removal - Windows
echo.
if not exist "%RX3_UNINSTALLER%" (
    echo ERROR: Keep UNINSTALL-WINDOWS.bat next to the NauticMixxx-Files folder.
    set "RX3_EXIT=1"
    goto :finish
)
if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
    echo ERROR: Windows PowerShell is required.
    set "RX3_EXIT=1"
    goto :finish
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%RX3_UNINSTALLER%"
set "RX3_EXIT=%ERRORLEVEL%"
:finish
echo.
if "%RX3_EXIT%"=="0" (
    echo NauticMixxx removal completed.
) else (
    echo NauticMixxx removal did not complete. Review the message above.
)
echo Press any key to close this window...
pause >nul
exit /b %RX3_EXIT%
