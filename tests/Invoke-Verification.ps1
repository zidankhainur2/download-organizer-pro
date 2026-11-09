# Reproducible local gate; interactive GUI results are recorded by Invoke-GUIVerification separately.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$output = Join-Path $projectRoot ('.tools/verification/Automated-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($output) | Out-Null
function Invoke-VerificationProcess {
    param([string]$Executable, [string[]]$Arguments, [string]$Log)
    $ErrorActionPreference = 'Continue'
    & $Executable @Arguments *> $Log
    $LASTEXITCODE
}
function Get-SourceSnapshot {
    $version = (Import-PowerShellDataFile "$projectRoot/DownloadOrganizerPro.psd1").ModuleVersion
    $paths = @('DownloadOrganizer.ps1','DownloadOrganizerPro.psd1','DownloadOrganizerPro.psm1','config.json','build.ps1','package.ps1','LICENSE','CHANGELOG.md',"docs/RELEASE_NOTES_$version.md",'.github/workflows/ci.yml')
    $paths += @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'modules'),(Join-Path $projectRoot 'assets'),$PSScriptRoot -Recurse -File | Where-Object Extension -in @('.ps1','.psm1','.psd1','.cs','.xaml','.ico') | ForEach-Object { $_.FullName.Substring($projectRoot.Length + 1).Replace('\','/') })
    @($paths | Sort-Object -Unique | ForEach-Object { [pscustomobject]@{ Path = $_; SHA256 = (Get-FileHash -LiteralPath (Join-Path $projectRoot $_) -Algorithm SHA256).Hash } })
}
$files = Get-SourceSnapshot
$sha = [Security.Cryptography.SHA256]::Create()
try { $sourceId = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($files | ConvertTo-Json -Compress))))).Replace('-','') }
finally { $sha.Dispose() }
$record = [ordered]@{ Date = (Get-Date -Format o); Head = (git -C $projectRoot rev-parse HEAD); SourceId = $sourceId; DirtyStatus = @(git -C $projectRoot status --short); OS = [Environment]::OSVersion.VersionString; Files = $files; Engines = @(); Syntax = 'belum diuji'; Manifest = 'belum diuji'; Build = 'belum diuji'; Portable = 'belum diuji'; Error = ''; Evidence = $output }
try {
    foreach ($file in $files | Where-Object Path -match '\.ps[dm]?1$') {
        $tokens = $null; $errors = $null
        $null = [Management.Automation.Language.Parser]::ParseFile((Join-Path $projectRoot $file.Path), [ref]$tokens, [ref]$errors)
        if ($errors.Count) { throw "Syntax failed: $($file.Path): $errors" }
    }
    $record.Syntax = 'lulus'
    $null = Test-ModuleManifest (Join-Path $projectRoot 'DownloadOrganizerPro.psd1')
    $record.Manifest = 'lulus'
    $engines = @("$env:SystemRoot/System32/WindowsPowerShell/v1.0/powershell.exe", (Join-Path $projectRoot '.tools/pwsh/pwsh.exe'))
    if (-not (Test-Path -LiteralPath $engines[1])) { $engines[1] = (Get-Command pwsh -ErrorAction Stop).Source }
    for ($i = 0; $i -lt $engines.Count; $i++) {
        $destination = Join-Path $output "engine-$i"
        $arguments = @('-NoProfile','-STA','-ExecutionPolicy','Bypass','-File', (Join-Path $PSScriptRoot 'Invoke-Tests.ps1'), '-OutputDirectory', $destination)
        if ($i -eq 0) { $arguments += '-Coverage' }
        $exitCode = Invoke-VerificationProcess $engines[$i] $arguments (Join-Path $output "engine-$i.txt")
        $record.Engines += Get-Content -LiteralPath (Join-Path $destination 'summary.json') -Raw | ConvertFrom-Json
        if ($exitCode -ne 0) { throw "Engine $i failed; see $output/engine-$i.txt" }
    }
    $exitCode = Invoke-VerificationProcess $engines[0] @('-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',(Join-Path $projectRoot 'package.ps1')) (Join-Path $output 'build.txt')
    if ($exitCode -ne 0) { throw 'Portable build failed.' }
    $record.Build = 'lulus'
    for ($i = 0; $i -lt $engines.Count; $i++) {
        $version = (Import-PowerShellDataFile "$projectRoot/DownloadOrganizerPro.psd1").ModuleVersion
        $archive = Join-Path $projectRoot "dist/DownloadOrganizerPro-$version-portable.zip"
        $exitCode = Invoke-VerificationProcess $engines[$i] @('-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Smoke-Package.ps1'),'-PackagePath',$archive) (Join-Path $output "portable-$i.txt")
        if ($exitCode -ne 0) { throw "Portable smoke failed on engine $i." }
    }
    $record.Portable = 'lulus'
    if (($files | ConvertTo-Json -Compress) -cne ((Get-SourceSnapshot) | ConvertTo-Json -Compress)) { throw 'Source changed during verification; rerun against a stable snapshot.' }
}
catch { $record.Error = $_.Exception.Message }
finally {
    $record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'result.json') -Encoding UTF8
    Write-Host "Verification evidence: $output"
}
if ($record.Error) { throw $record.Error }
