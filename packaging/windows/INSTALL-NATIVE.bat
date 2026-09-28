@echo off
setlocal EnableExtensions
set "RX3_ROOT=%~dp0"
set "RX3_FILES=%RX3_ROOT%NauticMixxx-Files"
set "RX3_INSTALLER=%RX3_FILES%\install-native-rx3.ps1"
echo NauticMixxx @VERSION@ - Windows 10/11 x64
echo Extract the entire ZIP, then run this file from the extracted folder.
echo.
if not exist "%RX3_INSTALLER%" (
    echo ERROR: The NauticMixxx-Files folder is missing or incomplete.
    echo Keep INSTALL-WINDOWS.bat next to the NauticMixxx-Files folder.
    set "RX3_EXIT=1"
    goto :finish
)
echo Checking package integrity. This can take a few minutes; progress will be shown below.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%RX3_INSTALLER%"
set "RX3_EXIT=%ERRORLEVEL%"
:finish
echo.
if "%RX3_EXIT%"=="0" (
    echo NauticMixxx setup completed.
) else (
    echo NauticMixxx setup did not complete. Review the error above.
)
echo Press any key to close this window...
pause >nul
exit /b %RX3_EXIT%
