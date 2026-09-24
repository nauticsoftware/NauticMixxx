param(
    [switch]$NoLaunch,
    [ValidateSet('Ask', 'Parallel', 'Replace')]
    [string]$InstallMode = 'Ask',
    [string]$TargetPath = '',
    [switch]$SkipOnlineVersionCheck,
    [switch]$ConfirmedReplace
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'windows\rx3-install-common.ps1')

function Get-VersionStatus {
    param([version]$Installed, [version]$Latest)

    if (-not $Installed) { return 'version desconocida' }
    if ($Installed -lt $Latest) { return 'anterior a la estable actual' }
    if ($Installed -gt $Latest) { return 'posterior a la estable actual' }
    return 'estable actual'
}

function Select-ReplacementInstallation {
    param([object[]]$Installations, [string]$RequestedPath)

    if ($RequestedPath) {
        $fullRequested = [IO.Path]::GetFullPath($RequestedPath)
        $match = @($Installations | Where-Object {
            $_.Path -eq $fullRequested -or $_.InstallRoot -eq $fullRequested
        } | Select-Object -First 1)
        if ($match.Count -eq 0) {
            throw "La ruta elegida no corresponde a una instalacion de Mixxx detectada: $RequestedPath"
        }
        return $match[0]
    }

    if ($Installations.Count -eq 0) {
        throw 'No hay una instalacion existente de Mixxx para reemplazar. Usa la instalacion paralela.'
    }
    if ($Installations.Count -eq 1) { return $Installations[0] }

    Write-Host ''
    Write-Host 'Elige la instalacion que quieres reemplazar:' -ForegroundColor Yellow
    for ($index = 0; $index -lt $Installations.Count; $index++) {
        Write-Host ("  {0}. Mixxx {1} - {2}" -f ($index + 1), $Installations[$index].VersionText, $Installations[$index].InstallRoot)
    }
    $selectionText = Read-Host 'Numero (o C para cancelar)'
    if ($selectionText -match '(?i)^c$') { throw 'Instalacion cancelada por el usuario.' }
    $selection = 0
    if (-not [int]::TryParse($selectionText, [ref]$selection) -or $selection -lt 1 -or $selection -gt $Installations.Count) {
        throw 'Seleccion invalida.'
    }
    return $Installations[$selection - 1]
}

