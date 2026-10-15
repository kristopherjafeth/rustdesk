<#
  Compila el cliente JimkaSoporte (RustDesk con marca Jimka Offshore) en un PC Windows.
  No usa GitHub Actions.

  Requisitos: Windows 10/11 x64, PowerShell como Administrador, ~60 GB libres, 16 GB RAM,
  internet. La primera vez tarda 1-3 horas (instala herramientas y compila dependencias).

  Uso (PowerShell como Administrador):
    Set-ExecutionPolicy -Scope Process Bypass -Force
    irm https://github.com/kristopherjafeth/rustdesk/raw/jimka/jimka/build-windows.ps1 -OutFile build-windows.ps1
    .\build-windows.ps1

  Resultado: C:\jimka-build\salida\JimkaSoporte-<version>-install.exe
#>
param(
  [string]$Root = "C:\jimka-build",
  [string]$Repo = "https://github.com/kristopherjafeth/rustdesk.git",
  [string]$Branch = "jimka"
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Versiones que usa el CI oficial de RustDesk (.github/workflows/flutter-build.yml / bridge.yml)
$RUST_VERSION    = "1.75"
$FLUTTER_VERSION = "3.24.5"
$LLVM_VERSION    = "15.0.6"
$VCPKG_COMMIT    = "9e593bb18ea69cc5095e012465dcd675a822ed0d"
$FRB_VERSION     = "1.80.1"
$EXPAND_VERSION  = "1.0.95"
$TRIPLET         = "x64-windows-static"

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Have($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function RefreshPath {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path", "User") + ";" +
              "$env:USERPROFILE\.cargo\bin;$Root\flutter\bin;C:\Program Files\LLVM\bin"
}
function Run($exe, [string[]]$argv) {
  & $exe @argv
  if ($LASTEXITCODE -ne 0) { throw "Fallo: $exe $($argv -join ' ')" }
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw "Abre PowerShell como Administrador."
}
New-Item -ItemType Directory -Force -Path $Root, "$Root\salida" | Out-Null
Set-Location $Root

Step "1/9 Herramientas base (Git, Python, Visual Studio Build Tools)"
if (-not (Have winget)) { throw "Falta winget (App Installer de Microsoft Store)." }
if (-not (Have git)) { winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements --silent }
$pyOk = $false
try { $pyOk = ((& python --version 2>&1) -match "Python 3") } catch {}
if (-not $pyOk) { winget install -e --id Python.Python.3.11 --scope machine --accept-source-agreements --accept-package-agreements --silent }
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$hasVC = (Test-Path $vswhere) -and (& $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)
if (-not $hasVC) {
  winget install -e --id Microsoft.VisualStudio.2022.BuildTools --accept-source-agreements --accept-package-agreements --silent `
    --override "--wait --quiet --norestart --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --includeRecommended"
}
RefreshPath
# build.py llama a python3/pip3: se evita el alias de Microsoft Store y se crea python3.exe
$pyExe = Get-ChildItem "$env:ProgramFiles\Python3*\python.exe", "$env:LOCALAPPDATA\Programs\Python\Python3*\python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $pyExe) { throw "No se encontro Python 3 instalado." }
$pyDir = $pyExe.DirectoryName
if (-not (Test-Path "$pyDir\python3.exe")) { Copy-Item $pyExe.FullName "$pyDir\python3.exe" }
function PrependPyPath { $env:Path = "$pyDir;$pyDir\Scripts;" + $env:Path }
PrependPyPath

Step "2/9 LLVM $LLVM_VERSION"
if (-not (Test-Path "C:\Program Files\LLVM\bin\clang.exe")) {
  $llvm = "$Root\LLVM-$LLVM_VERSION-win64.exe"
  Invoke-WebRequest "https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VERSION/LLVM-$LLVM_VERSION-win64.exe" -OutFile $llvm
  Start-Process $llvm -ArgumentList "/S" -Wait
}
$env:LIBCLANG_PATH = "C:\Program Files\LLVM\bin"

Step "3/9 Rust $RUST_VERSION"
if (-not (Have rustup)) {
  Invoke-WebRequest "https://win.rustup.rs/x86_64" -OutFile "$Root\rustup-init.exe"
  Run "$Root\rustup-init.exe" @("-y", "--default-toolchain", $RUST_VERSION, "--profile", "minimal")
}
RefreshPath; PrependPyPath
Run rustup @("toolchain", "install", $RUST_VERSION, "--profile", "minimal", "--component", "rustfmt")
Run rustup @("default", $RUST_VERSION)

Step "4/9 Flutter $FLUTTER_VERSION"
if (-not (Test-Path "$Root\flutter\bin\flutter.bat")) {
  Run git @("clone", "--depth", "1", "-b", $FLUTTER_VERSION, "https://github.com/flutter/flutter.git", "$Root\flutter")
}
RefreshPath; PrependPyPath
Run flutter @("config", "--enable-windows-desktop", "--no-analytics")
Run flutter @("precache", "--windows")

Step "5/9 Codigo fuente (rama $Branch)"
if (-not (Test-Path "$Root\rustdesk\.git")) {
  Run git @("clone", "--recursive", "-b", $Branch, $Repo, "$Root\rustdesk")
} else {
  Push-Location "$Root\rustdesk"
  Run git @("fetch", "origin", $Branch); Run git @("reset", "--hard", "origin/$Branch")
  Run git @("submodule", "update", "--init", "--recursive", "--force")
  Pop-Location
}
Set-Location "$Root\rustdesk"
Push-Location (Split-Path (Split-Path (Get-Command flutter).Source))
git apply --check "$Root\rustdesk\.github\patches\flutter_3.24.4_dropdown_menu_enableFilter.diff" 2>$null
if ($LASTEXITCODE -eq 0) { Run git @("apply", "$Root\rustdesk\.github\patches\flutter_3.24.4_dropdown_menu_enableFilter.diff") }
Pop-Location

Step "6/9 Branding Jimka"
Run python @("jimka\apply_branding.py", ".")

Step "7/9 vcpkg y dependencias C (la primera vez tarda bastante)"
$env:VCPKG_ROOT = "$Root\vcpkg"
if (-not (Test-Path "$env:VCPKG_ROOT\vcpkg.exe")) {
  Run git @("clone", "https://github.com/microsoft/vcpkg.git", $env:VCPKG_ROOT)
  Push-Location $env:VCPKG_ROOT; Run git @("checkout", $VCPKG_COMMIT); Run ".\bootstrap-vcpkg.bat" @("-disableMetrics"); Pop-Location
}
$env:VCPKG_DEFAULT_HOST_TRIPLET = $TRIPLET
Run "$env:VCPKG_ROOT\vcpkg.exe" @("install", "--triplet", $TRIPLET, "--x-install-root=$env:VCPKG_ROOT\installed")

Step "8/9 Puente Flutter <-> Rust"
if (-not (Have flutter_rust_bridge_codegen)) {
  Run cargo @("install", "cargo-expand", "--version", $EXPAND_VERSION, "--locked")
  Run cargo @("install", "flutter_rust_bridge_codegen", "--version", $FRB_VERSION, "--features", "uuid", "--locked")
}
Push-Location flutter; Run flutter @("pub", "get"); Pop-Location
Run flutter_rust_bridge_codegen @("--rust-input", ".\src\flutter_ffi.rs", "--dart-output", ".\flutter\lib\generated_bridge.dart", "--c-output", ".\flutter\macos\Runner\bridge_generated.h")

Step "9/9 Compilando JimkaSoporte"
Run python @("-m", "pip", "install", "-r", "libs\portable\requirements.txt")
Run python @(".\build.py", "--portable", "--flutter", "--hwcodec", "--vram")
$out = Get-ChildItem -Path . -Filter "rustdesk-*-install.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $out) { throw "No se encontro el instalador generado." }
$dest = "$Root\salida\" + ($out.Name -replace '^rustdesk', 'JimkaSoporte')
Copy-Item $out.FullName $dest -Force
Write-Host "`nListo: $dest" -ForegroundColor Green
