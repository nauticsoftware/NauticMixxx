param([switch]$NoLaunch)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
. (Join-Path $PSScriptRoot 'windows\rx3-install-common.ps1')

function Get-InstalledSkinVersion {
    param([string]$SettingsPath)
    $skinXml = Join-Path $SettingsPath 'skins\XDJ_RX3_Mixxx\skin.xml'
    if (-not (Test-Path -LiteralPath $skinXml -PathType Leaf)) { return $null }
    try {
        [xml]$skin = Get-Content -LiteralPath $skinXml -Raw
        return ConvertTo-MixxxVersion -Value ([string]$skin.skin.manifest.version)
    }
    catch {
        Write-Warning "Could not read the installed skin version at $skinXml. It will be backed up before replacement."
        return $null
    }
}

function Backup-SkinSettings {
    param([string]$SettingsPath)
    if (-not (Test-Path -LiteralPath $SettingsPath -PathType Container)) { return $null }
    $items = @(
        'mixxx.cfg', 'effects.xml', 'skins\XDJ_RX3_Mixxx',
        'controllers\Hercules_DJControl_Inpulse_500_RX3.midi.xml',
        'controllers\midi-components-0.0.js',
        'controllers\Hercules-DJControl-Inpulse-500-RX3-script.js',
        'controllers\Pioneer-DDJ-FLX6-RX3-Browser.midi.xml',
        'controllers\Pioneer-DDJ-FLX6-RX3-Browser.js'
    )
    $existing = @($items | Where-Object { Test-Path -LiteralPath (Join-Path $SettingsPath $_) })
    if ($existing.Count -eq 0) { return $null }
    $backup = Join-Path $env:LOCALAPPDATA ('NauticMixxx-Backups\Skin-' + (Get-Date -Format 'yyyyMMdd-HHmmssfff'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Write-Step "Backing up existing skin settings to $backup"
    foreach ($item in $existing) {
        $source = Join-Path $SettingsPath $item
        $target = Join-Path $backup $item
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
    }
    foreach ($effect in @(Get-ChildItem -LiteralPath (Join-Path $SettingsPath 'effects\chains') -Filter 'RX3 *.xml' -File -ErrorAction SilentlyContinue)) {
        $target = Join-Path $backup ('effects\chains\' + $effect.Name)
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath $effect.FullName -Destination $target -Force
    }
    return $backup
}

function Select-MixxxInstallation {
    param([object[]]$Installations)
    $nautic = @($Installations | Where-Object { $_.Kind -eq 'NauticMixxx' } | Sort-Object NauticVersion -Descending)
    if ($nautic.Count -gt 0) {
        Write-Step "Using the existing NauticMixxx installation at $($nautic[0].InstallRoot)"
        return $nautic[0]
    }
    if ($Installations.Count -eq 1) { return $Installations[0] }
    Write-Host 'Choose the Mixxx installation to use:' -ForegroundColor Cyan
    for ($index = 0; $index -lt $Installations.Count; $index++) {
        Write-Host ("  {0}. Mixxx {1} - {2}" -f ($index + 1), $Installations[$index].VersionText, $Installations[$index].Path)
    }
    $answer = Read-Host 'Enter a number'
    $number = 0
    if (-not [int]::TryParse($answer, [ref]$number) -or $number -lt 1 -or $number -gt $Installations.Count) {
        throw 'Invalid Mixxx installation selection.'
    }
    return $Installations[$number - 1]
}

function Move-OldShortcut {
    param([string]$Path, [string]$BackupRoot)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $destination = Join-Path $BackupRoot ((Get-Date -Format 'yyyyMMdd-HHmmssfff') + '-' + [IO.Path]::GetFileName($Path))
    Move-Item -LiteralPath $Path -Destination $destination -Force
    Write-Step "Moved the old desktop shortcut to $destination"
}

try {
    if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitOperatingSystem -or
        $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        throw 'Windows 10/11 x64 on an Intel or AMD processor is required.'
    }
    if ([Environment]::OSVersion.Version.Build -lt 17763) { throw 'Windows 10 version 1809 or later is required.' }

    $logPath = Join-Path $env:TEMP ('NauticMixxx-skin-install-' + (Get-Date -Format 'yyyyMMdd-HHmmssfff') + '.log')
    Start-Transcript -LiteralPath $logPath | Out-Null
    Write-Step 'Verifying the skin package...'
    Test-Rx3Payload -PackageRoot $PSScriptRoot
    $manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'payload-sha256.json') -Raw | ConvertFrom-Json
    if ($manifest.product -ne 'NauticMixxx' -or $manifest.kind -ne 'skin-only' -or $manifest.version -ne '1.2.0') {
        throw 'This is not a valid NauticMixxx 1.2.0 skin package.'
    }
    $newVersion = [version]$manifest.version
    $standardProfile = Join-Path $env:LOCALAPPDATA 'Mixxx'
    $parallelProfile = Join-Path $env:LOCALAPPDATA 'Mixxx-RX3'
    foreach ($candidate in @($standardProfile, $parallelProfile)) {
        $installedVersion = Get-InstalledSkinVersion -SettingsPath $candidate
        if ($installedVersion) { Write-Host "Existing skin $installedVersion found at $candidate" }
    }

    Write-Step 'Detecting Mixxx...'
    $installations = @(Get-MixxxInstallations)
    if ($installations.Count -eq 0) {
        Write-Host 'Mixxx is not installed. Downloading and installing official Mixxx 2.5.6.'
        $mixxxPath = Install-OfficialMixxx
        $installations = @(Get-MixxxInstallations)
        if ($installations.Count -eq 0) { throw 'Official Mixxx installation finished, but mixxx.exe was not detected.' }
    }
    $installation = Select-MixxxInstallation -Installations $installations
    Write-Host "Using $($installation.Kind) $($installation.VersionText): $($installation.Path)"
    if ($installation.Version -and $installation.Version -ne [version]'2.5.6') {
        Write-Warning 'The skin was developed against Mixxx 2.5.6. Check it carefully with this Mixxx version.'
    }

    if ($installation.Kind -eq 'NauticMixxx') {
        $mode = 'UpdateNauticMixxx'
        $settings = $parallelProfile
        Write-Step "Updating the existing NauticMixxx skin in place at $settings"
    }
    else {
        Write-Host ''
        Write-Host '[P] Parallel: use a separate NauticMixxx profile and shortcut (recommended).'
        Write-Host '[R] Replace: update the skin in the standard Mixxx profile; Mixxx itself stays installed.'
        Write-Host '[C] Cancel.'
        $choice = (Read-Host 'Choose P, R or C [P]').Trim()
        if (-not $choice -or $choice -match '(?i)^p$') { $mode = 'Parallel' }
        elseif ($choice -match '(?i)^r$') { $mode = 'Replace' }
        elseif ($choice -match '(?i)^c$') { throw 'Installation cancelled by the user.' }
        else { throw 'Invalid option.' }
        $settings = if ($mode -eq 'Parallel') { $parallelProfile } else { $standardProfile }
    }
    $installedVersion = Get-InstalledSkinVersion -SettingsPath $settings
    if ($installedVersion -and $installedVersion -gt $newVersion) {
        throw "A newer skin ($installedVersion) is already installed in $settings. Setup will not downgrade it."
    }
    if ($installedVersion) { Write-Step "Updating skin $installedVersion to $newVersion" }
    Stop-RunningMixxx

    $backup = Backup-SkinSettings -SettingsPath $settings
    if ($mode -eq 'Parallel' -and -not (Test-Path -LiteralPath $settings -PathType Container) -and
        (Test-Path -LiteralPath $standardProfile -PathType Container)) {
        $standardConfig = Join-Path $standardProfile 'mixxx.cfg'
        $canCopy = $true
        if (Test-Path -LiteralPath $standardConfig -PathType Leaf) {
            $configText = Get-Content -LiteralPath $standardConfig -Raw
            if ($configText -match '(?m)^Version\s+(\d+\.\d+\.\d+)' -and [version]$Matches[1] -gt [version]'2.5.6') {
                $canCopy = $false
            }
        }
        if ($canCopy) {
            New-Item -ItemType Directory -Path $settings -Force | Out-Null
            Get-ChildItem -LiteralPath $standardProfile -Force | Copy-Item -Destination $settings -Recurse -Force
            Write-Step 'Copied the existing Mixxx library and settings into the separate profile'
        }
    }
    New-Item -ItemType Directory -Path $settings -Force | Out-Null
    $copiedVersion = Get-InstalledSkinVersion -SettingsPath $settings
    if ($copiedVersion -and $copiedVersion -gt $newVersion) {
        throw "A newer skin ($copiedVersion) is already present in $settings. Setup will not downgrade it."
    }
    $configPath = Join-Path $settings 'mixxx.cfg'
    $effectsPath = Join-Path $settings 'effects.xml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf) -or -not (Test-Path -LiteralPath $effectsPath -PathType Leaf)) {
        if ($NoLaunch) { throw 'Mixxx must be opened once to initialize its profile.' }
        Write-Host 'Mixxx will open once to create its profile. Close it when startup is complete.'
        Start-Rx3Mixxx -Executable $installation.Path -SettingsPath $settings
        [void](Read-Host 'Press ENTER after closing Mixxx')
        Stop-RunningMixxx
        if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
            throw 'Mixxx did not create mixxx.cfg. Run setup again after opening Mixxx once.'
        }
    }

    $skinRoot = Join-Path $settings 'skins'
    $skinTarget = Join-Path $skinRoot 'XDJ_RX3_Mixxx'
    $applicationSkinBackup = $null
    if ($installation.Kind -eq 'NauticMixxx') {
        $bundledSkin = Join-Path $installation.InstallRoot 'skins\XDJ_RX3_Mixxx'
        $bundledVersion = Get-InstalledSkinVersion -SettingsPath $installation.InstallRoot
        if ($bundledVersion -and $bundledVersion -gt $newVersion) {
            throw "A newer bundled skin ($bundledVersion) is already installed at $bundledSkin. Setup will not downgrade it."
        }
        if (-not (Test-DirectoryWritable -Directory $installation.InstallRoot)) {
            throw "Cannot update $($installation.InstallRoot). Run INSTALL-WINDOWS.bat as administrator."
        }
        if (Test-Path -LiteralPath $bundledSkin) {
            $applicationSkinBackup = Backup-SkinSettings -SettingsPath $installation.InstallRoot
            Remove-Item -LiteralPath $bundledSkin -Recurse -Force
        }
        New-Item -ItemType Directory -Path (Split-Path -Parent $bundledSkin) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'skins\XDJ_RX3_Mixxx') -Destination (Split-Path -Parent $bundledSkin) -Recurse -Force
        Write-Step "Updated the bundled NauticMixxx skin at $bundledSkin"
    }
    New-Item -ItemType Directory -Path $skinRoot -Force | Out-Null
    if (Test-Path -LiteralPath $skinTarget) { Remove-Item -LiteralPath $skinTarget -Recurse -Force }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'skins\XDJ_RX3_Mixxx') -Destination $skinRoot -Recurse -Force
    $controllers = Join-Path $settings 'controllers'
    $chains = Join-Path $settings 'effects\chains'
    New-Item -ItemType Directory -Path $controllers, $chains -Force | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'controllers\Hercules_DJControl_Inpulse_500_RX3') -File |
        Copy-Item -Destination $controllers -Force
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'controllers\Pioneer_DDJ_FLX6_RX3') -File |
        Copy-Item -Destination $controllers -Force
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'effects\chains') -File |
        Copy-Item -Destination $chains -Force
    foreach ($legacyEffect in @('RX3 SPACE.xml', 'RX3 DUB ECHO.xml')) {
        $legacyPath = Join-Path $chains $legacyEffect
        if (Test-Path -LiteralPath $legacyPath -PathType Leaf) { Remove-Item -LiteralPath $legacyPath -Force }
    }
    if (Test-Path -LiteralPath $effectsPath -PathType Leaf) { Set-Rx3QuickEffectOrder -EffectsConfig $effectsPath }
    $midiNames = @(Get-WindowsMidiInputs)
    $keys = @(Get-Rx3ControllerKeys -DeviceNames $midiNames)
    Apply-MixxxProfile -ConfigPath $configPath -ProfilePath (Join-Path $PSScriptRoot 'profile\XDJ_RX3_Mixxx.profile.cfg') `
        -ControllerPresetPath (Join-Path $controllers 'Hercules_DJControl_Inpulse_500_RX3.midi.xml') `
        -ControllerKeys $keys -InterfaceScale 1

    $iconTarget = Join-Path $settings 'NauticMixxx.ico'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'branding\NauticMixxx.ico') -Destination $iconTarget -Force
    $shell = New-Object -ComObject WScript.Shell
    $desktop = [Environment]::GetFolderPath('DesktopDirectory')
    $programs = [Environment]::GetFolderPath('Programs')
    $shortcutBackup = Join-Path $env:LOCALAPPDATA 'NauticMixxx-Backups\Shortcuts'
    foreach ($directory in @($desktop, $programs)) {
        Move-OldShortcut -Path (Join-Path $directory 'NauticMixxx Skin.lnk') -BackupRoot $shortcutBackup
    }
    Move-OldShortcut -Path (Join-Path $desktop 'Mixxx.lnk') -BackupRoot $shortcutBackup
    $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
    if ($publicDesktop -and $publicDesktop -ne $desktop) {
        try {
            Move-OldShortcut -Path (Join-Path $publicDesktop 'Mixxx.lnk') -BackupRoot $shortcutBackup
        }
        catch {
            Write-Step 'Windows will request administrator permission to remove the old public Mixxx desktop shortcut'
            $helper = Join-Path $PSScriptRoot 'windows\cleanup-public-shortcut.ps1'
            $publicShortcut = Join-Path $publicDesktop 'Mixxx.lnk'
            $arguments = @(
                '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                '-File', ('"' + $helper + '"'),
                '-ShortcutPath', ('"' + $publicShortcut + '"'),
                '-BackupRoot', ('"' + $shortcutBackup + '"')
            )
            $cleanup = Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -Wait -PassThru
            if ($cleanup.ExitCode -ne 0 -or (Test-Path -LiteralPath $publicShortcut -PathType Leaf)) {
                throw 'The public Mixxx desktop shortcut could not be removed. Close setup and remove that shortcut manually.'
            }
        }
    }
    foreach ($directory in @($desktop, $programs)) {
        $shortcut = $shell.CreateShortcut((Join-Path $directory 'NauticMixxx.lnk'))
        $shortcut.TargetPath = $installation.Path
        $shortcut.Arguments = '--settings-path "' + $settings + '"'
        $shortcut.WorkingDirectory = $installation.InstallRoot
        $shortcut.IconLocation = $iconTarget + ',0'
        $shortcut.Description = "NauticMixxx $newVersion"
        $shortcut.Save()
    }

    if (-not (Test-HerculesAsioDriver) -and -not $NoLaunch) {
        Write-Host 'Optional: the Hercules ASIO driver was not detected.' -ForegroundColor Yellow
        $driverAnswer = (Read-Host 'Download and install the official Hercules driver now? [y/N]').Trim()
        if ($driverAnswer -match '(?i)^y$') {
            & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File `
                (Join-Path $PSScriptRoot 'windows\install-hercules-driver.ps1') -NonInteractive
            if ($LASTEXITCODE -ne 0) { Write-Warning 'Hercules driver setup did not complete; the skin was installed.' }
        }
    }
    Write-Host ''
    Write-Host "NauticMixxx skin $newVersion installed successfully." -ForegroundColor Green
    Write-Host "Mode: $mode"
    Write-Host "Mixxx: $($installation.Path)"
    Write-Host "Profile: $settings"
    if ($backup) { Write-Host "Backup: $backup" }
    if ($applicationSkinBackup) { Write-Host "Bundled skin backup: $applicationSkinBackup" }
    Write-Host "Log: $logPath"
    if (-not $NoLaunch) { Start-Rx3Mixxx -Executable $installation.Path -SettingsPath $settings }
    Stop-Transcript | Out-Null
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Setup did not complete. Any backups already created were preserved.'
    try { Stop-Transcript | Out-Null } catch {}
    exit 1
}
