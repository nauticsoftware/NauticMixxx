param(
    [string]$WorkRoot = 'C:\rx3-build',
    [ValidateRange(1, 32)][int]$Jobs = 4
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0
$projectRoot = Split-Path -Parent $PSScriptRoot

function Invoke-Checked {
    param([string]$File, [string[]]$Arguments)
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$File termino con codigo $LASTEXITCODE" }
}

function Get-VerifiedDownload {
    param([string]$Url, [string]$Path, [string]$Sha256)
    if (-not (Test-Path -LiteralPath $Path)) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Host "Descargando $Url"
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile ($Path + '.partial')
        if ((Get-FileHash -LiteralPath ($Path + '.partial') -Algorithm SHA256).Hash -ne $Sha256) {
            throw "SHA-256 incorrecto: $Url"
        }
        Move-Item -LiteralPath ($Path + '.partial') -Destination $Path -Force
    }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Sha256) { throw "Cache corrupta: $Path" }
}

try {
    if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitOperatingSystem -or
        $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        throw 'La compilacion requiere Windows x64 Intel/AMD.'
    }
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path $vswhere)) {
        throw 'Instala Visual Studio Build Tools 2022 con Desarrollo para escritorio con C++, CMake y Windows SDK. Consulta EMPEZAR-COMPILACION.txt.'
    }
    $vs = & $vswhere -latest -products '*' -version '[17.0,18.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { throw 'No se encontro Visual Studio 2022 con herramientas C++ x64.' }
    Import-Module (Join-Path $vs 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
    Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'
    $cmakeTools = Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake'
    $env:PATH = (Join-Path $cmakeTools 'CMake\bin') + ';' + (Join-Path $cmakeTools 'Ninja') + ';' + $env:PATH
    foreach ($command in @('cmake', 'ninja', 'git', 'python', 'tar')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Falta $command. Consulta EMPEZAR-COMPILACION.txt." }
    }
    Invoke-Checked -File python -Arguments @('--version')
    $WorkRoot = [IO.Path]::GetFullPath($WorkRoot)
    New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null
    $sourceArchive = Join-Path $WorkRoot 'mixxx-2.5.6.tar.gz'
    Get-VerifiedDownload -Url 'https://github.com/mixxxdj/mixxx/archive/refs/tags/2.5.6.tar.gz' -Path $sourceArchive `
        -Sha256 '9cfc9025d50d2511767ee52a07b8854f75c581f0585197d043bc219fcf9f9050'
    $depsName = 'mixxx-deps-2.5-x64-windows-release-40c29ff'
    $depsArchive = Join-Path $WorkRoot ($depsName + '.zip')
    Get-VerifiedDownload -Url ("https://downloads.mixxx.org/dependencies/2.5-rel/Windows/$depsName.zip") -Path $depsArchive `
        -Sha256 'a9d809ae9c52d8a553af1bb8a58565649ced7b1f938d1d37c1c7d83ad53aacf3'
    $depsRoot = Join-Path $WorkRoot 'buildenv'
    $deps = Join-Path $depsRoot $depsName
    if (-not (Test-Path (Join-Path $deps '.rx3-extracted'))) {
        if (Test-Path $deps) { throw 'Extraccion de dependencias incompleta. Mueve buildenv a otra carpeta antes de reintentar.' }
        New-Item -ItemType Directory -Path $depsRoot -Force | Out-Null
        Invoke-Checked -File tar -Arguments @('-xf', $depsArchive, '-C', $depsRoot)
        if (-not (Test-Path (Join-Path $deps 'installed\x64-windows-release\bin\Qt6Core.dll'))) { throw 'Dependencias incompletas.' }
        Set-Content -LiteralPath (Join-Path $deps '.rx3-extracted') -Value $depsName
    }
    $source = Join-Path $WorkRoot 'mixxx-2.5.6'
    $patches = @(Get-ChildItem (Join-Path $projectRoot 'patches\00[0-9][0-9]-*.patch') | Sort-Object Name)
    if ($patches.Count -ne 10) { throw 'Falta alguno de los diez parches NauticMixxx.' }
    $patchState = ($patches | ForEach-Object { (Get-FileHash $_.FullName -Algorithm SHA256).Hash }) -join ','
    if (-not (Test-Path $source)) {
        Invoke-Checked -File tar -Arguments @('-xzf', $sourceArchive, '-C', $WorkRoot)
        Push-Location $source
        try {
            foreach ($patch in $patches) { Invoke-Checked -File git -Arguments @('apply', '--whitespace=error', $patch.FullName) }
        } finally { Pop-Location }
        Set-Content -LiteralPath (Join-Path $source '.rx3-patched') -Value $patchState
    }
    $marker = Join-Path $source '.rx3-patched'
    if (-not (Test-Path $marker) -or (Get-Content $marker -Raw).Trim() -ne $patchState) {
        throw 'Los fuentes en cache no coinciden con estos parches. Usa otro WorkRoot.'
    }
    $windowsIcon = Join-Path $source 'res\images\icons\ic_mixxx.ico'
    Invoke-Checked -File python -Arguments @((Join-Path $PSScriptRoot 'build-app-icon-windows.py'), $windowsIcon)
    $resourceFile = Join-Path $source 'src\mixxx.rc'
    $resourceText = [IO.File]::ReadAllText($resourceFile)
    $resourceText = $resourceText.Replace('#define VER_PRODUCTNAME_STR         "Mixxx\0"', '#define VER_PRODUCTNAME_STR         "NauticMixxx\0"')
    $resourceText = $resourceText.Replace('#define VER_FILEDESCRIPTION_STR     "Mixxx digital DJ software"', '#define VER_FILEDESCRIPTION_STR     "NauticMixxx digital DJ software"')
    $resourceText = $resourceText.Replace('#define VER_COMPANYNAME_STR         "The Mixxx Development Team"', '#define VER_COMPANYNAME_STR         "NauticMixxx contributors and Mixxx Development Team"')
    $utf8WithoutBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false
    [IO.File]::WriteAllText($resourceFile, $resourceText, $utf8WithoutBom)
    $build = Join-Path $WorkRoot 'build'
    $stage = Join-Path $WorkRoot ('stage-' + (Get-Date -Format 'yyyyMMdd-HHmmssfff'))
    $env:MIXXX_VCPKG_ROOT = $deps
    Invoke-Checked -File cmake -Arguments @('-S', $source, '-B', $build, '-G', 'Ninja',
        '-DCMAKE_BUILD_TYPE=Release', '-DCMAKE_POLICY_VERSION_MINIMUM=3.5', "-DMIXXX_VCPKG_ROOT=$deps",
        '-DVCPKG_TARGET_TRIPLET=x64-windows-release', '-DQT6=ON', '-DQML=OFF', '-DAU_EFFECTS=OFF',
        '-DBUILD_TESTING=ON', '-DBUILD_BENCH=OFF', '-DOPTIMIZE=portable', '-DDEBUG_ASSERTIONS_FATAL=OFF',
        '-DBULK=ON', '-DFFMPEG=OFF', '-DHSS1394=ON', '-DLOCALECOMPARE=ON', '-DMAD=ON',
        '-DMEDIAFOUNDATION=ON', '-DMODPLUG=ON', '-DWAVPACK=ON', '-DDOWNLOAD_MANUAL=OFF')
    Invoke-Checked -File cmake -Arguments @('--build', $build, '--target', 'mixxx', 'mixxx-test', '--parallel', "$Jobs")
    $env:QT_QPA_PLATFORM = 'offscreen'
    $env:PATH = (Join-Path $deps 'installed\x64-windows-release\bin') + ';' + $env:PATH
    $testXml = Join-Path $build 'rx3-tests.xml'
    Push-Location $build
    try {
        Invoke-Checked -File (Join-Path $build 'mixxx-test.exe') -Arguments @(
            '--gtest_filter=Rx3*:BeatGridTest.*:BeatMapTest.*:BeatsTest.*:CueTest.*:CueControlTest.*:WPushButtonTest.*',
            "--gtest_output=xml:$testXml")
    } finally { Pop-Location }
    Invoke-Checked -File cmake -Arguments @('--install', $build, '--prefix', $stage)
    Copy-Item -LiteralPath (Join-Path $projectRoot 'skins\XDJ_RX3_Mixxx') -Destination (Join-Path $stage 'skins') -Recurse -Force
    Copy-Item -LiteralPath $testXml -Destination (Join-Path $stage 'rx3-tests.xml')
    $info = @{ version = '1.0.0'; product = 'NauticMixxx'; platform = 'windows-x64'; baseMixxxVersion = '2.5.6'; testsPassed = $true; patches = $patchState;
        executableSha256 = (Get-FileHash (Join-Path $stage 'mixxx.exe') -Algorithm SHA256).Hash.ToLowerInvariant() }
    $info | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stage 'rx3-build.json') -Encoding UTF8
    Invoke-Checked -File python -Arguments @((Join-Path $PSScriptRoot 'package-rx3-windows-native.py'), '--runtime', $stage, '--source', $source)
    Write-Host 'ZIP nativo NauticMixxx generado en build.' -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
