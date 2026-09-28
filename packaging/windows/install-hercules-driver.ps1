param([switch]$NonInteractive)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0
try {
    if ($env:OS -ne "Windows_NT" -or -not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") {
        throw 'The driver requires Windows 10/11 x64 on an Intel or AMD processor.'
    }
    $url = "https://ts.hercules.com/download/pub/webupdate/DJCSeries/2023_HDJS_2.exe"
    $expected = "de65f35ed1e10cb7a201a558da94599ea95be2b4491714232bc1d8a1cda884a5"
    $directory = Join-Path ([IO.Path]::GetTempPath()) "RX3-Hercules-Driver"
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $installer = Join-Path $directory "2023_HDJS_2.exe"
    Write-Host 'Official Hercules HDJCSeries 2023.HDJS.2 driver (Windows 10/11).'
    Write-Host 'If it is already installed, you do not need to repeat this step.'
    Write-Host 'Close DJ software and follow the Hercules setup instructions for USB connection.'
    if (-not $NonInteractive) {
        [void](Read-Host 'Press ENTER to download and open the official setup (Ctrl+C to quit)')
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (-not (Test-Path -LiteralPath $installer) -or (Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash -ne $expected) {
        Write-Host "Downloading from $url (about 58 MB)..."
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $installer
    }
    if ((Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash -ne $expected) { throw 'The download does not match the verified SHA-256 hash.' }
    if ((Get-AuthenticodeSignature -LiteralPath $installer).Status -ne "Valid") { throw 'The driver signature is invalid. Setup will not run.' }
    $process = Start-Process -FilePath $installer -Verb RunAs -Wait -PassThru
    if ($process.ExitCode -notin @(0, 3010, 1641)) { throw "Hercules setup exited with code $($process.ExitCode)." }
    Write-Host 'Setup finished. If Hercules requests a restart, restart before using NauticMixxx.'
    exit 0
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Official support: https://support.hercules.com/en/product/djcontrolinpulse500-en/'
    exit 1
}
