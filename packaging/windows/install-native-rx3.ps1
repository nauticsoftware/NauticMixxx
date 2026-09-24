param([switch]$NoLaunch)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'windows\rx3-install-common.ps1')

try {
    if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitOperatingSystem -or
        $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        throw 'Requiere Windows 10/11 x64 Intel/AMD.'
    }
    if ([Environment]::OSVersion.Version.Build -lt 17763) { throw 'Requiere Windows 10 1809 o posterior.' }
    Test-Rx3Payload -PackageRoot $PSScriptRoot
    $runtime = Join-Path $PSScriptRoot 'runtime'
    $buildInfo = Get-Content (Join-Path $runtime 'rx3-build.json') -Raw | ConvertFrom-Json
    if ($buildInfo.version -ne '1.0.0' -or $buildInfo.product -ne 'NauticMixxx' -or $buildInfo.platform -ne 'windows-x64' -or -not $buildInfo.testsPassed) {
        throw 'El paquete no contiene una compilacion NauticMixxx 1.0.0 validada.'
    }
    if ((Get-FileHash (Join-Path $runtime 'mixxx.exe') -Algorithm SHA256).Hash -ne $buildInfo.executableSha256) {
        throw 'El ejecutable no corresponde a la compilacion validada.'
    }
    $logPath = Join-Path $env:TEMP ('RX3-native-install-' + (Get-Date -Format 'yyyyMMdd-HHmmssfff') + '.log')
    Start-Transcript -LiteralPath $logPath | Out-Null
    Write-Step 'NauticMixxx 1.0.0 para Windows x64'
    Stop-RunningMixxx
    $settings = Join-Path $env:LOCALAPPDATA 'Mixxx-RX3'
    $officialSettings = Join-Path $env:LOCALAPPDATA 'Mixxx'
    $backup = $null
    if (Test-Path -LiteralPath $settings) {
        $backup = Backup-MixxxSettings -SettingsPath $settings
    } elseif (Test-Path -LiteralPath $officialSettings) {
        # First migration copies the existing Windows library/audio into the RX3
        # profile. Official Mixxx keeps its own original files and executable.
        $config = Join-Path $officialSettings 'mixxx.cfg'
        if (Test-Path $config) {
            $text = Get-Content -LiteralPath $config -Raw
            if ($text -match '(?m)^Version\s+(\d+\.\d+\.\d+)') {
                if ([version]$Matches[1] -gt [version]'2.5.6') {
                    throw 'El perfil oficial es posterior a Mixxx 2.5.6. No se migrara hacia una version anterior.'
                }
            }
        }
        $backup = Backup-MixxxSettings -SettingsPath $officialSettings
        New-Item -ItemType Directory -Path $settings | Out-Null
        Get-ChildItem -LiteralPath $officialSettings -Force | Copy-Item -Destination $settings -Recurse -Force
        Write-Step 'Biblioteca y audio de Windows copiados al perfil RX3 independiente'
    }
    New-Item -ItemType Directory -Path $settings -Force | Out-Null
    # A unique application directory keeps every previous installation usable.
    $installRoot = Join-Path $env:LOCALAPPDATA ('Programs\NauticMixxx\1.0.0-' + (Get-Date -Format 'yyyyMMdd-HHmmssfff'))
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $runtime -Force | Copy-Item -Destination $installRoot -Recurse -Force
    $exe = Join-Path $installRoot 'mixxx.exe'
    if ((Get-FileHash $exe -Algorithm SHA256).Hash -ne $buildInfo.executableSha256) { throw 'Fallo al copiar el ejecutable.' }
    $mixxxConfig = Join-Path $settings 'mixxx.cfg'
    $effectsConfig = Join-Path $settings 'effects.xml'
    if (-not (Test-Path $mixxxConfig) -or -not (Test-Path $effectsConfig)) {
        if ($NoLaunch) { throw 'Es necesario abrir NauticMixxx una vez para inicializar el perfil.' }
        Write-Host 'NauticMixxx se abrira para crear el perfil. Cuando termine de abrir, cierralo.'
        Start-Rx3Mixxx -Executable $exe -SettingsPath $settings
        [void](Read-Host 'Pulsa ENTER despues de cerrar Mixxx RX3')
        Stop-RunningMixxx
        if (-not (Test-Path $mixxxConfig) -or -not (Test-Path $effectsConfig)) { throw 'No se pudo inicializar el perfil.' }
    }
    if (-not $backup) { $backup = Backup-MixxxSettings -SettingsPath $settings }
    $skinRoot = Join-Path $settings 'skins'
    $skinTarget = Join-Path $skinRoot 'XDJ_RX3_Mixxx'
    New-Item -ItemType Directory -Path $skinRoot -Force | Out-Null
    if (Test-Path $skinTarget) { Remove-Item -LiteralPath $skinTarget -Recurse -Force }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'skins\XDJ_RX3_Mixxx') -Destination $skinRoot -Recurse
    $controllers = Join-Path $settings 'controllers'
    $chains = Join-Path $settings 'effects\chains'
    New-Item -ItemType Directory -Path $controllers, $chains -Force | Out-Null
    Get-ChildItem (Join-Path $PSScriptRoot 'controllers\Hercules_DJControl_Inpulse_500_RX3') -File |
        Copy-Item -Destination $controllers -Force
    Get-ChildItem (Join-Path $PSScriptRoot 'effects\chains') -File | Copy-Item -Destination $chains -Force
    foreach ($legacyEffect in @('RX3 SPACE.xml', 'RX3 DUB ECHO.xml')) {
        $legacyPath = Join-Path $chains $legacyEffect
        if (Test-Path -LiteralPath $legacyPath -PathType Leaf) { Remove-Item -LiteralPath $legacyPath -Force }
    }
    Set-Rx3QuickEffectOrder -EffectsConfig $effectsConfig
    $midiNames = @(Get-WindowsMidiInputs)
    $keys = @(Get-Rx3ControllerKeys -DeviceNames $midiNames)
    Apply-MixxxProfile -ConfigPath $mixxxConfig -ProfilePath (Join-Path $PSScriptRoot 'profile\XDJ_RX3_Mixxx.profile.cfg') `
        -ControllerPresetPath (Join-Path $controllers 'Hercules_DJControl_Inpulse_500_RX3.midi.xml') `
        -ControllerKeys $keys -InterfaceScale 1
    $shell = New-Object -ComObject WScript.Shell
    foreach ($directory in @([Environment]::GetFolderPath('DesktopDirectory'), [Environment]::GetFolderPath('Programs'))) {
        $shortcut = $shell.CreateShortcut((Join-Path $directory 'NauticMixxx.lnk'))
        $shortcut.TargetPath = $exe
        $shortcut.Arguments = '--settings-path "' + $settings + '"'
        $shortcut.WorkingDirectory = $installRoot
        $shortcut.IconLocation = $exe + ',0'
        $shortcut.Description = 'NauticMixxx 1.0.0 - Hercules Inpulse 500'
        $shortcut.Save()
    }
    Write-Host 'Instalacion completada. Usa el acceso directo NauticMixxx.' -ForegroundColor Green
    Write-Host "Perfil: $settings"
    Write-Host "Respaldo: $backup"
    Write-Host 'En cada laptop: ASIO Hercules, Principal 1-2, Auriculares 3-4.'
    if (@($midiNames | Where-Object { $_ -match '(?i)DJControl[ _-]*Inpulse[ _-]*500' }).Count -eq 0) {
        Write-Warning 'Conecta el Inpulse 500 y selecciona el mapping RX3 en Preferencias > Controladores, o repite este instalador.'
    }
    Write-Host "Registro: $logPath"
    if (-not $NoLaunch) { Start-Rx3Mixxx -Executable $exe -SettingsPath $settings }
    Stop-Transcript | Out-Null
    exit 0
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'No se completo la instalacion. Conserva el registro y el respaldo para recuperar el perfil.'
    try { Stop-Transcript | Out-Null } catch {}
    exit 1
}
