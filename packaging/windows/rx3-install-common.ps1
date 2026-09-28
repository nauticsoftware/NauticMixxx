function Write-Step {
    param([string]$Message)
    Write-Host "[XDJ-RX3] $Message" -ForegroundColor Cyan
}

function Get-Rx3ControllerKeys {
    param([string[]]$DeviceNames)
    $keys = @("DJControl_Inpulse_500")
    foreach ($name in $DeviceNames) {
        if ($name -match "(?i)DJControl[ _-]*Inpulse[ _-]*500") {
            # Same normalization as ControllerManager::sanitizeDeviceName.
            $keys += $name.Replace(" ", "_").Replace("/", "_").Replace("\", "_")
        }
    }
    return @($keys | Select-Object -Unique)
}

function Get-WindowsMidiInputs {
    if (-not ("Rx3MidiDevices" -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class Rx3MidiDevices {
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct Caps {
        public ushort manufacturer, product;
        public uint version;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string name;
        public uint support;
    }
    [DllImport("winmm.dll")] static extern uint midiInGetNumDevs();
    [DllImport("winmm.dll", CharSet=CharSet.Unicode)]
    static extern uint midiInGetDevCapsW(UIntPtr id, out Caps caps, uint size);
    public static string[] Names() {
        var names = new List<string>();
        for (uint i=0; i<midiInGetNumDevs(); ++i) {
            Caps caps;
            if (midiInGetDevCapsW(new UIntPtr(i), out caps, (uint)Marshal.SizeOf(typeof(Caps))) == 0)
                names.Add(caps.name);
        }
        return names.ToArray();
    }
}
'@
    }
    return [Rx3MidiDevices]::Names()
}

function Get-Rx3InterfaceScale {
    # Screen.WorkingArea is logical pixels in this DPI-unaware PowerShell host.
    # Leave room for a title bar, taskbar and borders. Never stretch the canvas.
    Add-Type -AssemblyName System.Windows.Forms
    $area = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $fit = [Math]::Min(($area.Width - 32) / 1280.0, ($area.Height - 72) / 800.0)
    return [Math]::Max(0.5, [Math]::Min(1.0, [Math]::Floor($fit * 100) / 100.0))
}

function Test-Rx3Payload {
    param([string]$PackageRoot)
    $manifestPath = Join-Path $PackageRoot "payload-sha256.json"
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw 'The package manifest is missing. Extract the complete ZIP and try again.'
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if (-not $manifest.files -or $manifest.files.Count -eq 0) {
        throw 'The package manifest does not list any files.'
    }
    $root = [IO.Path]::GetFullPath($PackageRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $checked = 0
    $total = $manifest.files.Count
    foreach ($entry in $manifest.files) {
        $path = [IO.Path]::GetFullPath((Join-Path $root $entry.path))
        if (-not $path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid path in the package manifest.' }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Incomplete package: $($entry.path)" }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.sha256) {
            throw "File $($entry.path) does not match the original package. Extract the ZIP again."
        }
        $checked++
        if ($checked -eq 1 -or $checked % 100 -eq 0 -or $checked -eq $total) {
            Write-Host ("Verified {0}/{1} files" -f $checked, $total)
        }
    }
}

function Start-Rx3Mixxx {
    param([string]$Executable, [string]$SettingsPath)
    # Start-Process joins ArgumentList: quote paths explicitly, including spaces.
    if ($SettingsPath.Contains('"')) { throw 'Invalid settings path.' }
    Start-Process -FilePath $Executable -ArgumentList @("--settings-path", ('"' + $SettingsPath + '"')) | Out-Null
}

function ConvertTo-MixxxVersion {
    param([string]$Value)

    if ($Value -and $Value -match '(\d+\.\d+\.\d+)') {
        return [version]$Matches[1]
    }
    return $null
}

function Get-MixxxInstallations {
    $candidates = New-Object System.Collections.ArrayList

    $nauticParents = @()
    if ($env:LOCALAPPDATA) { $nauticParents += (Join-Path $env:LOCALAPPDATA 'Programs\NauticMixxx') }
    if ($env:ProgramFiles) { $nauticParents += (Join-Path $env:ProgramFiles 'NauticMixxx') }
    foreach ($parent in $nauticParents) {
        [void]$candidates.Add([pscustomobject]@{ Path = (Join-Path $parent 'mixxx.exe'); Source = 'NauticMixxx'; VersionHint = $null; Kind = 'NauticMixxx' })
        if (Test-Path -LiteralPath $parent -PathType Container) {
            foreach ($directory in Get-ChildItem -LiteralPath $parent -Directory -ErrorAction SilentlyContinue) {
                [void]$candidates.Add([pscustomobject]@{ Path = (Join-Path $directory.FullName 'mixxx.exe'); Source = 'NauticMixxx'; VersionHint = $null; Kind = 'NauticMixxx' })
            }
        }
    }

    if ($env:ProgramFiles) {
        [void]$candidates.Add([pscustomobject]@{ Path = (Join-Path $env:ProgramFiles "Mixxx\mixxx.exe"); Source = 'Program Files'; VersionHint = $null; Kind = 'Mixxx' })
    }
    if (${env:ProgramFiles(x86)}) {
        [void]$candidates.Add([pscustomobject]@{ Path = (Join-Path ${env:ProgramFiles(x86)} "Mixxx\mixxx.exe"); Source = 'Program Files (x86)'; VersionHint = $null; Kind = 'Mixxx' })
    }
    if ($env:LOCALAPPDATA) {
        [void]$candidates.Add([pscustomobject]@{ Path = (Join-Path $env:LOCALAPPDATA "Programs\Mixxx\mixxx.exe"); Source = 'User'; VersionHint = $null; Kind = 'Mixxx' })
    }

    foreach ($registryRoot in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
        if (Test-Path $registryRoot) {
            foreach ($entry in Get-ChildItem $registryRoot) {
                $values = Get-ItemProperty $entry.PSPath -ErrorAction SilentlyContinue
                if ($values.PSObject.Properties["DisplayName"] -and $values.DisplayName -match "^(?:Mixxx|NauticMixxx)(?: |$)" -and $values.PSObject.Properties["InstallLocation"] -and $values.InstallLocation) {
                    $versionHint = if ($values.PSObject.Properties['DisplayVersion']) { $values.DisplayVersion } else { $null }
                    $kind = if ($values.DisplayName -match '^NauticMixxx') { 'NauticMixxx' } else { 'Mixxx' }
                    [void]$candidates.Add([pscustomobject]@{ Path = (Join-Path $values.InstallLocation "mixxx.exe"); Source = 'Registry'; VersionHint = $versionHint; Kind = $kind })
                }
            }
        }
    }

    $command = Get-Command "mixxx.exe" -ErrorAction SilentlyContinue
    if ($command) {
        [void]$candidates.Add([pscustomobject]@{ Path = $command.Source; Source = 'PATH'; VersionHint = $null; Kind = 'Mixxx' })
    }

    $seen = @{}
    foreach ($candidate in $candidates) {
        if (-not $candidate.Path -or -not (Test-Path -LiteralPath $candidate.Path -PathType Leaf)) { continue }
        $fullPath = [IO.Path]::GetFullPath($candidate.Path)
        if ($seen.ContainsKey($fullPath)) { continue }
        $seen[$fullPath] = $true
        $versionText = (Get-Item -LiteralPath $fullPath).VersionInfo.ProductVersion
        $version = ConvertTo-MixxxVersion -Value $versionText
        if (-not $version) { $version = ConvertTo-MixxxVersion -Value $candidate.VersionHint }
        $buildInfoPath = Join-Path (Split-Path -Parent $fullPath) 'rx3-build.json'
        $nauticVersion = $null
        if (Test-Path -LiteralPath $buildInfoPath -PathType Leaf) {
            try {
                $buildInfo = Get-Content -LiteralPath $buildInfoPath -Raw | ConvertFrom-Json
                if ($buildInfo.product -eq 'NauticMixxx') {
                    $nauticVersion = ConvertTo-MixxxVersion -Value $buildInfo.version
                }
            } catch {}
        }
        [pscustomobject]@{
            Path = $fullPath
            InstallRoot = Split-Path -Parent $fullPath
            Version = $version
            VersionText = if ($version) { $version.ToString() } elseif ($versionText) { $versionText } else { 'unknown' }
            Source = $candidate.Source
            Kind = $candidate.Kind
            NauticVersion = $nauticVersion
        }
    }
}

function Find-MixxxExecutable {
    $installation = @(Get-MixxxInstallations | Select-Object -First 1)
    if ($installation.Count -gt 0) { return $installation[0].Path }
    return $null
}

function Get-LatestStableMixxxVersion {
    param([version]$Fallback = [version]'2.5.6')

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $headers = @{ 'User-Agent' = 'NauticMixxx-Installer/1.1.0' }
        $release = Invoke-RestMethod -UseBasicParsing -Uri 'https://api.github.com/repos/mixxxdj/mixxx/releases/latest' `
            -Headers $headers -TimeoutSec 8
        $version = ConvertTo-MixxxVersion -Value $release.tag_name
        if ($version) { return $version }
    }
    catch {
        Write-Warning "The latest stable Mixxx version could not be checked. Using validated base $Fallback."
    }
    return $Fallback
}

function Test-HerculesAsioDriver {
    foreach ($root in @('HKLM:\SOFTWARE\ASIO', 'HKLM:\SOFTWARE\WOW6432Node\ASIO')) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        if (@(Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '(?i)Hercules|DJControl|Inpulse' }).Count -gt 0) {
            return $true
        }
    }
    return $false
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-SafeInstallRoot {
    param([string]$InstallRoot)

    $full = [IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')
    $root = [IO.Path]::GetPathRoot($full).TrimEnd('\')
    $forbidden = @($root, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA, $env:USERPROFILE, $env:WINDIR) |
        Where-Object { $_ } | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') }
    if ($forbidden -contains $full -or $full.Length -lt 8) {
        throw "Unsafe installation path: $full"
    }
    return $full
}

function Test-DirectoryWritable {
    param([string]$Directory)

    try {
        $probe = Join-Path $Directory ('.nauticmixxx-write-' + [guid]::NewGuid().ToString('N') + '.tmp')
        [IO.File]::WriteAllText($probe, 'test')
        Remove-Item -LiteralPath $probe -Force
        return $true
    }
    catch { return $false }
}

function Backup-MixxxApplication {
    param([string]$InstallRoot, [string]$VersionText = 'unknown')

    $safeRoot = Assert-SafeInstallRoot -InstallRoot $InstallRoot
    if (-not (Test-Path -LiteralPath (Join-Path $safeRoot 'mixxx.exe') -PathType Leaf)) {
        throw "mixxx.exe was not found in the installation to replace: $safeRoot"
    }
    $backupParent = Join-Path $env:LOCALAPPDATA 'NauticMixxx-Backups\Applications'
    $safeVersion = $VersionText -replace '[^0-9A-Za-z._-]', '_'
    $backupRoot = Join-Path $backupParent ("Mixxx-$safeVersion-" + (Get-Date -Format 'yyyyMMdd-HHmmssfff'))
    New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
    Write-Step "Backing up the complete application to $backupRoot"
    Copy-Item -LiteralPath $safeRoot -Destination $backupRoot -Recurse -Force
    if (-not (Test-Path -LiteralPath (Join-Path $backupRoot 'mixxx.exe') -PathType Leaf)) {
        throw 'The application backup could not be verified.'
    }
    return $backupRoot
}

function Install-OfficialMixxx {
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw 'Mixxx 2.5.6 and this package require 64-bit Windows.'
    }

    $mixxxVersion = "2.5.6"
    $installerName = "mixxx-$mixxxVersion-win64.msi"
    $downloadUrl = "https://downloads.mixxx.org/releases/$mixxxVersion/$installerName"
    $expectedHash = "0d1f01a1f5c2e4d4180cd462e60365d0230b405808e7bd2b6625b62a53a29c72"
    $downloadDirectory = Join-Path ([System.IO.Path]::GetTempPath()) "XDJ_RX3_Mixxx"
    $installerPath = Join-Path $downloadDirectory $installerName

    New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null

    $downloadRequired = $true
    if (Test-Path -LiteralPath $installerPath -PathType Leaf) {
        $existingHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($existingHash -eq $expectedHash) {
            $downloadRequired = $false
            Write-Step 'Reusing a verified official download'
        }
        else {
            Remove-Item -LiteralPath $installerPath -Force
        }
    }

    if ($downloadRequired) {
        Write-Step "Mixxx is not installed; downloading official Mixxx $mixxxVersion"
        Write-Host "Source: $downloadUrl"
        Write-Host 'Approximate size: 115 MB. This may take a few minutes.' -ForegroundColor Yellow

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try {
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $downloadUrl -Destination $installerPath -DisplayName "Mixxx $mixxxVersion" -Description 'Official download for XDJ-RX3'
        }
        catch {
            Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $installerPath
        }
    }

    $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
        throw 'Mixxx installer SHA-256 verification failed. No downloaded file was executed.'
    }

    $signature = Get-AuthenticodeSignature -LiteralPath $installerPath
    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
        throw "The official Mixxx installer signature is invalid: $($signature.Status)."
    }

    Write-Step "Installing Mixxx $mixxxVersion"
    $msiArguments = @("/i", "`"$installerPath`"", "/passive", "/norestart")
    $installerProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArguments -Verb RunAs -Wait -PassThru
    if ($installerProcess.ExitCode -notin @(0, 3010)) {
        throw "The Mixxx installer exited with code $($installerProcess.ExitCode)."
    }

    if ($installerProcess.ExitCode -eq 3010) { Write-Host 'Windows requires a restart after installation.' -ForegroundColor Yellow }
    $mixxxExecutable = Find-MixxxExecutable
    if (-not $mixxxExecutable) {
        throw 'Mixxx was installed, but mixxx.exe was not found in a standard location.'
    }

    Write-Host "Mixxx $mixxxVersion was installed successfully." -ForegroundColor Green
    return $mixxxExecutable
}

function Stop-RunningMixxx {
    $processes = @(Get-Process -Name "mixxx" -ErrorAction SilentlyContinue)
    if ($processes.Count -eq 0) { return }
    Write-Host 'Close Mixxx to continue; setup will not force it to quit.' -ForegroundColor Yellow
    [void](Read-Host 'Press ENTER after closing Mixxx')
    if (@(Get-Process -Name "mixxx" -ErrorAction SilentlyContinue).Count -gt 0) {
        throw 'Mixxx is still running. Close it and run setup again.'
    }
}

function Backup-MixxxSettings {
    param([string]$SettingsPath)

    $settingsParent = Split-Path -Parent $SettingsPath
    if (-not $settingsParent) {
        throw 'An external location for the Mixxx backup could not be determined.'
    }

    $backupParent = Join-Path $settingsParent "Mixxx-XDJ-RX3-Backups"
    $backupRoot = Join-Path $backupParent ("Mixxx-before-XDJ-RX3-" + (Get-Date -Format "yyyyMMdd-HHmmssfff"))

    Write-Step "Backing up all Mixxx settings to $backupRoot"
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    foreach ($settingsItem in Get-ChildItem -LiteralPath $SettingsPath -Force) {
        Copy-Item -LiteralPath $settingsItem.FullName -Destination $backupRoot -Recurse -Force
    }

    return $backupRoot
}

function Set-MixxxConfigValue {
    param(
        [System.Collections.ArrayList]$Lines,
        [string]$Section,
        [string]$Key,
        [string]$Value
    )

    $sectionHeader = "[$Section]"
    $sectionStart = -1
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -eq $sectionHeader) {
            $sectionStart = $index
            break
        }
    }

    if ($sectionStart -lt 0) {
        if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1].Trim()) {
            [void]$Lines.Add("")
        }
        [void]$Lines.Add($sectionHeader)
        [void]$Lines.Add("$Key $Value")
        return
    }

    $sectionEnd = $Lines.Count
    for ($index = $sectionStart + 1; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -match "^\[.+\]$") {
            $sectionEnd = $index
            break
        }
    }

    $keyPattern = "^\s*" + [regex]::Escape($Key) + "(?:\s+|=)"
    for ($index = $sectionStart + 1; $index -lt $sectionEnd; $index++) {
        if ($Lines[$index] -match $keyPattern) {
            $Lines[$index] = "$Key $Value"
            return
        }
    }

    $Lines.Insert($sectionEnd, "$Key $Value")
}

