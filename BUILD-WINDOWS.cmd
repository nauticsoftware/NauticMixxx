@echo off
setlocal
cd /d "%~dp0"
echo Compilacion nativa NauticMixxx 1.0.0 - Windows x64
echo Este paso genera el ZIP instalable. Requiere herramientas C++, Git y Python.
echo Consulta EMPEZAR-COMPILACION.txt antes de empezar.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build-mixxx-rx3-windows.ps1"
set "RX3_EXIT=%ERRORLEVEL%"
pause
exit /b %RX3_EXIT%
