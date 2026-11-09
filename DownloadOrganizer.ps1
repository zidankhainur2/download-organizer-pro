[CmdletBinding()]
param(
    [switch]$DryRun, [switch]$Recurse, [switch]$Undo, [switch]$Silent, [switch]$Background,
    [switch]$Watcher, [switch]$ExportCSV, [switch]$ExportJSON, [switch]$ExportHTML,
    [switch]$Report, [switch]$GUI, [switch]$Schedule, [switch]$Unschedule, [switch]$ScheduleStatus,
    [string]$ConfigPath = '', [string]$DownloadsPath,
    [ValidateSet('Rename', 'Skip', 'Overwrite')][string]$ConflictAction
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $ConfigPath) { $ConfigPath = Join-Path $PSScriptRoot 'config.json' }
Import-Module "$PSScriptRoot/DownloadOrganizerPro.psd1"
$ConfigPath = Resolve-EnvironmentPath $ConfigPath
if ($DownloadsPath) { $DownloadsPath = Resolve-EnvironmentPath $DownloadsPath }
$operationalPath = Join-Path $PSScriptRoot 'logs'
try {
    $modes = @($GUI, $Undo, $Watcher, $Report, $Schedule, $Unschedule, $ScheduleStatus, $Background) | Where-Object { $_ }
    if (@($modes).Count -gt 1) { throw 'Choose only one execution mode.' }
    $config = $null
    if ($Report) { Get-OrganizerStatistics -LogPath $operationalPath; return }
    if ($Unschedule) { Unregister-OrganizerTask; return }
    if ($ScheduleStatus) { Get-OrganizerTask; return }
    if ($Undo) {
        $logs = @((Get-UndoLog -LogPath (Join-Path $operationalPath 'transactions')) + (Get-UndoLog -LogPath $operationalPath) | Sort-Object LastWriteTime -Descending)
        if ($logs.Count -eq 0) { if (-not $Silent) { Write-Host 'No transactions available.' }; return }
        $result = Invoke-UndoOperation -TransactionFile $logs[0].FullName
        if (-not $Silent) { $result }
        if ($result.FailedCount -gt 0) { exit 1 }
        return
    }
    $config = Get-OrganizerConfig -Path $ConfigPath -DownloadsPath $DownloadsPath
    foreach ($name in @('DryRun', 'ExportCSV', 'ExportJSON', 'ExportHTML')) {
        if ($PSBoundParameters.ContainsKey($name)) { $config.Settings.$name = [bool]$PSBoundParameters[$name] }
    }
    if ($PSBoundParameters.ContainsKey('Recurse')) { $config.Settings.Recursive = [bool]$Recurse }
    if ($PSBoundParameters.ContainsKey('Verbose')) { $config.Settings.Verbose = [bool]$PSBoundParameters.Verbose }
    if ($ConflictAction) { $config.Settings | Add-Member ConflictAction $ConflictAction -Force }
    if ($GUI -or ($PSBoundParameters.Count -eq 0 -and [Environment]::UserInteractive)) {
        Show-OrganizerGUI -ConfigPath $ConfigPath -Config $config
        return
    }
    if ($Schedule) {
        Register-OrganizerTask -ScriptPath $PSCommandPath -ConfigPath ([IO.Path]::GetFullPath($ConfigPath)) -DownloadsPath $config.Settings.DownloadsPath -IntervalMinutes $config.Settings.ScheduleIntervalMinutes
        return
    }
    if ($Watcher) {
        Start-OrganizerWatcher -Path $config.Settings.DownloadsPath -ScriptPath $PSCommandPath -ConfigPath $ConfigPath -DebounceSeconds $config.Settings.WatcherDebounceSeconds -IgnorePatterns $config.Settings.IgnorePatterns | Out-Null
        $lastWatcherError = ''
        try {
            while ($true) {
                Start-Sleep -Milliseconds 250
                $watcherError = (Get-OrganizerWatcherStatus).LastError
                if ($watcherError -and $watcherError -ne $lastWatcherError) { Write-Warning $watcherError; $lastWatcherError = $watcherError }
            }
        }
        finally { Stop-OrganizerWatcher | Out-Null }
    }
    if ($Background) {
        $command = "& '" + $PSCommandPath.Replace("'", "''") + "' -Silent"
        foreach ($name in $PSBoundParameters.Keys) {
            if ($name -in @('Background', 'Silent')) { continue }
            $value = $PSBoundParameters[$name]
            if ($name -eq 'ConfigPath') { $value = $ConfigPath }
            if ($name -eq 'DownloadsPath') { $value = $DownloadsPath }
            if ($value -is [Management.Automation.SwitchParameter]) { $command += ' -' + $name + ':$' + ([bool]$value).ToString().ToLowerInvariant() }
            else { $command += ' -' + $name + " '" + ([string]$value).Replace("'", "''") + "'" }
        }
        $arguments = '-NoProfile -ExecutionPolicy Bypass -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
        $startInfo = [Diagnostics.ProcessStartInfo]::new('powershell.exe', $arguments)
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.WindowStyle = 'Hidden'
        $startInfo.EnvironmentVariables.Remove('PSModulePath')
        $process = [Diagnostics.Process]::Start($startInfo)
        $process.Dispose()
        return
    }
    $run = Invoke-Organizer -Config $config -OperationalPath $operationalPath
    if (-not $Silent) { Write-Host (Show-OrganizerSummary -Summary $run.Summary -LogFile $run.LogFile) }
    if ($run.Summary.Failed -gt 0) { exit 1 }
}
catch { Write-Error $_ -ErrorAction Continue; exit 1 }
