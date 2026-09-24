@echo off
setlocal
cd /d "%~dp0"

echo ============================================================
echo       XDJ-RX3 para Mixxx - Instalador de Windows
echo ============================================================
echo.
echo Si Mixxx no esta instalado, se descargara la version oficial 2.5.6.
echo Skin RX3 + tu mapping Hercules Inpulse 500 + Sound Color FX.
echo Windows 10/11 de 64 bits. Extrae todo el ZIP antes de empezar.
echo Si falta el driver ASIO, ejecuta primero DRIVER-HERCULES.cmd.
echo.

where powershell.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: Windows PowerShell no esta disponible.
    echo Instala o habilita Windows PowerShell y vuelve a intentarlo.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-mixxx-rx3-windows.ps1"
set "RX3_EXIT=%ERRORLEVEL%"

echo.
if not "%RX3_EXIT%"=="0" (
    echo La instalacion no pudo completarse. Revisa el mensaje anterior.
) else (
    echo Instalacion finalizada correctamente.
)
echo.
pause
exit /b %RX3_EXIT%