try {
    if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitOperatingSystem -or
        $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        throw 'Requiere Windows 10/11 x64 Intel/AMD.'
    }
    if ([Environment]::OSVersion.Version.Build -lt 17763) { throw 'Requiere Windows 10 1809 o posterior.' }

    Test-Rx3Payload -PackageRoot $PSScriptRoot
    $runtime = Join-Path $PSScriptRoot 'runtime'
    $buildInfo = Get-Content (Join-Path $runtime 'rx3-build.json') -Raw | ConvertFrom-Json
    if ($buildInfo.version -ne '1.0.0' -or $buildInfo.product -ne 'NauticMixxx' -or
        $buildInfo.platform -ne 'windows-x64' -or -not $buildInfo.testsPassed -or
        $buildInfo.baseMixxxVersion -ne '2.5.6') {
        throw 'El paquete no contiene una compilacion NauticMixxx 1.0.0 validada sobre Mixxx 2.5.6.'
    }
    if ((Get-FileHash (Join-Path $runtime 'mixxx.exe') -Algorithm SHA256).Hash -ne $buildInfo.executableSha256) {
        throw 'El ejecutable no corresponde a la compilacion validada.'
    }

    $logPath = Join-Path $env:TEMP ('NauticMixxx-install-' + (Get-Date -Format 'yyyyMMdd-HHmmssfff') + '.log')
    Start-Transcript -LiteralPath $logPath | Out-Null
    Write-Step 'NauticMixxx 1.0.0 para Windows x64'

    $baseVersion = [version]$buildInfo.baseMixxxVersion
    $latestStable = if ($SkipOnlineVersionCheck) { $baseVersion } else { Get-LatestStableMixxxVersion -Fallback $baseVersion }
    Write-Host "Base nativa incluida: Mixxx $baseVersion"
    Write-Host "Ultima version estable detectada: Mixxx $latestStable"
    if ($latestStable -gt $baseVersion) {
        Write-Warning "Este paquete fue validado sobre Mixxx $baseVersion, no sobre $latestStable. Se recomienda instalarlo en paralelo."
    }

    $installations = @(Get-MixxxInstallations)
    if ($installations.Count -eq 0) {
        Write-Host 'No se detecto otra instalacion de Mixxx.'
    }
    else {
        Write-Host ''
        Write-Host 'Instalaciones detectadas:' -ForegroundColor Cyan
        foreach ($installation in $installations) {
            $status = Get-VersionStatus -Installed $installation.Version -Latest $latestStable
            Write-Host "- Mixxx $($installation.VersionText) ($status): $($installation.InstallRoot)"
        }
    }

    $resolvedMode = $InstallMode
    if ($resolvedMode -eq 'Ask') {
        if ($installations.Count -eq 0) {
            $resolvedMode = 'Parallel'
        }
        else {
            Write-Host ''
            Write-Host '[P] Instalar en paralelo (recomendado): conserva Mixxx y usa un perfil independiente.'
            Write-Host '[R] Reemplazar una instalacion detectada: crea respaldos completos antes de copiar.'
            Write-Host '[C] Cancelar.'
            $modeAnswer = (Read-Host 'Elige P, R o C [P]').Trim()
            if (-not $modeAnswer -or $modeAnswer -match '(?i)^p$') { $resolvedMode = 'Parallel' }
            elseif ($modeAnswer -match '(?i)^r$') { $resolvedMode = 'Replace' }
            elseif ($modeAnswer -match '(?i)^c$') { throw 'Instalacion cancelada por el usuario.' }
            else { throw 'Opcion invalida.' }
        }
    }

    $replacement = $null
    if ($resolvedMode -eq 'Replace') {
        $replacement = Select-ReplacementInstallation -Installations $installations -RequestedPath $TargetPath
        if ($replacement.Version -and $replacement.Version -gt $baseVersion) {
            throw "No se reemplazara Mixxx $($replacement.VersionText) con la base $baseVersion. Ejecuta otra vez y elige la instalacion paralela."
        }
        if (-not $ConfirmedReplace) {
            Write-Host ''
            Write-Warning "Se reemplazara: $($replacement.InstallRoot)"
            Write-Host 'Se respaldaran primero la aplicacion completa y el perfil de usuario.'
            if ((Read-Host 'Escribe REEMPLAZAR para continuar') -cne 'REEMPLAZAR') {
                throw 'No se confirmo el reemplazo. No se modifico la instalacion.'
            }
            $ConfirmedReplace = $true
        }

        $replacementRoot = Assert-SafeInstallRoot -InstallRoot $replacement.InstallRoot
        if (-not (Test-DirectoryWritable -Directory $replacementRoot) -and -not (Test-Administrator)) {
            Write-Step 'Windows solicitara permisos de administrador para reemplazar esa instalacion'
            Stop-Transcript | Out-Null
            $arguments = @(
                '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                '-File', ('"' + $PSCommandPath + '"'),
                '-InstallMode', 'Replace',
                '-TargetPath', ('"' + $replacement.Path + '"'),
                '-SkipOnlineVersionCheck', '-ConfirmedReplace'
            )
            if ($NoLaunch) { $arguments += '-NoLaunch' }
            $elevated = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -Wait -PassThru
            exit $elevated.ExitCode
        }
    }

    Stop-RunningMixxx
    $settings = Join-Path $env:LOCALAPPDATA 'Mixxx-RX3'
    $officialSettings = Join-Path $env:LOCALAPPDATA 'Mixxx'
    $profileBackup = $null
    if (Test-Path -LiteralPath $settings) {
        $profileBackup = Backup-MixxxSettings -SettingsPath $settings
    }
    elseif (Test-Path -LiteralPath $officialSettings) {
        $canMigrate = $true
        $config = Join-Path $officialSettings 'mixxx.cfg'
        if (Test-Path -LiteralPath $config -PathType Leaf) {
            $text = Get-Content -LiteralPath $config -Raw
            if ($text -match '(?m)^Version\s+(\d+\.\d+\.\d+)' -and [version]$Matches[1] -gt $baseVersion) {
                $canMigrate = $false
                Write-Warning "El perfil oficial pertenece a Mixxx $($Matches[1]), posterior a $baseVersion. Se creara un perfil NauticMixxx limpio."
            }
        }
        $profileBackup = Backup-MixxxSettings -SettingsPath $officialSettings
        if ($canMigrate) {
            New-Item -ItemType Directory -Path $settings -Force | Out-Null
            Get-ChildItem -LiteralPath $officialSettings -Force | Copy-Item -Destination $settings -Recurse -Force
            Write-Step 'Biblioteca y ajustes de Windows copiados al perfil NauticMixxx independiente'
        }
    }
    New-Item -ItemType Directory -Path $settings -Force | Out-Null

    $applicationBackup = $null
    if ($resolvedMode -eq 'Replace') {
        $installRoot = Assert-SafeInstallRoot -InstallRoot $replacement.InstallRoot
        $applicationBackup = Backup-MixxxApplication -InstallRoot $installRoot -VersionText $replacement.VersionText
    }
    else {
        $installRoot = Assert-SafeInstallRoot -InstallRoot (Join-Path $env:LOCALAPPDATA 'Programs\NauticMixxx\1.0.0')
        if (Test-Path -LiteralPath $installRoot) {
            if (-not (Test-Path -LiteralPath (Join-Path $installRoot 'mixxx.exe') -PathType Leaf)) {
                throw "Hay una instalacion incompleta en $installRoot. Renombrala y repite el instalador."
            }
            $applicationBackup = Backup-MixxxApplication -InstallRoot $installRoot -VersionText 'NauticMixxx-1.0.0'
        }
    }

    if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $runtime -Force | Copy-Item -Destination $installRoot -Recurse -Force
    $exe = Join-Path $installRoot 'mixxx.exe'
    if ((Get-FileHash $exe -Algorithm SHA256).Hash -ne $buildInfo.executableSha256) {
        throw 'Fallo al verificar el ejecutable despues de copiarlo.'
    }

    $mixxxConfig = Join-Path $settings 'mixxx.cfg'
    $effectsConfig = Join-Path $settings 'effects.xml'
    if (-not (Test-Path $mixxxConfig) -or -not (Test-Path $effectsConfig)) {
        if ($NoLaunch) { throw 'Es necesario abrir NauticMixxx una vez para inicializar el perfil.' }
        Write-Host 'NauticMixxx se abrira para crear el perfil. Cuando termine de abrir, cierralo.'
        Start-Rx3Mixxx -Executable $exe -SettingsPath $settings
        [void](Read-Host 'Pulsa ENTER despues de cerrar NauticMixxx')
        Stop-RunningMixxx
        if (-not (Test-Path $mixxxConfig) -or -not (Test-Path $effectsConfig)) {
            throw 'No se pudo inicializar el perfil.'
        }
    }
    if (-not $profileBackup) { $profileBackup = Backup-MixxxSettings -SettingsPath $settings }

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

    if (-not (Test-HerculesAsioDriver) -and -not $NoLaunch) {
        Write-Host ''
        Write-Host 'Opcional: no se detecto el driver ASIO de Hercules.' -ForegroundColor Yellow
        Write-Host 'No es necesario si usas otro controlador o dispositivo de audio.'
        $driverAnswer = (Read-Host 'Quieres descargar e instalar ahora el driver oficial Hercules? [s/N]').Trim()
        if ($driverAnswer -match '(?i)^s$') {
            & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File `
                (Join-Path $PSScriptRoot 'windows\install-hercules-driver.ps1') -NonInteractive
            if ($LASTEXITCODE -ne 0) { Write-Warning 'El driver Hercules no se completo; NauticMixxx si quedo instalado.' }
        }
    }

    Write-Host ''
    Write-Host 'Instalacion completada. Usa el acceso directo NauticMixxx.' -ForegroundColor Green
    Write-Host "Modo: $resolvedMode"
    Write-Host "Aplicacion: $installRoot"
    Write-Host "Perfil independiente: $settings"
    if ($applicationBackup) { Write-Host "Respaldo de aplicacion: $applicationBackup" }
    if ($profileBackup) { Write-Host "Respaldo de perfil: $profileBackup" }
    Write-Host 'Audio: configura el dispositivo y los canales adecuados para tu hardware.'
    if (@($midiNames | Where-Object { $_ -match '(?i)DJControl[ _-]*Inpulse[ _-]*500' }).Count -eq 0) {
        Write-Warning 'Conecta el Inpulse 500 y selecciona el mapping RX3 en Preferencias > Controladores, o repite este instalador.'
    }
    Write-Host "Registro: $logPath"
    if (-not $NoLaunch) { Start-Rx3Mixxx -Executable $exe -SettingsPath $settings }
    Stop-Transcript | Out-Null
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'No se completo la instalacion. Los respaldos ya creados no se eliminan.'
    try { Stop-Transcript | Out-Null } catch {}
    exit 1
}
