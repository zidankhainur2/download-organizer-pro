# ===========================================
# Download Organizer Pro — Executable Build Script
# ===========================================

[CmdletBinding()]
param(
    [switch]$SkipModuleInstall
)

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

$ProjectRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) { $PSScriptRoot } else { (Get-Location).Path }

Write-Host ""
Write-Host "========================================="
Write-Host "  BUILDING DOWNLOAD ORGANIZER PRO .EXE   "
Write-Host "========================================="
Write-Host ""

# Create Staging & Dist Directories
$distDir = Join-Path $ProjectRoot "dist"
if (-not (Test-Path -LiteralPath $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

$rootExe   = Join-Path $ProjectRoot "DownloadOrganizerPro.exe"
$outputExe = Join-Path $distDir "DownloadOrganizerPro.exe"
$iconPath  = Join-Path $ProjectRoot "assets\app.ico"
$configSrc = Join-Path $ProjectRoot "config.json"
$configDst = Join-Path $distDir "config.json"

# Copy external config.json to dist/
if (Test-Path -LiteralPath $configSrc) {
    Copy-Item -LiteralPath $configSrc -Destination $configDst -Force
    Write-Host "[BUILD] Copied config.json -> dist/config.json"
}

# Copy icon to dist/
if (Test-Path -LiteralPath $iconPath) {
    Copy-Item -LiteralPath $iconPath -Destination (Join-Path $distDir "app.ico") -Force
}

# Build README.txt for dist/
$readmeText = @"
=====================================================
DOWNLOAD ORGANIZER PRO v2.1 (Desktop Edition)
=====================================================

HOW TO RUN:
Double-click 'DownloadOrganizerPro.exe' to launch the Desktop GUI interface.

CONFIGURATION:
Edit 'config.json' in this folder to customize file categories,
extensions, and Smart Rules anytime without recompiling.

LOGS & REPORTS:
Execution logs and exported HTML/CSV reports will be saved
in the 'logs/' subfolder.
"@
Set-Content -Path (Join-Path $distDir "README.txt") -Value $readmeText -Encoding UTF8

Write-Host "[BUILD] Locating ps2exe compilation script..."

$ps2exeScript = Get-ChildItem -Path $env:USERPROFILE, $env:ProgramFiles -Filter "ps2exe.ps1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($null -eq $ps2exeScript -and -not $SkipModuleInstall) {
    Write-Host "[BUILD] Installing ps2exe module for CurrentUser..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction SilentlyContinue
    $ps2exeScript = Get-ChildItem -Path $env:USERPROFILE, $env:ProgramFiles -Filter "ps2exe.ps1" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}

if ($null -eq $ps2exeScript) {
    throw "Could not locate ps2exe.ps1 script. Please install ps2exe via: Install-Module ps2exe"
}

Write-Host "[BUILD] Found ps2exe script: $($ps2exeScript.FullName)"
Write-Host "[BUILD] Compiling DownloadOrganizer.ps1 -> DownloadOrganizerPro.exe..."

$inputFile = Join-Path $ProjectRoot "DownloadOrganizer.ps1"

if (Test-Path -LiteralPath $iconPath) {
    Write-Host "[BUILD] Compiling with custom icon: assets/app.ico"
    & $ps2exeScript.FullName $inputFile $rootExe -x64 -iconFile $iconPath -noConsole -title "Download Organizer Pro" -version "2.1.0.0" -copyright "Copyright (c) 2026 zidankhainur" -description "Professional Downloads Folder Organizer Desktop Edition" -product "Download Organizer Pro"
}
else {
    & $ps2exeScript.FullName $inputFile $rootExe -x64 -noConsole -title "Download Organizer Pro" -version "2.1.0.0" -copyright "Copyright (c) 2026 zidankhainur" -description "Professional Downloads Folder Organizer Desktop Edition" -product "Download Organizer Pro"
}

if (Test-Path -LiteralPath $rootExe) {
    Copy-Item -LiteralPath $rootExe -Destination $outputExe -Force
    Write-Host "[BUILD] Copied executable -> dist/DownloadOrganizerPro.exe"
}

Write-Host ""
Write-Host "========================================="
Write-Host " BUILD COMPLETED SUCCESSFULLY!"
Write-Host " Executable Output: $outputExe"
Write-Host "========================================="
Write-Host ""
