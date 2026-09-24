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
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $root = [IO.Path]::GetFullPath($PackageRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    foreach ($entry in $manifest.files) {
        $path = [IO.Path]::GetFullPath((Join-Path $root $entry.path))
        if (-not $path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw "Ruta invalida en el paquete." }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Paquete incompleto: $($entry.path)" }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.sha256) {
            throw "El archivo $($entry.path) no coincide con el paquete original. Extrae de nuevo el ZIP."
        }
    }
}

function Start-Rx3Mixxx {
    param([string]$Executable, [string]$SettingsPath)
    # Start-Process joins ArgumentList: quote paths explicitly, including spaces.
    if ($SettingsPath.Contains('"')) { throw "Ruta de configuracion invalida." }
    Start-Process -FilePath $Executable -ArgumentList @("--settings-path", ('"' + $SettingsPath + '"')) | Out-Null
}

function Find-MixxxExecutable {
    $candidates = @()

    if ($env:ProgramFiles) {
        $candidates += Join-Path $env:ProgramFiles "Mixxx\mixxx.exe"
    }
    if (${env:ProgramFiles(x86)}) {
        $candidates += Join-Path ${env:ProgramFiles(x86)} "Mixxx\mixxx.exe"
    }
    if ($env:LOCALAPPDATA) {
        $candidates += Join-Path $env:LOCALAPPDATA "Programs\Mixxx\mixxx.exe"
    }

    foreach ($registryRoot in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
        if (Test-Path $registryRoot) {
            foreach ($entry in Get-ChildItem $registryRoot) {
                $values = Get-ItemProperty $entry.PSPath
                if ($values.PSObject.Properties["DisplayName"] -and $values.DisplayName -match "^Mixxx(?: |$)" -and $values.PSObject.Properties["InstallLocation"] -and $values.InstallLocation) {
                    $candidates += Join-Path $values.InstallLocation "mixxx.exe"
                }
            }
        }
    }

    $command = Get-Command "mixxx.exe" -ErrorAction SilentlyContinue
    if ($command) {
        $candidates += $command.Source
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return $candidate
        }
    }
    return $null
}

function Install-OfficialMixxx {
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "Mixxx 2.5.6 y este paquete requieren Windows de 64 bits."
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
            Write-Step "Reutilizando una descarga oficial ya verificada"
        }
        else {
            Remove-Item -LiteralPath $installerPath -Force
        }
    }

    if ($downloadRequired) {
        Write-Step "Mixxx no esta instalado; descargando Mixxx $mixxxVersion oficial"
        Write-Host "Origen: $downloadUrl"
        Write-Host "Tamano aproximado: 115 MB. Esto puede tardar unos minutos." -ForegroundColor Yellow

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try {
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $downloadUrl -Destination $installerPath -DisplayName "Mixxx $mixxxVersion" -Description "Descarga oficial para XDJ-RX3"
        }
        catch {
            Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -OutFile $installerPath
        }
    }

    $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
        throw "La comprobacion SHA-256 del instalador de Mixxx fallo. No se ejecuto ningun archivo."
    }

    $signature = Get-AuthenticodeSignature -LiteralPath $installerPath
    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
        throw "La firma digital del instalador oficial de Mixxx no es valida: $($signature.Status)."
    }

    Write-Step "Instalando Mixxx $mixxxVersion"
    $msiArguments = @("/i", "`"$installerPath`"", "/passive", "/norestart")
    $installerProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArguments -Verb RunAs -Wait -PassThru
    if ($installerProcess.ExitCode -notin @(0, 3010)) {
        throw "El instalador de Mixxx termino con el codigo $($installerProcess.ExitCode)."
    }

    if ($installerProcess.ExitCode -eq 3010) { Write-Host "Windows solicita reiniciar despues de la instalacion." -ForegroundColor Yellow }
    $mixxxExecutable = Find-MixxxExecutable
    if (-not $mixxxExecutable) {
        throw "Mixxx se instalo, pero no se encontro mixxx.exe en una ruta estandar."
    }

    Write-Host "Mixxx $mixxxVersion fue instalado correctamente." -ForegroundColor Green
    return $mixxxExecutable
}

function Stop-RunningMixxx {
    $processes = @(Get-Process -Name "mixxx" -ErrorAction SilentlyContinue)
    if ($processes.Count -eq 0) { return }
    Write-Host "Cierra Mixxx para continuar; no se forzara su cierre." -ForegroundColor Yellow
    [void](Read-Host "Pulsa ENTER cuando Mixxx este cerrado")
    if (@(Get-Process -Name "mixxx" -ErrorAction SilentlyContinue).Count -gt 0) {
        throw "Mixxx sigue abierto. Cierra la aplicacion y repite la instalacion."
    }
}

function Backup-MixxxSettings {
    param([string]$SettingsPath)

    $settingsParent = Split-Path -Parent $SettingsPath
    if (-not $settingsParent) {
        throw "No se pudo determinar una ubicacion externa para el respaldo de Mixxx."
    }

    $backupParent = Join-Path $settingsParent "Mixxx-XDJ-RX3-Backups"
    $backupRoot = Join-Path $backupParent ("Mixxx-antes-de-XDJ-RX3-" + (Get-Date -Format "yyyyMMdd-HHmmssfff"))

    Write-Step "Respaldando todas las settings de Mixxx en $backupRoot"
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
        throw "No se encontro mixxx.cfg para aplicar el perfil RX3."
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
            throw "El perfil RX3 contiene un valor fuera de una seccion: $line"
        }

        $parts = $line -split "\s+", 2
        if ($parts.Count -ne 2) {
            throw "El perfil RX3 contiene una linea invalida: $line"
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
        throw "No se pudo activar la skin XDJ-RX3 en mixxx.cfg."
    }
    foreach ($deviceKey in $ControllerKeys) {
        if ($savedConfig -notmatch ("(?m)^" + [regex]::Escape($deviceKey) + "\s+1\s*$")) {
            throw "No se pudo activar el controlador $deviceKey en mixxx.cfg."
        }
    }
}

function Set-Rx3QuickEffectOrder {
    param([string]$EffectsConfig)

    [xml]$effectsDocument = [System.IO.File]::ReadAllText($EffectsConfig)
    $root = $effectsDocument.DocumentElement
    if (-not $root) {
        throw "effects.xml no contiene un documento XML valido."
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
