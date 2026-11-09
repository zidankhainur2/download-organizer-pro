[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot/build.ps1"
$version = (Import-PowerShellDataFile "$PSScriptRoot/DownloadOrganizerPro.psd1").ModuleVersion
$packageName = "DownloadOrganizerPro-$version-portable"
$parent = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '.tools/release-build'))
$session = Join-Path $parent ([guid]::NewGuid().ToString('N'))
$payload = Join-Path $session $packageName
[IO.Directory]::CreateDirectory($payload) | Out-Null
try {
    $runtime = @('DownloadOrganizer.ps1','DownloadOrganizerPro.psd1','DownloadOrganizerPro.psm1','config.json','assets/OrganizerWindow.xaml')
    $runtime += @(Get-ChildItem -LiteralPath "$PSScriptRoot/modules" -Filter '*.psm1' -File | ForEach-Object { 'modules/' + $_.Name })
    $sources = $runtime + @('LICENSE','CHANGELOG.md',"docs/RELEASE_NOTES_$version.md",'assets/Launcher.cs','assets/app.ico','assets/favicon.ico','build.ps1','package.ps1')
    foreach ($path in $runtime + @('LICENSE','CHANGELOG.md')) {
        $destination = Join-Path $payload $path
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $path) -Destination $destination
    }
    Copy-Item -LiteralPath "$PSScriptRoot/dist/DownloadOrganizerPro.exe" -Destination $payload
    Copy-Item -LiteralPath "$PSScriptRoot/docs/RELEASE_NOTES_$version.md" -Destination (Join-Path $payload 'RELEASE_NOTES.md')
    @"
Download Organizer Pro $version - Windows portable

Extract this entire folder to a location your Windows account can write to.
Double-click DownloadOrganizerPro.exe for the GUI. Keep all companion files together.
Windows PowerShell 5.1 and WPF are required by the launcher. No installer is included.

Preview: DownloadOrganizerPro.exe -Silent -DryRun -DownloadsPath "C:\My Downloads"
Organize: DownloadOrganizerPro.exe -Silent -DownloadsPath "C:\My Downloads"
Recovery: DownloadOrganizerPro.exe -Silent -Undo
Edit config.json for classification, conflict behavior and automation settings.

Before upgrading, stop watcher/scheduled runs and wait for active transactions.
Keep your existing config.json and logs/ folder, including transactions, progress
journals and overwrite backups. Extract the new version into a separate writable
folder first. Never replace recovery data with an empty folder from another package.

See RELEASE_NOTES.md for changes and recovery limitations. License: LICENSE.
"@ | Set-Content -LiteralPath (Join-Path $payload 'README.txt') -Encoding UTF8
    $files = @(Get-ChildItem -LiteralPath $payload -Recurse -File | Sort-Object FullName | ForEach-Object {
        [pscustomobject]@{ Path = $packageName + '/' + $_.FullName.Substring($payload.Length + 1).Replace('\','/'); Bytes = $_.Length; SHA256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    })
    $archive = Join-Path $session ($packageName + '.zip')
    Compress-Archive -LiteralPath $payload -DestinationPath $archive
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try { $entries = @($zip.Entries | Where-Object { -not $_.FullName.EndsWith('/') } | ForEach-Object { $_.FullName.Replace('\','/') } | Sort-Object) }
    finally { $zip.Dispose() }
    if (($entries -join "`n") -cne (($files.Path | Sort-Object) -join "`n")) { throw 'Release ZIP contents differ from the clean staging folder.' }
    $archiveHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    $manifest = [ordered]@{ Version = $version; Created = (Get-Date -Format o); Archive = $packageName + '.zip'; SHA256 = $archiveHash; Files = $files; SourceFiles = @($sources | Sort-Object -Unique | Where-Object { Test-Path -LiteralPath (Join-Path $PSScriptRoot $_) } | ForEach-Object { [pscustomobject]@{ Path = $_; SHA256 = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $_) -Algorithm SHA256).Hash } }) }
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $session "DownloadOrganizerPro-$version-release.json") -Encoding UTF8
    "$archiveHash  $packageName.zip" | Set-Content -LiteralPath ($archive + '.sha256') -Encoding ASCII
    foreach ($path in @($archive, ($archive + '.sha256'), (Join-Path $session "DownloadOrganizerPro-$version-release.json"))) {
        Move-Item -LiteralPath $path -Destination (Join-Path $PSScriptRoot 'dist') -Force
    }
    Write-Host "Release package: $PSScriptRoot/dist/$packageName.zip"
}
finally {
    $resolved = [IO.Path]::GetFullPath($session)
    if (-not $resolved.StartsWith($parent.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Release cleanup escaped its workspace.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
