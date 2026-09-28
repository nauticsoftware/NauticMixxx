param([string]$UninstallerPath)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
if (-not $UninstallerPath) {
    $UninstallerPath = Join-Path $PSScriptRoot '../../packaging/windows/uninstall-nauticmixxx.ps1'
}
$tokens = $null
$errors = $null
[void][Management.Automation.Language.Parser]::ParseFile($UninstallerPath, [ref]$tokens, [ref]$errors)
if ($errors.Count -gt 0) { throw "Uninstaller PowerShell syntax errors: $errors" }
. $UninstallerPath

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('nautic-uninstaller-test-' + [guid]::NewGuid().ToString('N'))
$oldLocal = $env:LOCALAPPDATA
$oldTemp = $env:TEMP
$oldProgramFiles = $env:ProgramFiles
$checks = 0
function Assert-Uninstall($condition, $description) {
    if (-not $condition) { throw "FAIL: $description" }
    $script:checks++
}
try {
    $env:LOCALAPPDATA = Join-Path $testRoot 'AppData'
    $env:TEMP = Join-Path $testRoot 'Temp'
    $env:ProgramFiles = Join-Path $testRoot 'ProgramFiles'
    New-Item -ItemType Directory -Path $env:LOCALAPPDATA, $env:TEMP -Force | Out-Null
    $v1 = Join-Path $env:LOCALAPPDATA 'Programs/NauticMixxx/1.0.0'
    $v2 = Join-Path $env:LOCALAPPDATA 'Programs/NauticMixxx/2.0.0'
    New-Item -ItemType Directory -Path $v1, $v2 -Force | Out-Null
    'exe' | Set-Content -LiteralPath (Join-Path $v1 'mixxx.exe')
    'exe' | Set-Content -LiteralPath (Join-Path $v2 'mixxx.exe')
    $separate = Join-Path $env:LOCALAPPDATA 'Mixxx-RX3'
    New-Item -ItemType Directory -Path $separate -Force | Out-Null
    'library' | Set-Content -LiteralPath (Join-Path $separate 'mixxxdb.sqlite')
    $plan = @(Get-NauticRemovalPlan)
    Assert-Uninstall (@($plan | Where-Object { $_.Kind -eq 'Application' }).Count -eq 1) 'All native versions are covered by one owned application root'
    Assert-Uninstall (@($plan | Where-Object { $_.Kind -eq 'Data' -and $_.Path -eq $separate }).Count -eq 1) 'Separate profile is found'
    Assert-Uninstall ((Assert-OwnedApplicationPath $v1) -eq $v1) 'Version 1 path is allowed'
    $rejected = $false
    try { [void](Assert-OwnedApplicationPath $env:LOCALAPPDATA) } catch { $rejected = $true }
    Assert-Uninstall $rejected 'Unrelated profile root is rejected'
    $sharedApp = Join-Path $env:ProgramFiles 'Mixxx'
    New-Item -ItemType Directory -Path $sharedApp -Force | Out-Null
    '{"product":"NauticMixxx","version":"1.0.0"}' |
        Set-Content -LiteralPath (Join-Path $sharedApp 'rx3-build.json')
    Assert-Uninstall (@(Get-SharedNativeReplacements).Count -eq 1) 'Unsafe native replacement inside official Mixxx is detected'
    Remove-OwnedPath -Path (Join-Path $env:LOCALAPPDATA 'Programs/NauticMixxx') -Label 'test native versions'
    Assert-Uninstall (-not (Test-Path -LiteralPath $v1) -and -not (Test-Path -LiteralPath $v2)) 'Every native version was removed'

    $standard = Join-Path $env:LOCALAPPDATA 'Mixxx'
    $skin = Join-Path $standard 'skins/XDJ_RX3_Mixxx'
    $controllers = Join-Path $standard 'controllers'
    $chains = Join-Path $standard 'effects/chains'
    New-Item -ItemType Directory -Path $skin, $controllers, $chains -Force | Out-Null
    'skin' | Set-Content -LiteralPath (Join-Path $skin 'skin.xml')
    'map' | Set-Content -LiteralPath (Join-Path $controllers 'Hercules_DJControl_Inpulse_500_RX3.midi.xml')
    'shared' | Set-Content -LiteralPath (Join-Path $controllers 'midi-components-0.0.js')
    '<file filename="midi-components-0.0.js" />' |
        Set-Content -LiteralPath (Join-Path $controllers 'Other.midi.xml')
    'effect' | Set-Content -LiteralPath (Join-Path $chains 'RX3 NOISE.xml')
    'other' | Set-Content -LiteralPath (Join-Path $chains 'User Effect.xml')
    'library' | Set-Content -LiteralPath (Join-Path $standard 'mixxxdb.sqlite')
    @'
[Config]
ResizableSkin XDJ_RX3_Mixxx
Locale en_US
[ControllerPreset]
DJControl_Inpulse_500 C:/Users/DJ/Mixxx/controllers/Hercules_DJControl_Inpulse_500_RX3.midi.xml
OtherDevice C:/other.xml
[Controller]
DJControl_Inpulse_500 1
OtherDevice 1
'@ | Set-Content -LiteralPath (Join-Path $standard 'mixxx.cfg')
    '<Effects><QuickEffectPresetList><ChainPresetName>RX3 NOISE</ChainPresetName><ChainPresetName>User Effect</ChainPresetName></QuickEffectPresetList></Effects>' |
        Set-Content -LiteralPath (Join-Path $standard 'effects.xml')
    Assert-Uninstall (Test-Rx3StandardProfile $standard) 'RX3 components in shared profile detected'
    Remove-Rx3StandardProfile $standard
    Assert-Uninstall (-not (Test-Path -LiteralPath $skin)) 'RX3 skin removed from shared profile'
    Assert-Uninstall (-not (Test-Path -LiteralPath (Join-Path $controllers 'Hercules_DJControl_Inpulse_500_RX3.midi.xml'))) 'RX3 mapping removed'
    Assert-Uninstall (Test-Path -LiteralPath (Join-Path $controllers 'midi-components-0.0.js')) 'Shared mapping library retained'
    Assert-Uninstall (Test-Path -LiteralPath (Join-Path $standard 'mixxxdb.sqlite')) 'Mixxx library retained'
    Assert-Uninstall (Test-Path -LiteralPath (Join-Path $chains 'User Effect.xml')) 'User effect retained'
    $config = Get-Content -LiteralPath (Join-Path $standard 'mixxx.cfg') -Raw
    Assert-Uninstall ($config -match 'Locale en_US' -and $config -match 'OtherDevice 1' -and
        $config -notmatch 'XDJ_RX3_Mixxx|Hercules_DJControl_Inpulse_500_RX3|DJControl_Inpulse_500 1') 'Only RX3 config references removed'
    $effect = Get-Content -LiteralPath (Join-Path $standard 'effects.xml') -Raw
    Assert-Uninstall ($effect -match 'User Effect' -and $effect -notmatch 'RX3 NOISE') 'Only RX3 effect reference removed'
    Assert-Uninstall (-not (Test-Rx3StandardProfile $standard)) 'Shared profile no longer contains RX3 footprint'
    Remove-Item -LiteralPath (Join-Path $controllers 'Other.midi.xml')
    Remove-Rx3StandardProfile $standard
    Assert-Uninstall (-not (Test-Path -LiteralPath (Join-Path $controllers 'midi-components-0.0.js'))) 'Unused RX3 mapping library removed'
    Write-Host "PASS: $checks NauticMixxx uninstaller checks."
}
finally {
    $env:LOCALAPPDATA = $oldLocal
    $env:TEMP = $oldTemp
    $env:ProgramFiles = $oldProgramFiles
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