function Apply-MixxxProfile {
    param(
        [string]$ConfigPath,
        [string]$ProfilePath,
        [string]$ControllerPresetPath,
        [string[]]$ControllerKeys = @("DJControl_Inpulse_500"),
        [double]$InterfaceScale = 1
    )

    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        throw 'mixxx.cfg was not found while applying the RX3 profile.'
    }

    $lines = New-Object System.Collections.ArrayList
    foreach ($existingLine in [System.IO.File]::ReadAllLines($ConfigPath)) {
        [void]$lines.Add($existingLine)
    }

    $currentSection = ""
    foreach ($rawLine in [System.IO.File]::ReadAllLines($ProfilePath)) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith("#") -or $line.StartsWith(";")) {
            continue
        }
        if ($line.StartsWith("[") -and $line.EndsWith("]")) {
            $currentSection = $line.Substring(1, $line.Length - 2)
            continue
        }
        if (-not $currentSection) {
            throw "The RX3 profile contains a value outside a section: $line"
        }

        $parts = $line -split "\s+", 2
        if ($parts.Count -ne 2) {
            throw "The RX3 profile contains an invalid line: $line"
        }
        Set-MixxxConfigValue -Lines $lines -Section $currentSection -Key $parts[0] -Value $parts[1]
    }

    $portableControllerPath = $ControllerPresetPath -replace "\\", "/"
    Set-MixxxConfigValue -Lines $lines -Section "Config" -Key "ResizableSkin" -Value "XDJ_RX3_Mixxx"
    foreach ($deviceKey in $ControllerKeys) {
        Set-MixxxConfigValue -Lines $lines -Section "ControllerPreset" -Key $deviceKey -Value $portableControllerPath
        Set-MixxxConfigValue -Lines $lines -Section "Controller" -Key $deviceKey -Value "1"
    }
    Set-MixxxConfigValue -Lines $lines -Section "Config" -Key "ScaleFactor" -Value $InterfaceScale.ToString("0.##", [Globalization.CultureInfo]::InvariantCulture)

    $utf8WithoutBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
    [System.IO.File]::WriteAllLines("$ConfigPath.rx3.tmp", [string[]]$lines, $utf8WithoutBom)
    Move-Item -LiteralPath "$ConfigPath.rx3.tmp" -Destination $ConfigPath -Force

    $savedConfig = [System.IO.File]::ReadAllText($ConfigPath)
    if ($savedConfig -notmatch "(?m)^ResizableSkin\s+XDJ_RX3_Mixxx\s*$") {
        throw 'The XDJ-RX3 skin could not be enabled in mixxx.cfg.'
    }
    foreach ($deviceKey in $ControllerKeys) {
        if ($savedConfig -notmatch ("(?m)^" + [regex]::Escape($deviceKey) + "\s+1\s*$")) {
            throw "Controller $deviceKey could not be enabled in mixxx.cfg."
        }
    }
}

