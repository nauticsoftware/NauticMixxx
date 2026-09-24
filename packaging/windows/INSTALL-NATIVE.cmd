@echo off
setlocal
cd /d "%~dp0"
echo NauticMixxx 1.0.0 - Windows 10/11 x64
echo Extrae todo el ZIP antes de continuar.
echo Este es el unico archivo que necesitas ejecutar.
echo El instalador detectara Mixxx y preguntara si deseas conservarlo o reemplazarlo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-mixxx-rx3-windows.ps1"
set "RX3_EXIT=%ERRORLEVEL%"
if not "%RX3_EXIT%"=="0" echo La instalacion no se completo. Revisa el error anterior.
pause
exit /b %RX3_EXIT%
