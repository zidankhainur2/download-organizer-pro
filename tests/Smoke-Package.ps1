[CmdletBinding()]
param([string]$PackagePath = '')
$ErrorActionPreference = 'Stop'
if (-not $PackagePath) { $PackagePath = Join-Path $PSScriptRoot '../dist' }
Import-Module "$PSScriptRoot/../modules/Utils.psm1"
$parent = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../.tools/package-smoke'))
$root = Join-Path $parent ([guid]::NewGuid().ToString('N') + ' spaces & [1]')
[IO.Directory]::CreateDirectory($root) | Out-Null
try {
    if ([IO.Path]::GetExtension($PackagePath) -eq '.zip') {
        $version = (Import-PowerShellDataFile "$PSScriptRoot/../DownloadOrganizerPro.psd1").ModuleVersion
        $packageName = "DownloadOrganizerPro-$version-portable"
        $PackagePath = [IO.Path]::GetFullPath($PackagePath)
        $checksum = (Get-Content -LiteralPath ($PackagePath + '.sha256') -Raw).Trim()
        $actualHash = (Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash
        if ($checksum -cne "$actualHash  $([IO.Path]::GetFileName($PackagePath))") { throw 'Release ZIP checksum mismatch.' }
        $manifest = Get-Content -LiteralPath (Join-Path ([IO.Path]::GetDirectoryName($PackagePath)) "DownloadOrganizerPro-$version-release.json") -Raw | ConvertFrom-Json
        if ($manifest.Version -ne $version -or $manifest.SHA256 -ne $actualHash -or $manifest.Archive -cne [IO.Path]::GetFileName($PackagePath)) { throw 'Release manifest does not describe this ZIP.' }
        $allowed = @('DownloadOrganizerPro.exe','DownloadOrganizer.ps1','DownloadOrganizerPro.psd1','DownloadOrganizerPro.psm1','config.json','assets/OrganizerWindow.xaml','LICENSE','CHANGELOG.md','README.txt','RELEASE_NOTES.md')
        $allowed += @(Get-ChildItem -LiteralPath "$PSScriptRoot/../modules" -Filter '*.psm1' -File | ForEach-Object { 'modules/' + $_.Name })
        $expected = @($allowed | ForEach-Object { $packageName + '/' + $_ } | Sort-Object)
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($PackagePath)
        try {
            $entries = @($zip.Entries | ForEach-Object { $_.FullName.Replace('\','/') })
            $directories = @($entries | Where-Object { $_.EndsWith('/') })
            if (@($directories | Where-Object { $_ -notin @("$packageName/","$packageName/modules/","$packageName/assets/") }).Count) { throw 'Unexpected directory in release ZIP.' }
            $files = @($entries | Where-Object { -not $_.EndsWith('/') } | Sort-Object)
            if (($files -join "`n") -cne ($expected -join "`n")) { throw 'Unexpected or missing file in release ZIP.' }
        }
        finally { $zip.Dispose() }
        if ((($manifest.Files.Path | Sort-Object) -join "`n") -cne ($expected -join "`n")) { throw 'Release payload manifest has unexpected or missing files.' }
        $extracted = Join-Path $root 'extracted'
        Expand-Archive -LiteralPath $PackagePath -DestinationPath $extracted
        foreach ($file in $manifest.Files) {
            $path = Join-Path $extracted $file.Path
            if ((Get-Item -LiteralPath $path).Length -ne $file.Bytes -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.SHA256) { throw "Release payload changed: $($file.Path)" }
        }
        $sourcePaths = @($allowed | Where-Object { $_ -notin @('DownloadOrganizerPro.exe','README.txt','RELEASE_NOTES.md') })
        $sourcePaths += @("docs/RELEASE_NOTES_$version.md",'assets/Launcher.cs','build.ps1','package.ps1')
        $sourcePaths += @('assets/app.ico','assets/favicon.ico' | Where-Object { Test-Path -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) $_) })
        if ((($manifest.SourceFiles.Path | Sort-Object) -join "`n") -cne (($sourcePaths | Sort-Object) -join "`n")) { throw 'Unexpected or missing release source path.' }
        foreach ($source in $manifest.SourceFiles) {
            if ((Get-FileHash -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) $source.Path) -Algorithm SHA256).Hash -ne $source.SHA256) { throw "Release source changed: $($source.Path)" }
        }
        $PackagePath = Join-Path $extracted $packageName
        Write-Host "Release ZIP verified: checksum, clean payload, source hashes and $($files.Count) extracted files."
    }
    foreach ($name in @('DownloadOrganizerPro.exe', 'DownloadOrganizer.ps1', 'DownloadOrganizerPro.psd1', 'DownloadOrganizerPro.psm1', 'config.json', 'modules', 'assets')) {
        Copy-Item -LiteralPath (Join-Path $PackagePath $name) -Destination $root -Recurse -Force
    }
    $downloads = Join-Path $root 'downloads & [1]'
    [IO.Directory]::CreateDirectory($downloads) | Out-Null
    [IO.File]::WriteAllText((Join-Path $downloads 'resume [1].pdf'), 'portable payload')
    $config = Get-Content -LiteralPath (Join-Path $root 'config.json') -Raw | ConvertFrom-Json
    $config.Settings.DownloadsPath = Join-Path $root 'missing default folder'
    $config.Settings.ExportJSON = $true
    $config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $root 'custom & [1].json')
    $arguments = '-Silent -ConfigPath ' + (ConvertTo-WindowsArgument (Join-Path $root 'custom & [1].json')) + ' -DownloadsPath ' + (ConvertTo-WindowsArgument $downloads)
    $process = Start-Process -FilePath (Join-Path $root 'DownloadOrganizerPro.exe') -ArgumentList ($arguments + ' -DryRun') -PassThru -WindowStyle Hidden
    try { $process.WaitForExit(); if ($process.ExitCode -ne 0) { throw 'Portable DryRun failed.' } }
    finally { $process.Dispose() }
    if (-not (Test-Path -LiteralPath (Join-Path $downloads 'resume [1].pdf')) -or (Test-Path -LiteralPath (Join-Path $root 'logs/transactions'))) { throw 'DryRun mutated downloads or created a transaction.' }
    $report = Get-ChildItem -LiteralPath (Join-Path $root 'logs/reports') -Filter '*.json' | Select-Object -First 1
    $reportData = Get-Content -LiteralPath $report.FullName -Raw | ConvertFrom-Json
    if ($reportData.Summary.Planned -ne 1 -or $reportData.Results[0].Status -ne 'Planned') { throw 'Portable DryRun reported inconsistent outcomes.' }
    $mutex = [Threading.Mutex]::new($false, 'Local\DownloadOrganizerPro_GUI')
    $owned = $false
    try {
        try { $owned = $mutex.WaitOne(0) }
        catch [Threading.AbandonedMutexException] { $owned = $true }
        $process = Start-Process -FilePath (Join-Path $root 'DownloadOrganizerPro.exe') -ArgumentList $arguments -PassThru -WindowStyle Hidden
        try {
            if (-not $process.WaitForExit(30000)) { throw 'Portable launcher timed out.' }
            if ($process.ExitCode -ne 0) { throw "Portable launcher failed: $($process.ExitCode)" }
        }
        finally { $process.Dispose() }
    }
    finally { if ($owned) { $mutex.ReleaseMutex() }; $mutex.Dispose() }
    $destination = Join-Path $downloads 'Documents/CV/resume [1].pdf'
    if (-not (Test-Path -LiteralPath $destination)) { throw 'Arguments were not forwarded or the silent pipeline did not run while the GUI mutex was held.' }
    if ([IO.File]::ReadAllText($destination) -ne 'portable payload') { throw 'Portable run changed file contents.' }
    $process = Start-Process -FilePath (Join-Path $root 'DownloadOrganizerPro.exe') -ArgumentList '-Undo -Silent' -PassThru -WindowStyle Hidden
    try { $process.WaitForExit(); if ($process.ExitCode -ne 0) { throw 'Portable undo failed.' } }
    finally { $process.Dispose() }
    if ([IO.File]::ReadAllText((Join-Path $downloads 'resume [1].pdf')) -ne 'portable payload') { throw 'Portable undo did not restore the source.' }
    Write-Host 'Portable package smoke passed: spaces, metacharacters, silent execution with GUI mutex held, and undo.'
}
finally {
    $resolved = [IO.Path]::GetFullPath($root)
    if (-not $resolved.StartsWith($parent.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Package cleanup escaped its workspace.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
