@echo off
setlocal EnableExtensions
set "RX3_ROOT=%~dp0"
set "RX3_FILES=%RX3_ROOT%NauticMixxx-Files"
set "RX3_INSTALLER=%RX3_FILES%\install-skin-rx3.ps1"
echo NauticMixxx skin @VERSION@ - Windows 10/11 x64
echo Keep this BAT file next to the NauticMixxx-Files folder.
echo.
if not exist "%RX3_INSTALLER%" (
    echo ERROR: The NauticMixxx-Files folder is missing or incomplete.
    set "RX3_EXIT=1"
    goto :finish
)
if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
    echo ERROR: Windows PowerShell is required.
    set "RX3_EXIT=1"
    goto :finish
)
echo Starting setup and verifying package files...
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%RX3_INSTALLER%"
set "RX3_EXIT=%ERRORLEVEL%"
:finish
echo.
if "%RX3_EXIT%"=="0" (
    echo NauticMixxx skin setup completed.
) else (
    echo NauticMixxx skin setup did not complete. Review the error above.
)
echo Press any key to close this window...
pause >nul
exit /b %RX3_EXIT%