function Set-Rx3QuickEffectOrder {
    param([string]$EffectsConfig)

    [xml]$effectsDocument = [System.IO.File]::ReadAllText($EffectsConfig)
    $root = $effectsDocument.DocumentElement
    if (-not $root) {
        throw 'effects.xml does not contain a valid XML document.'
    }

    $presetList = $root.SelectSingleNode("QuickEffectPresetList")
    if (-not $presetList) {
        $presetList = $effectsDocument.CreateElement("QuickEffectPresetList")
        [void]$root.AppendChild($presetList)
    }

    $rx3Presets = @("RX3 REVERB", "RX3 PING PONG", "RX3 NOISE", "RX3 FILTER")
    $legacyRx3Presets = @("RX3 SPACE", "RX3 DUB ECHO")
    $existingNodes = @($presetList.SelectNodes("ChainPresetName"))
    foreach ($node in $existingNodes) {
        if (($rx3Presets -contains $node.InnerText.Trim()) -or ($legacyRx3Presets -contains $node.InnerText.Trim())) {
            [void]$presetList.RemoveChild($node)
        }
    }

    for ($index = $rx3Presets.Count - 1; $index -ge 0; $index--) {
        $node = $effectsDocument.CreateElement("ChainPresetName")
        $node.InnerText = $rx3Presets[$index]
        if ($presetList.FirstChild) {
            [void]$presetList.InsertBefore($node, $presetList.FirstChild)
        }
        else {
            [void]$presetList.AppendChild($node)
        }
    }

    $temporaryFile = "$EffectsConfig.rx3.tmp"
    $writerSettings = New-Object -TypeName System.Xml.XmlWriterSettings
    $writerSettings.Indent = $true
    $writerSettings.NewLineChars = "`r`n"
    $writerSettings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
    $writerSettings.Encoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false

    $writer = [System.Xml.XmlWriter]::Create($temporaryFile, $writerSettings)
    try {
        $effectsDocument.Save($writer)
    }
    finally {
        $writer.Dispose()
    }
    Move-Item -LiteralPath $temporaryFile -Destination $EffectsConfig -Force
}
