param([switch]$ElevatedCleanup, [string]$ProtectedPath)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Test-PathWithin {
    param([string]$Path, [string]$Parent)
    if (-not $Path -or -not $Parent) { return $false }
    $full = [IO.Path]::GetFullPath($Path).TrimEnd([char]92, [char]47)
    $base = [IO.Path]::GetFullPath($Parent).TrimEnd([char]92, [char]47)
    return $full.StartsWith($base + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase)
}

function Assert-OwnedApplicationPath {
    param([string]$Path)
    $owned = @()
    if ($env:LOCALAPPDATA) { $owned += (Join-Path $env:LOCALAPPDATA 'Programs\NauticMixxx') }
    if ($env:ProgramFiles) { $owned += (Join-Path $env:ProgramFiles 'NauticMixxx') }
    if (${env:ProgramFiles(x86)}) { $owned += (Join-Path ${env:ProgramFiles(x86)} 'NauticMixxx') }
    $full = [IO.Path]::GetFullPath($Path).TrimEnd([char]92, [char]47)
    foreach ($parent in $owned) {
        $base = [IO.Path]::GetFullPath($parent).TrimEnd([char]92, [char]47)
        if ($full.Equals($base, [StringComparison]::OrdinalIgnoreCase) -or
            (Test-PathWithin -Path $full -Parent $base)) { return $full }
    }
    throw "Refusing to remove an application outside NauticMixxx-owned folders: $Path"
}

