# Explicitly invoked smoke test only; normal Pester runs never register real tasks.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot/../../DownloadOrganizerPro.psd1"
$name = 'DownloadOrganizerPro-Test-' + [guid]::NewGuid().ToString('N')
$sandbox = Join-Path ([IO.Path]::GetTempPath()) $name
[IO.Directory]::CreateDirectory($sandbox) | Out-Null
$registered = $false
try {
    Register-OrganizerTask -ScriptPath "$PSScriptRoot/../../DownloadOrganizer.ps1" -DownloadsPath $sandbox -TaskName $name -IntervalMinutes 60 | Out-Null
    $registered = $true
    if (-not (Get-OrganizerTask -TaskName $name).IsRegistered) { throw 'Task registration was not visible.' }
}
finally {
    if ($registered) { Unregister-OrganizerTask -TaskName $name | Out-Null }
    [IO.Directory]::Delete($sandbox)
}
