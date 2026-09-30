param(
    [Parameter(Mandatory = $true)][string]$Profile,
    [Parameter(Mandatory = $true)][string]$Template
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Set-ConfigValue {
    param([System.Collections.ArrayList]$Lines, [string]$Section, [string]$Key, [string]$Value)
    $header = '[' + $Section + ']'
    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -eq $header) { $start = $i; break }
    }
    if ($start -lt 0) {
        if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -ne '') { [void]$Lines.Add('') }
        [void]$Lines.Add($header)
        $start = $Lines.Count - 1
    }
    $end = $Lines.Count
    for ($i = $start + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\s*\[.+\]\s*$') { $end = $i; break }
    }
    $pattern = '^\s*' + [regex]::Escape($Key) + '(?:\s+|=)'
    for ($i = $start + 1; $i -lt $end; $i++) {
        if ($Lines[$i] -match $pattern) {
            $Lines[$i] = "$Key $Value"
            return
        }
    }
    $Lines.Insert($end, "$Key $Value")
}

try {
    New-Item -ItemType Directory -Path $Profile -Force | Out-Null
    $config = Join-Path $Profile 'mixxx.cfg'
    $lines = New-Object System.Collections.ArrayList
    if (Test-Path -LiteralPath $config -PathType Leaf) {
        foreach ($line in [IO.File]::ReadAllLines($config)) { [void]$lines.Add($line) }
        Copy-Item -LiteralPath $config -Destination ($config + '.previous') -Force
    }
    $section = ''
    foreach ($raw in [IO.File]::ReadAllLines($Template)) {
        $line = $raw.Trim()
        if (-not $line -or $line.StartsWith('#') -or $line.StartsWith(';')) { continue }
        if ($line.StartsWith('[') -and $line.EndsWith(']')) {
            $section = $line.Substring(1, $line.Length - 2)
            continue
        }
        $parts = $line -split '\s+', 2
        if (-not $section -or $parts.Count -ne 2) { throw "Invalid profile template line: $line" }
        Set-ConfigValue -Lines $lines -Section $section -Key $parts[0] -Value $parts[1]
    }
    $controller = (Join-Path $Profile 'controllers\Hercules_DJControl_Inpulse_500_RX3.midi.xml') -replace '\\', '/'
    Set-ConfigValue -Lines $lines -Section 'ControllerPreset' -Key 'DJControl_Inpulse_500' -Value $controller
    Set-ConfigValue -Lines $lines -Section 'Controller' -Key 'DJControl_Inpulse_500' -Value '1'
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
    [IO.File]::WriteAllLines(($config + '.tmp'), [string[]]$lines, $utf8)
    Move-Item -LiteralPath ($config + '.tmp') -Destination $config -Force

    $effects = Join-Path $Profile 'effects.xml'
    $xml = New-Object System.Xml.XmlDocument
    if (Test-Path -LiteralPath $effects -PathType Leaf) {
        Copy-Item -LiteralPath $effects -Destination ($effects + '.previous') -Force
        $xml.Load($effects)
    } else {
        [void]$xml.AppendChild($xml.CreateElement('Effects'))
    }
    $list = $xml.DocumentElement.SelectSingleNode('QuickEffectPresetList')
    if ($null -eq $list) {
        $list = $xml.CreateElement('QuickEffectPresetList')
        [void]$xml.DocumentElement.AppendChild($list)
    }
    $wanted = @('RX3 REVERB', 'RX3 PING PONG', 'RX3 NOISE', 'RX3 FILTER')
    foreach ($child in @($list.ChildNodes)) {
        if ($child.Name -eq 'ChainPresetName' -and
            ($wanted -contains $child.InnerText -or @('RX3 SPACE', 'RX3 DUB ECHO') -contains $child.InnerText)) {
            [void]$list.RemoveChild($child)
        }
    }
    for ($i = $wanted.Count - 1; $i -ge 0; $i--) {
        $node = $xml.CreateElement('ChainPresetName')
        $node.InnerText = $wanted[$i]
        [void]$list.PrependChild($node)
    }
    $writer = New-Object System.Xml.XmlWriterSettings
    $writer.Encoding = $utf8
    $writer.Indent = $true
    $stream = [System.Xml.XmlWriter]::Create(($effects + '.tmp'), $writer)
    try { $xml.Save($stream) } finally { $stream.Dispose() }
    Move-Item -LiteralPath ($effects + '.tmp') -Destination $effects -Force
    exit 0
} catch {
    Write-Error $_
    exit 1
}
