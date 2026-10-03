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

    if (-not $Installed) { return 'unknown version' }
    if ($Installed -lt $Latest) { return 'older than the latest stable release' }
    if ($Installed -gt $Latest) { return 'newer than the latest stable release' }
    return 'latest stable release'
}

function Select-ReplacementInstallation {
    param([object[]]$Installations, [string]$RequestedPath)

    if ($RequestedPath) {
        $fullRequested = [IO.Path]::GetFullPath($RequestedPath)
        $match = @($Installations | Where-Object {
            $_.Path -eq $fullRequested -or $_.InstallRoot -eq $fullRequested
        } | Select-Object -First 1)
        if ($match.Count -eq 0) {
            throw "The selected path is not a detected Mixxx installation: $RequestedPath"
        }
        return $match[0]
    }

    if ($Installations.Count -eq 0) {
        throw 'There is no existing Mixxx installation to replace. Choose a parallel installation.'
    }
    if ($Installations.Count -eq 1) { return $Installations[0] }

    Write-Host ''
    Write-Host 'Choose the installation to replace:' -ForegroundColor Yellow
    for ($index = 0; $index -lt $Installations.Count; $index++) {
        Write-Host ("  {0}. Mixxx {1} - {2}" -f ($index + 1), $Installations[$index].VersionText, $Installations[$index].InstallRoot)
    }
    $selectionText = Read-Host 'Number (or C to cancel)'
    if ($selectionText -match '(?i)^c$') { throw 'Installation cancelled by the user.' }
    $selection = 0
    if (-not [int]::TryParse($selectionText, [ref]$selection) -or $selection -lt 1 -or $selection -gt $Installations.Count) {
        throw 'Invalid selection.'
    }
    return $Installations[$selection - 1]
}

