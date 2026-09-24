param([switch]$NonInteractive)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0
try {
    if ($env:OS -ne "Windows_NT" -or -not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") {
        throw "El driver requiere Windows 10/11 de 64 bits en Intel/AMD."
    }
    $url = "https://ts.hercules.com/download/pub/webupdate/DJCSeries/2023_HDJS_2.exe"
    $expected = "de65f35ed1e10cb7a201a558da94599ea95be2b4491714232bc1d8a1cda884a5"
    $directory = Join-Path ([IO.Path]::GetTempPath()) "RX3-Hercules-Driver"
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $installer = Join-Path $directory "2023_HDJS_2.exe"
    Write-Host "Driver oficial Hercules HDJCSeries 2023.HDJS.2 (Windows 10/11)."
    Write-Host "Si ya lo tienes instalado, no hace falta repetir este paso."
    Write-Host "Cierra los programas de DJ y sigue las indicaciones de conexion USB del asistente Hercules."
    if (-not $NonInteractive) {
        [void](Read-Host "Pulsa ENTER para descargar y abrir el asistente oficial (Ctrl+C para salir)")
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (-not (Test-Path -LiteralPath $installer) -or (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash -ne $expected) {
        Write-Host "Descargando desde $url (aprox. 58 MB)..."
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $installer
    }
    if ((Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash -ne $expected) { throw "La descarga no coincide con el SHA-256 verificado." }
    if ((Get-AuthenticodeSignature -LiteralPath $installer).Status -ne "Valid") { throw "La firma del driver no es valida. No se ejecutara." }
    $process = Start-Process -FilePath $installer -Verb RunAs -Wait -PassThru
    if ($process.ExitCode -notin @(0, 3010, 1641)) { throw "El asistente Hercules termino con codigo $($process.ExitCode)." }
    Write-Host "Asistente finalizado. Si Hercules solicita reiniciar, hazlo antes de instalar la skin."
    exit 0
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Soporte oficial: https://support.hercules.com/es/product/djcontrolinpulse500-es/"
    exit 1
}
