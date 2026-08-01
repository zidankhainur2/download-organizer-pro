# ===========================================
# Download Organizer Pro - Native Build Script
# ===========================================

[CmdletBinding()]
param()

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

$outputExe = Join-Path $distDir "DownloadOrganizerPro.exe"
$iconPath  = Join-Path $ProjectRoot "assets\app.ico"
if (-not (Test-Path -LiteralPath $iconPath)) {
    $iconPath = Join-Path $ProjectRoot "assets\favicon.ico"
}
$configSrc = Join-Path $ProjectRoot "config.json"
$configDst = Join-Path $distDir "config.json"
$ps1Src    = Join-Path $ProjectRoot "DownloadOrganizer.ps1"
$ps1Dst    = Join-Path $distDir "DownloadOrganizer.ps1"

# Copy DownloadOrganizer.ps1 to dist/
if (Test-Path -LiteralPath $ps1Src) {
    Copy-Item -LiteralPath $ps1Src -Destination $ps1Dst -Force
    Write-Host "[BUILD] Copied DownloadOrganizer.ps1 -> dist/DownloadOrganizer.ps1"
}

# Copy external config.json to dist/
if (Test-Path -LiteralPath $configSrc) {
    Copy-Item -LiteralPath $configSrc -Destination $configDst -Force
    Write-Host "[BUILD] Copied config.json -> dist/config.json"
}

# Copy modules folder to dist/
$modulesSrc = Join-Path $ProjectRoot "modules"
$modulesDst = Join-Path $distDir "modules"
if (Test-Path -LiteralPath $modulesSrc) {
    Copy-Item -LiteralPath $modulesSrc -Destination $modulesDst -Recurse -Force
    Write-Host "[BUILD] Copied modules/ -> dist/modules/"
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

Write-Host "[BUILD] Locating Native C# Compiler (csc.exe)..."

$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path -LiteralPath $cscPath)) {
    $cscPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

if (-not (Test-Path -LiteralPath $cscPath)) {
    throw "Native C# Compiler (csc.exe) not found on system."
}

Write-Host "[BUILD] Found C# Compiler: $cscPath"

# Generate C# Single-Instance Mutex Launcher Code using raw single-quoted string
$csSource = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Windows.Forms;

class Program {
    private static Mutex appMutex;

    [STAThread]
    static void Main() {
        bool createdNew;
        appMutex = new Mutex(true, "Global\\DownloadOrganizerPro_SingleInstance_Mutex_2026", out createdNew);

        if (!createdNew) {
            return;
        }

        try {
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string scriptPath = Path.Combine(baseDir, "DownloadOrganizer.ps1");
            if (!File.Exists(scriptPath)) {
                DirectoryInfo parent = Directory.GetParent(baseDir);
                if (parent != null) {
                    string pPath = Path.Combine(parent.FullName, "DownloadOrganizer.ps1");
                    if (File.Exists(pPath)) {
                        scriptPath = pPath;
                    }
                }
            }

            if (!File.Exists(scriptPath)) {
                MessageBox.Show("Could not locate DownloadOrganizer.ps1 script at:\n" + scriptPath, "Download Organizer Pro", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = "powershell.exe";
            psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + scriptPath + "\" -GUI";
            psi.WindowStyle = ProcessWindowStyle.Hidden;
            psi.CreateNoWindow = true;
            psi.UseShellExecute = false;

            Process proc = Process.Start(psi);
            if (proc != null) {
                proc.WaitForExit();
            }
        }
        catch (Exception ex) {
            MessageBox.Show("Launcher error: " + ex.Message, "Download Organizer Pro Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally {
            if (appMutex != null) {
                appMutex.ReleaseMutex();
            }
        }
    }
}
'@

$tempCs = Join-Path $distDir "Launcher.cs"
Set-Content -Path $tempCs -Value $csSource -Encoding UTF8

Write-Host "[BUILD] Compiling Native Single-Instance Win32 Executable -> dist/DownloadOrganizerPro.exe..."

$cscArgs = @("/target:winexe", "/optimize+", "/r:System.Windows.Forms.dll", "/out:$outputExe")

if (Test-Path -LiteralPath $iconPath) {
    $cscArgs += "/win32icon:$iconPath"
    Write-Host "[BUILD] Embedded custom Win32 icon: assets/app.ico"
}

$cscArgs += $tempCs

& $cscPath $cscArgs | Out-Null

Remove-Item -LiteralPath $tempCs -Force -ErrorAction SilentlyContinue

if (Test-Path -LiteralPath $outputExe) {
    Write-Host "[BUILD] Verified compilation output: dist/DownloadOrganizerPro.exe"
}
else {
    throw "Build failed: Executable dist/DownloadOrganizerPro.exe was not created."
}

Write-Host ""
Write-Host "========================================="
Write-Host " BUILD COMPLETED SUCCESSFULLY!"
Write-Host " Executable Output: $outputExe"
Write-Host "========================================="
Write-Host ""