try {
    if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitOperatingSystem -or
        $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        throw 'Windows 10/11 x64 on an Intel or AMD processor is required.'
    }
    if ([Environment]::OSVersion.Version.Build -lt 17763) { throw 'Windows 10 version 1809 or later is required.' }

    $logPath = Join-Path $env:TEMP ('NauticMixxx-install-' + (Get-Date -Format 'yyyyMMdd-HHmmssfff') + '.log')
    Start-Transcript -LiteralPath $logPath | Out-Null
    Write-Step 'Checking package files and SHA-256 hashes...'
    Test-Rx3Payload -PackageRoot $PSScriptRoot
    $runtime = Join-Path $PSScriptRoot 'runtime'
    $buildInfo = Get-Content (Join-Path $runtime 'rx3-build.json') -Raw | ConvertFrom-Json
    $manifest = Get-Content (Join-Path $PSScriptRoot 'payload-sha256.json') -Raw | ConvertFrom-Json
    if ($buildInfo.version -ne $manifest.version -or $buildInfo.product -ne 'NauticMixxx' -or
        $buildInfo.platform -ne 'windows-x64' -or -not $buildInfo.testsPassed -or
        $buildInfo.baseMixxxVersion -ne '2.5.6' -or $manifest.version -ne '1.2.0' -or
        $buildInfo.patches -ne $manifest.patches) {
        throw 'This package does not contain a validated NauticMixxx 1.2.0 build based on Mixxx 2.5.6.'
    }
    if ((Get-FileHash (Join-Path $runtime 'mixxx.exe') -Algorithm SHA256).Hash -ne $buildInfo.executableSha256) {
        throw 'The executable does not match the validated build.'
    }

    Write-Step "NauticMixxx $($buildInfo.version) for Windows x64"

    $baseVersion = [version]$buildInfo.baseMixxxVersion
    if (-not $SkipOnlineVersionCheck) { Write-Step 'Checking the latest stable Mixxx version (up to 8 seconds)...' }
    $latestStable = if ($SkipOnlineVersionCheck) { $baseVersion } else { Get-LatestStableMixxxVersion -Fallback $baseVersion }
    Write-Host "Bundled native base: Mixxx $baseVersion"
    Write-Host "Latest stable version detected: Mixxx $latestStable"
    if ($latestStable -gt $baseVersion) {
        Write-Warning "This package was validated with Mixxx $baseVersion, not $latestStable. Parallel installation is recommended."
    }

    Write-Step 'Detecting existing Mixxx installations...'
    $installations = @(Get-MixxxInstallations)
    if ($installations.Count -eq 0) {
        Write-Host 'No other Mixxx installation was found.'
    }
    else {
        Write-Host ''
        Write-Host 'Detected installations:' -ForegroundColor Cyan
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
            Write-Host '[P] Parallel installation (recommended): keep Mixxx and use a separate profile.'
            Write-Host '[R] Replace a detected installation: create complete backups first.'
            Write-Host '[C] Cancel.'
            $modeAnswer = (Read-Host 'Choose P, R or C [P]').Trim()
            if (-not $modeAnswer -or $modeAnswer -match '(?i)^p$') { $resolvedMode = 'Parallel' }
            elseif ($modeAnswer -match '(?i)^r$') { $resolvedMode = 'Replace' }
            elseif ($modeAnswer -match '(?i)^c$') { throw 'Installation cancelled by the user.' }
            else { throw 'Invalid option.' }
        }
    }

    $replacement = $null
    if ($resolvedMode -eq 'Replace') {
        $replacement = Select-ReplacementInstallation -Installations $installations -RequestedPath $TargetPath
        if ($replacement.Version -and $replacement.Version -gt $baseVersion) {
            throw "Mixxx $($replacement.VersionText) cannot be replaced with the older base $baseVersion. Run setup again and choose parallel installation."
        }
        if (-not $ConfirmedReplace) {
            Write-Host ''
            Write-Warning "This installation will be replaced: $($replacement.InstallRoot)"
            Write-Host 'The complete application and user profile will be backed up first.'
            if ((Read-Host 'Type REPLACE to continue') -cne 'REPLACE') {
                throw 'Replacement was not confirmed. The installation was not modified.'
            }
            $ConfirmedReplace = $true
        }

        $replacementRoot = Assert-SafeInstallRoot -InstallRoot $replacement.InstallRoot
        if (-not (Test-DirectoryWritable -Directory $replacementRoot) -and -not (Test-Administrator)) {
            Write-Step 'Windows will request administrator permission to replace that installation'
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
                Write-Warning "The official profile belongs to Mixxx $($Matches[1]), newer than $baseVersion. A clean NauticMixxx profile will be created."
            }
        }
        $profileBackup = Backup-MixxxSettings -SettingsPath $officialSettings
        if ($canMigrate) {
            New-Item -ItemType Directory -Path $settings -Force | Out-Null
            Get-ChildItem -LiteralPath $officialSettings -Force | Copy-Item -Destination $settings -Recurse -Force
            Write-Step 'Library and settings copied to the separate NauticMixxx profile'
        }
    }
    New-Item -ItemType Directory -Path $settings -Force | Out-Null

    $applicationBackup = $null
    if ($resolvedMode -eq 'Replace') {
        $installRoot = Assert-SafeInstallRoot -InstallRoot $replacement.InstallRoot
        $applicationBackup = Backup-MixxxApplication -InstallRoot $installRoot -VersionText $replacement.VersionText
    }
    else {
        $installRoot = Assert-SafeInstallRoot -InstallRoot (Join-Path $env:LOCALAPPDATA ("Programs\NauticMixxx\" + $buildInfo.version))
        if (Test-Path -LiteralPath $installRoot) {
            if (-not (Test-Path -LiteralPath (Join-Path $installRoot 'mixxx.exe') -PathType Leaf)) {
                throw "An incomplete installation exists in $installRoot. Rename it and run setup again."
            }
            $applicationBackup = Backup-MixxxApplication -InstallRoot $installRoot -VersionText ("NauticMixxx-" + $buildInfo.version)
        }
    }

    if (Test-Path -LiteralPath $installRoot) { Remove-Item -LiteralPath $installRoot -Recurse -Force }
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    Get-ChildItem -LiteralPath $runtime -Force | Copy-Item -Destination $installRoot -Recurse -Force
    $exe = Join-Path $installRoot 'mixxx.exe'
    if ((Get-FileHash $exe -Algorithm SHA256).Hash -ne $buildInfo.executableSha256) {
        throw 'Executable verification failed after copying.'
    }

    $mixxxConfig = Join-Path $settings 'mixxx.cfg'
    $effectsConfig = Join-Path $settings 'effects.xml'
    if (-not (Test-Path $mixxxConfig) -or -not (Test-Path $effectsConfig)) {
        if ($NoLaunch) { throw 'NauticMixxx must be opened once to initialize the profile.' }
        Write-Host 'NauticMixxx will open to create its profile. Close it after startup finishes.'
        Start-Rx3Mixxx -Executable $exe -SettingsPath $settings
        [void](Read-Host 'Press ENTER after closing NauticMixxx')
        Stop-RunningMixxx
        if (-not (Test-Path $mixxxConfig) -or -not (Test-Path $effectsConfig)) {
            throw 'The profile could not be initialized.'
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
    Get-ChildItem (Join-Path $PSScriptRoot 'controllers\Pioneer_DDJ_FLX4_RX3') -File |
        Copy-Item -Destination $controllers -Force
    Get-ChildItem (Join-Path $PSScriptRoot 'controllers\Pioneer_DDJ_FLX6_RX3') -File |
        Copy-Item -Destination $controllers -Force
    Get-ChildItem (Join-Path $PSScriptRoot 'controllers\Pioneer_Roland_RX3') -File |
        Copy-Item -Destination $controllers -Force
    foreach ($legacyMapping in @('Hercules_DJControl_Inpulse_500.midi.xml', 'Hercules-DJControl-Inpulse-500-script.js')) {
        $legacyPath = Join-Path $controllers $legacyMapping
        if (Test-Path -LiteralPath $legacyPath -PathType Leaf) {
            Move-Item -LiteralPath $legacyPath -Destination ($legacyPath + '.previous') -Force
        }
    }
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
        $shortcut.Description = "NauticMixxx $($buildInfo.version) - Hercules Inpulse 500"
        $shortcut.Save()
    }

    if (-not (Test-HerculesAsioDriver) -and -not $NoLaunch) {
        Write-Host ''
        Write-Host 'Optional: the Hercules ASIO driver was not detected.' -ForegroundColor Yellow
        Write-Host 'It is not needed if you use a different controller or audio device.'
        $driverAnswer = (Read-Host 'Download and install the official Hercules driver now? [y/N]').Trim()
        if ($driverAnswer -match '(?i)^y$') {
            & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File `
                (Join-Path $PSScriptRoot 'windows\install-hercules-driver.ps1') -NonInteractive
            if ($LASTEXITCODE -ne 0) { Write-Warning 'The Hercules driver setup did not complete; NauticMixxx was installed.' }
        }
    }

    Write-Host ''
    Write-Host 'Installation complete. Use the NauticMixxx shortcut.' -ForegroundColor Green
    Write-Host "Mode: $resolvedMode"
    Write-Host "Application: $installRoot"
    Write-Host "Separate profile: $settings"
    if ($applicationBackup) { Write-Host "Application backup: $applicationBackup" }
    if ($profileBackup) { Write-Host "Profile backup: $profileBackup" }
    Write-Host 'Audio: configure the device and channels for your hardware.'
    if (@($midiNames | Where-Object { $_ -match '(?i)DJControl[ _-]*Inpulse[ _-]*500' }).Count -eq 0) {
        Write-Warning 'Connect the Inpulse 500 and select the RX3 mapping in Preferences > Controllers, or run this installer again.'
    }
    Write-Host "Log: $logPath"
    if (-not $NoLaunch) { Start-Rx3Mixxx -Executable $exe -SettingsPath $settings }
    Stop-Transcript | Out-Null
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Installation did not complete. Any backups already created were preserved.'
    try { Stop-Transcript | Out-Null } catch {}
    exit 1
}
