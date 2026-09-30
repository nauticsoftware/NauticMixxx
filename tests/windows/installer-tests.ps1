param([string]$PackageRoot)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0
if (-not $PackageRoot) { $PackageRoot = Join-Path $PSScriptRoot "../../build/NauticMixxx-1.2.0-Windows-x64/NauticMixxx-Files" }
$PackageRoot = [IO.Path]::GetFullPath($PackageRoot)
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("rx3-installer-tests-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$count = 0
function Assert-Rx3($condition, $message) {
    if (-not $condition) { throw "FAIL: $message" }
    $script:count++
}
try {
    foreach ($script in Get-ChildItem -LiteralPath $PackageRoot -Filter *.ps1 -Recurse) {
        $tokens = $null; $errors = $null
        [void][Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errors)
        Assert-Rx3 ($errors.Count -eq 0) "PowerShell syntax: $($script.FullName): $errors"
    }
    . (Join-Path $PackageRoot "windows/rx3-install-common.ps1")
    Test-Rx3Payload -PackageRoot $PackageRoot
    Assert-Rx3 $true "Original payload hashes"

    $originalLocalAppData = $env:LOCALAPPDATA
    try {
        $env:LOCALAPPDATA = $testRoot
        $legacyRoot = Join-Path $testRoot 'Programs/NauticMixxx/1.0.0'
        New-Item -ItemType Directory -Path $legacyRoot -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $legacyRoot 'mixxx.exe'), [byte[]]@(77, 90))
        '{"product":"NauticMixxx","version":"1.0.0"}' | Set-Content -LiteralPath (Join-Path $legacyRoot 'rx3-build.json')
        $legacy = @(Get-MixxxInstallations | Where-Object { $_.Path -eq (Join-Path $legacyRoot 'mixxx.exe') })
        Assert-Rx3 ($legacy.Count -eq 1 -and $legacy[0].Kind -eq 'NauticMixxx' -and
            $legacy[0].NauticVersion -eq [version]'1.0.0') 'NauticMixxx 1.0 is detected as an installed application'
    }
    finally {
        $env:LOCALAPPDATA = $originalLocalAppData
    }

    $names = @("DJControl Inpulse 500", "2- DJControl Inpulse 500", "Other MIDI Device")
    $keys = @(Get-Rx3ControllerKeys -DeviceNames $names)
    Assert-Rx3 ($keys.Count -eq 2 -and $keys -contains "2-_DJControl_Inpulse_500") "Windows MIDI device normalization"

    $settings = Join-Path $testRoot "settings con espacios"
    New-Item -ItemType Directory -Path $settings | Out-Null
    $config = Join-Path $settings "mixxx.cfg"
    @'
