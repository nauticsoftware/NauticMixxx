@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0packaging\windows\install-hercules-driver.ps1"
set "RX3_EXIT=%ERRORLEVEL%"
pause
exit /b %RX3_EXIT%
