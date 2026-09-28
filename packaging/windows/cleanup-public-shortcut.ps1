param(
    [Parameter(Mandatory=$true)][string]$ShortcutPath,
    [Parameter(Mandatory=$true)][string]$BackupRoot
)

$ErrorActionPreference = 'Stop'
try {
    $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
    $expected = [IO.Path]::GetFullPath((Join-Path $publicDesktop 'Mixxx.lnk'))
    if ([IO.Path]::GetFullPath($ShortcutPath) -ine $expected) {
        throw 'Only the public Mixxx desktop shortcut may be moved.'
    }
    if (-not (Test-Path -LiteralPath $ShortcutPath -PathType Leaf)) { exit 0 }
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $destination = Join-Path $BackupRoot ((Get-Date -Format 'yyyyMMdd-HHmmssfff') + '-Mixxx.lnk')
    Move-Item -LiteralPath $ShortcutPath -Destination $destination -Force
    Write-Host "Moved the public Mixxx shortcut to $destination"
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