[Config]
ResizableSkin Deere
Locale es_ES
[Soundcard]
master_device Local ASIO device
[Library]
Directory C:/Musica/coleccion
[Unrelated]
untouched 47
[Controller]
Other_MIDI_Device 1
'@ | Set-Content -LiteralPath $config -Encoding UTF8
    $database = Join-Path $settings "mixxxdb.sqlite"
    [IO.File]::WriteAllBytes($database, [byte[]]@(0, 1, 2, 255, 32))
    $originalConfig = [IO.File]::ReadAllBytes($config)
    $backup = Backup-MixxxSettings -SettingsPath $settings
    Assert-Rx3 (-not $backup.StartsWith($settings + [IO.Path]::DirectorySeparatorChar)) "Backup outside settings"
    Assert-Rx3 ((Get-FileHash $database).Hash -eq (Get-FileHash (Join-Path $backup "mixxxdb.sqlite")).Hash) "Database backup byte equality"

    $mapping = Join-Path $settings "controllers/Hercules_DJControl_Inpulse_500_RX3.midi.xml"
    Apply-MixxxProfile -ConfigPath $config -ProfilePath (Join-Path $PackageRoot "profile/XDJ_RX3_Mixxx.profile.cfg") -ControllerPresetPath $mapping -ControllerKeys $keys -InterfaceScale 0.8
    $first = [IO.File]::ReadAllText($config)
    Assert-Rx3 ($first.Contains("master_device Local ASIO device") -and $first.Contains("Directory C:/Musica/coleccion") -and $first.Contains("untouched 47")) "Audio, library and unrelated settings preserved"
    Assert-Rx3 ($first.Contains("2-_DJControl_Inpulse_500 1") -and $first.Contains("Other_MIDI_Device 1")) "Detected Hercules enabled; other controllers preserved"
    Assert-Rx3 ($first.Contains("ScaleFactor 0.8")) "Scale uses invariant decimal"
    Apply-MixxxProfile -ConfigPath $config -ProfilePath (Join-Path $PackageRoot "profile/XDJ_RX3_Mixxx.profile.cfg") -ControllerPresetPath $mapping -ControllerKeys $keys -InterfaceScale 0.8
    Assert-Rx3 ($first -eq [IO.File]::ReadAllText($config)) "Repeat install is idempotent"
    Assert-Rx3 ((Get-FileHash (Join-Path $backup "mixxx.cfg")).Hash -ne (Get-FileHash $config).Hash) "Original backup remains untouched"

    $effects = Join-Path $settings "effects.xml"
    '<Effects><QuickEffectPresetList><ChainPresetName>Réverbération personal</ChainPresetName><ChainPresetName>RX3 NOISE</ChainPresetName><ChainPresetName>RX3 REVERB</ChainPresetName><ChainPresetName>RX3 SPACE</ChainPresetName><ChainPresetName>RX3 DUB ECHO</ChainPresetName></QuickEffectPresetList><OtherNode value="keep"/></Effects>' | Set-Content $effects
    Set-Rx3QuickEffectOrder -EffectsConfig $effects
    Set-Rx3QuickEffectOrder -EffectsConfig $effects
    [xml]$xml = Get-Content $effects -Raw
    $order = @($xml.DocumentElement.QuickEffectPresetList.ChainPresetName)
    Assert-Rx3 (($order -join ',') -eq 'RX3 REVERB,RX3 PING PONG,RX3 NOISE,RX3 FILTER,Réverbération personal') "FX ordering preserves user presets without duplicates"
    Assert-Rx3 ($xml.DocumentElement.OtherNode.value -eq "keep") "Unrelated effects configuration preserved"

    # Stub process startup to verify custom profile paths without launching apps.
    function Start-Process { param($FilePath, $ArgumentList) $script:launch = @($FilePath, $ArgumentList) }
    Start-Rx3Mixxx -Executable "C:/Program Files/Mixxx/mixxx.exe" -SettingsPath "C:/Users/DJ Name/Mixxx RX3"
    Assert-Rx3 ($launch[1][0] -eq "--settings-path" -and $launch[1][1] -eq '"C:/Users/DJ Name/Mixxx RX3"') "Custom settings path is passed and quoted"

    $bad = Join-Path $testRoot "bad-package"
    New-Item -ItemType Directory -Path $bad | Out-Null
    [IO.File]::WriteAllText((Join-Path $bad "test.txt"), "original")
    $hash = (Get-FileHash (Join-Path $bad "test.txt") -Algorithm SHA256).Hash
    @{ files = @(@{ path="test.txt"; sha256=$hash }) } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $bad "payload-sha256.json")
    [IO.File]::WriteAllText((Join-Path $bad "test.txt"), "changed")
    $rejected = $false
    try { Test-Rx3Payload $bad } catch { $rejected = $true }
    Assert-Rx3 $rejected "Corrupted payload rejected"
    @{ files = @(@{ path="../outside.txt"; sha256=$hash }) } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $bad "payload-sha256.json")
    $rejected = $false
    try { Test-Rx3Payload $bad } catch { $rejected = $true }
    Assert-Rx3 $rejected "Manifest path traversal rejected"
    Write-Host "PASS: $count checks. Windows-only installation, MIDI enumeration and audio still require target-machine validation."
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
