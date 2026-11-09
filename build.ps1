[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$version = (Import-PowerShellDataFile "$PSScriptRoot/DownloadOrganizerPro.psd1").ModuleVersion
$distDir = Join-Path $PSScriptRoot 'dist'
[IO.Directory]::CreateDirectory($distDir) | Out-Null
$csc = "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path -LiteralPath $csc)) { $csc = "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319\csc.exe" }
if (-not (Test-Path -LiteralPath $csc)) { throw 'The .NET Framework C# compiler is unavailable.' }
$output = Join-Path $distDir ('launcher-' + [guid]::NewGuid().ToString('N') + '.exe')
$arguments = @('/target:winexe', '/optimize+', '/r:System.Windows.Forms.dll', "/out:$output")
$icon = Join-Path $PSScriptRoot 'assets/app.ico'
if (-not (Test-Path -LiteralPath $icon)) { $icon = Join-Path $PSScriptRoot 'assets/favicon.ico' }
if (Test-Path -LiteralPath $icon) { $arguments += "/win32icon:$icon" }
$arguments += Join-Path $PSScriptRoot 'assets/Launcher.cs'
& $csc $arguments
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $output -PathType Leaf) -or (Get-Item -LiteralPath $output).Length -eq 0) { throw 'C# compilation failed; previous executable was not replaced.' }
Move-Item -LiteralPath $output -Destination (Join-Path $distDir 'DownloadOrganizerPro.exe') -Force -ErrorAction Stop
foreach ($name in @('DownloadOrganizer.ps1', 'DownloadOrganizerPro.psd1', 'DownloadOrganizerPro.psm1', 'config.json')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $distDir $name) -Force -ErrorAction Stop
}
foreach ($name in @('modules', 'assets')) {
    $destination = Join-Path $distDir $name
    [IO.Directory]::CreateDirectory($destination) | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot $name) -File | Copy-Item -Destination $destination -Force -ErrorAction Stop
}
Set-Content -LiteralPath (Join-Path $distDir 'README.txt') -Encoding UTF8 -Value "Download Organizer Pro $version`r`nPortable package: keep the launcher, scripts, modules, assets, and config together.`r`nDouble-click the launcher for GUI, or pass -Silent, -DryRun, -Schedule, -Unschedule, or -ScheduleStatus.`r`nOverwrite backups and recovery journals live in logs/transactions."
Write-Host "Built Download Organizer Pro $version in $distDir"