function Test-PublicNauticShortcut {
    param([string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    if ([IO.Path]::GetFileName($full) -notin @('NauticMixxx.lnk', 'NauticMixxx Skin.lnk')) {
        return $false
    }
    foreach ($special in @('CommonDesktopDirectory', 'CommonPrograms')) {
        $parent = [Environment]::GetFolderPath($special)
        if ($parent -and [IO.Path]::GetFullPath((Split-Path -Parent $full)).Equals(
                [IO.Path]::GetFullPath($parent), [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Invoke-ElevatedRemoval {
    param([string]$Path)
    Write-Host 'Windows will request administrator permission for this component.'
    $arguments = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', ('"' + $PSCommandPath + '"'), '-ElevatedCleanup', '-ProtectedPath', ('"' + $Path + '"'))
    $process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru -ArgumentList $arguments
    if ($process.ExitCode -ne 0) { throw 'Administrator removal failed or was cancelled.' }
}

function Remove-OwnedPath {
    param([string]$Path, [string]$Label, [switch]$Quiet)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item) { return }
    if (-not $Quiet) { Write-Host "Removing $Label : $Path" }
    if ($item.PSIsContainer -and -not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        foreach ($child in @(Get-ChildItem -LiteralPath $Path -Force)) {
            Remove-OwnedPath -Path $child.FullName -Label $Label -Quiet
        }
    }
    Remove-Item -LiteralPath $Path -Force
}

function Get-NauticShortcutPaths {
    $locations = @(
        [Environment]::GetFolderPath('DesktopDirectory'),
        [Environment]::GetFolderPath('Programs'),
        [Environment]::GetFolderPath('CommonDesktopDirectory'),
        [Environment]::GetFolderPath('CommonPrograms')
    ) | Where-Object { $_ } | Select-Object -Unique
    foreach ($location in $locations) {
        foreach ($name in @('NauticMixxx.lnk', 'NauticMixxx Skin.lnk')) {
            $path = Join-Path $location $name
            if (Test-Path -LiteralPath $path -PathType Leaf) { $path }
        }
    }
}

function Test-Rx3StandardProfile {
    param([string]$Profile)
    foreach ($path in @(
        'skins\XDJ_RX3_Mixxx',
        'controllers\Hercules_DJControl_Inpulse_500_RX3.midi.xml',
        'controllers\Hercules-DJControl-Inpulse-500-RX3-script.js',
        'controllers\Pioneer-DDJ-FLX6-RX3-Browser.midi.xml',
        'controllers\Pioneer-DDJ-FLX6-RX3-Browser.js',
        'NauticMixxx.ico',
        'effects\chains\RX3 REVERB.xml',
        'effects\chains\RX3 PING PONG.xml',
        'effects\chains\RX3 NOISE.xml',
        'effects\chains\RX3 FILTER.xml'
    )) {
        if (Test-Path -LiteralPath (Join-Path $Profile $path)) { return $true }
    }
    $config = Join-Path $Profile 'mixxx.cfg'
    if (Test-Path -LiteralPath $config -PathType Leaf) {
        $body = [IO.File]::ReadAllText($config)
        if ($body -match 'XDJ_RX3_Mixxx|Hercules_DJControl_Inpulse_500_RX3') { return $true }
    }
    $effects = Join-Path $Profile 'effects.xml'
    if (Test-Path -LiteralPath $effects -PathType Leaf) {
        $body = [IO.File]::ReadAllText($effects)
        if ($body -match 'RX3 (?:REVERB|PING PONG|NOISE|FILTER|SPACE|DUB ECHO)') { return $true }
    }
    return $false
}

function Remove-Rx3ConfigEntries {
    param([string]$ConfigPath)
    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) { return }
    $lines = [IO.File]::ReadAllLines($ConfigPath)
    $keys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $section = ''
    foreach ($line in $lines) {
        if ($line -match '^\s*\[([^]]+)\]') { $section = $Matches[1]; continue }
        if ($section -eq 'ControllerPreset' -and
            $line -match '^\s*([^\s=]+)\s+(.*Hercules_DJControl_Inpulse_500_RX3\.midi\.xml)\s*$') {
            [void]$keys.Add($Matches[1])
        }
    }
    $kept = New-Object System.Collections.Generic.List[string]
    $section = ''
    foreach ($line in $lines) {
        if ($line -match '^\s*\[([^]]+)\]') { $section = $Matches[1] }
        if ($section -eq 'Config' -and $line -match '^\s*ResizableSkin\s+XDJ_RX3_Mixxx\s*$') { continue }
        if ($section -eq 'ControllerPreset' -and
            $line -match '^\s*([^\s=]+)\s+.*Hercules_DJControl_Inpulse_500_RX3\.midi\.xml\s*$') { continue }
        if ($section -eq 'Controller' -and $line -match '^\s*([^\s=]+)\s+1\s*$' -and
            $keys.Contains($Matches[1])) { continue }
        [void]$kept.Add($line)
    }
    if ($kept.Count -ne $lines.Length) {
        $encoding = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
        [IO.File]::WriteAllLines($ConfigPath + '.nautic-uninstall.tmp', [string[]]$kept, $encoding)
        Move-Item -LiteralPath ($ConfigPath + '.nautic-uninstall.tmp') -Destination $ConfigPath -Force
    }
}

function Remove-Rx3EffectReferences {
    param([string]$EffectsPath)
    if (-not (Test-Path -LiteralPath $EffectsPath -PathType Leaf)) { return }
    [xml]$xml = [IO.File]::ReadAllText($EffectsPath)
    $changed = $false
    foreach ($node in @($xml.SelectNodes('//ChainPresetName'))) {
        if ($node.InnerText -match '^RX3 (?:REVERB|PING PONG|NOISE|FILTER|SPACE|DUB ECHO)$') {
            [void]$node.ParentNode.RemoveChild($node)
            $changed = $true
        }
    }
    if ($changed) { $xml.Save($EffectsPath) }
}

function Remove-Rx3StandardProfile {
    param([string]$Profile)
    if (-not (Test-Path -LiteralPath $Profile -PathType Container)) { return }
    Remove-Rx3ConfigEntries -ConfigPath (Join-Path $Profile 'mixxx.cfg')
    Remove-Rx3EffectReferences -EffectsPath (Join-Path $Profile 'effects.xml')
    foreach ($relative in @(
        'skins\XDJ_RX3_Mixxx',
        'controllers\Hercules_DJControl_Inpulse_500_RX3.midi.xml',
        'controllers\Hercules-DJControl-Inpulse-500-RX3-script.js',
        'controllers\Pioneer-DDJ-FLX6-RX3-Browser.midi.xml',
        'controllers\Pioneer-DDJ-FLX6-RX3-Browser.js',
        'NauticMixxx.ico',
        'effects\chains\RX3 REVERB.xml',
        'effects\chains\RX3 PING PONG.xml',
        'effects\chains\RX3 NOISE.xml',
        'effects\chains\RX3 FILTER.xml',
        'effects\chains\RX3 SPACE.xml',
        'effects\chains\RX3 DUB ECHO.xml'
    )) {
        Remove-OwnedPath -Path (Join-Path $Profile $relative) -Label 'RX3 profile component'
    }
    $sharedScript = Join-Path $Profile 'controllers\midi-components-0.0.js'
    if (Test-Path -LiteralPath $sharedScript -PathType Leaf) {
        $otherReferences = @(Get-ChildItem -LiteralPath (Join-Path $Profile 'controllers') -Filter '*.midi.xml' -File -ErrorAction SilentlyContinue |
            Select-String -SimpleMatch 'midi-components-0.0.js' -Quiet)
        if (-not ($otherReferences -contains $true)) {
            Remove-OwnedPath -Path $sharedScript -Label 'unused RX3 mapping library'
        }
    }
}

function Get-OwnedApplicationRoots {
    $roots = @()
    if ($env:LOCALAPPDATA) { $roots += (Join-Path $env:LOCALAPPDATA 'Programs\NauticMixxx') }
    if ($env:ProgramFiles) { $roots += (Join-Path $env:ProgramFiles 'NauticMixxx') }
    if (${env:ProgramFiles(x86)}) { $roots += (Join-Path ${env:ProgramFiles(x86)} 'NauticMixxx') }
    return @($roots | Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -Unique)
}

function Get-SharedNativeReplacements {
    $roots = @()
    if ($env:ProgramFiles) { $roots += (Join-Path $env:ProgramFiles 'Mixxx') }
    if (${env:ProgramFiles(x86)}) { $roots += (Join-Path ${env:ProgramFiles(x86)} 'Mixxx') }
    if ($env:LOCALAPPDATA) { $roots += (Join-Path $env:LOCALAPPDATA 'Programs\Mixxx') }
    foreach ($root in $roots) {
        $marker = Join-Path $root 'rx3-build.json'
        if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { continue }
        try {
            $build = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
            if ($build.product -eq 'NauticMixxx') { $root }
        }
        catch { throw "Cannot inspect the native build marker at $marker" }
    }
}

function Get-NauticRemovalPlan {
    $plan = New-Object System.Collections.ArrayList
    foreach ($root in @(Get-OwnedApplicationRoots)) {
        [void]$plan.Add([pscustomobject]@{ Kind = 'Application'; Path = (Assert-OwnedApplicationPath $root) })
    }
    foreach ($relative in @('Mixxx-RX3', 'NauticMixxx', 'NauticMixxx-Backups', 'Mixxx-XDJ-RX3-Backups')) {
        $path = Join-Path $env:LOCALAPPDATA $relative
        if (Test-Path -LiteralPath $path) {
            [void]$plan.Add([pscustomobject]@{ Kind = 'Data'; Path = $path })
        }
    }
    $standard = Join-Path $env:LOCALAPPDATA 'Mixxx'
    if (Test-Rx3StandardProfile -Profile $standard) {
        [void]$plan.Add([pscustomobject]@{ Kind = 'StandardProfileComponents'; Path = $standard })
    }
    foreach ($shortcut in @(Get-NauticShortcutPaths)) {
        [void]$plan.Add([pscustomobject]@{ Kind = 'Shortcut'; Path = $shortcut })
    }
    foreach ($relative in @('XDJ_RX3_Mixxx', 'RX3-Hercules-Driver')) {
        $path = Join-Path $env:TEMP $relative
        if (Test-Path -LiteralPath $path) {
            [void]$plan.Add([pscustomobject]@{ Kind = 'DownloadCache'; Path = $path })
        }
    }
    foreach ($pattern in @('NauticMixxx-install-*.log', 'NauticMixxx-skin-install-*.log')) {
        foreach ($item in @(Get-ChildItem -LiteralPath $env:TEMP -Filter $pattern -File -ErrorAction SilentlyContinue)) {
            [void]$plan.Add([pscustomobject]@{ Kind = 'Log'; Path = $item.FullName })
        }
    }
    return @($plan)
}

# Loading these functions for verification must never start an interactive removal.
if ($MyInvocation.InvocationName -eq '.') { return }

try {
    if ($env:OS -ne 'Windows_NT') { throw 'Windows is required.' }
    if (-not $env:LOCALAPPDATA -or -not $env:TEMP) { throw 'Windows profile paths are unavailable.' }
    if ($ElevatedCleanup) {
        if (Test-PublicNauticShortcut -Path $ProtectedPath) {
            Remove-OwnedPath -Path $ProtectedPath -Label 'public NauticMixxx shortcut'
            exit 0
        }
        $safe = Assert-OwnedApplicationPath -Path $ProtectedPath
        if (-not ((Test-PathWithin $safe $env:ProgramFiles) -or
            (Test-PathWithin $safe ${env:ProgramFiles(x86)}))) {
            throw 'Elevated removal is limited to NauticMixxx-owned components.'
        }
        Remove-OwnedPath -Path $safe -Label 'protected NauticMixxx application'
        exit 0
    }

    $sharedReplacements = @(Get-SharedNativeReplacements)
    if ($sharedReplacements.Count -gt 0) {
        throw "A native NauticMixxx build replaced a shared Mixxx application at $($sharedReplacements -join ', '). Restore its original application backup before running this uninstaller; backups were preserved."
    }
    $plan = @(Get-NauticRemovalPlan)
    if ($plan.Count -eq 0) { Write-Host 'No NauticMixxx components were found.'; exit 0 }
    Write-Host 'NauticMixxx components found:' -ForegroundColor Cyan
    foreach ($entry in $plan) { Write-Host ("  [{0}] {1}" -f $entry.Kind, $entry.Path) }
    Write-Host ''
    Write-Host 'The separate NauticMixxx profile and backups may contain library data.' -ForegroundColor Yellow
    Write-Host 'Music files outside these folders, official Mixxx and the shared Hercules driver are retained.'
    Write-Host 'If the skin was installed in the standard Mixxx profile, only RX3 components are removed.'
    if ((Read-Host 'Type UNINSTALL to remove everything listed') -cne 'UNINSTALL') {
        Write-Host 'Removal cancelled.'
        exit 2
    }
    if (@(Get-Process -Name mixxx -ErrorAction SilentlyContinue).Count -gt 0) {
        throw 'Close all Mixxx and NauticMixxx windows, then run the uninstaller again.'
    }

    $failed = New-Object System.Collections.ArrayList
    foreach ($entry in $plan) {
        try {
            if ($entry.Kind -eq 'StandardProfileComponents') {
                Remove-Rx3StandardProfile -Profile $entry.Path
            }
            elseif ($entry.Kind -eq 'Application') {
                if ((Test-PathWithin $entry.Path $env:ProgramFiles) -or
                    (Test-PathWithin $entry.Path ${env:ProgramFiles(x86)})) {
                    try { Remove-OwnedPath -Path $entry.Path -Label $entry.Kind }
                    catch { Invoke-ElevatedRemoval -Path $entry.Path }
                }
                else { Remove-OwnedPath -Path $entry.Path -Label $entry.Kind }
            }
            elseif ($entry.Kind -eq 'Shortcut' -and (Test-PublicNauticShortcut $entry.Path)) {
                try { Remove-OwnedPath -Path $entry.Path -Label $entry.Kind }
                catch { Invoke-ElevatedRemoval -Path $entry.Path }
            }
            else { Remove-OwnedPath -Path $entry.Path -Label $entry.Kind }
        }
        catch {
            [void]$failed.Add("$($entry.Path): $($_.Exception.Message)")
            break
        }
    }
    if ($failed.Count -gt 0) {
        foreach ($failure in $failed) { Write-Host "FAILED: $failure" -ForegroundColor Red }
        throw "$($failed.Count) component(s) could not be removed. Run the uninstaller again after fixing the errors."
    }
    Write-Host 'NauticMixxx removal completed.' -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
