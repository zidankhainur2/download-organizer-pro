Set-StrictMode -Version Latest
foreach ($name in @('Utils', 'Validation', 'Config', 'Organizer', 'Undo', 'Watcher', 'Scheduler', 'Summary', 'ReportGenerator')) { Import-Module "$PSScriptRoot/$name.psm1" }
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

function Start-OrganizerGUIWorker {
    param($State, $Config, [string]$ProjectRoot, [string]$TransactionFile = '')
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = 'STA'
    $runspace.Open()
    $worker = [powershell]::Create()
    $worker.Runspace = $runspace
    $queue = [Collections.Concurrent.ConcurrentQueue[string]]::new()
    [void]$worker.AddScript({
        param($root, $config, $queue, $transaction)
        $ErrorActionPreference = 'Stop'
        Import-Module "$root/DownloadOrganizerPro.psd1"
        if ($transaction) { Invoke-UndoOperation -TransactionFile $transaction }
        else { Invoke-Organizer -Config $config -OperationalPath (Join-Path $root 'logs') -ProgressQueue $queue }
    }).AddArgument($ProjectRoot).AddArgument($Config).AddArgument($queue).AddArgument($TransactionFile)
    try {
        $State.Worker = $worker
        $State.Runspace = $runspace
        $State.Queue = $queue
        $State.IsUndo = [bool]$TransactionFile
        $State.Handle = $worker.BeginInvoke()
    }
    catch { $worker.Dispose(); $runspace.Dispose(); $State.Worker = $null; throw }
}

function Initialize-OrganizerWindowControls {
    param($Window, $Config, [string]$Version)
    $controls = @{}
    foreach ($name in @('TxtFolderPath', 'BtnBrowse', 'BtnStart', 'BtnWatcher', 'BtnUndo', 'BtnReportStats', 'BtnSchedule', 'ChkSmartRules', 'ChkDryRun', 'ChkRecurse', 'ChkExportHTML', 'ChkExportCSV', 'TxtKpiScanned', 'TxtKpiMoved', 'TxtKpiFailed', 'TxtKpiSize', 'GridResults', 'TxtLogConsole', 'TxtVersion')) {
        $controls[$name] = $window.FindName($name)
    }
    $controls.TxtVersion.Text = "v$version"
    $controls.TxtFolderPath.Text = Resolve-EnvironmentPath $Config.Settings.DownloadsPath
    foreach ($pair in @(@('ChkSmartRules', 'EnableSmartRules'), @('ChkDryRun', 'DryRun'), @('ChkRecurse', 'Recursive'), @('ChkExportHTML', 'ExportHTML'), @('ChkExportCSV', 'ExportCSV'))) {
        $controls[$pair[0]].IsChecked = $Config.Settings.($pair[1])
    }
    $controls.TxtLogConsole.Text = "[INIT] Download Organizer Pro v$version`n"
    return $controls
}

<#
.SYNOPSIS
Opens the WPF interface with a local instance mutex.
#>
function Show-OrganizerGUI {
    [CmdletBinding()]
    param([string]$ConfigPath = '', $Config)
    $mutex = [Threading.Mutex]::new($false, 'Local\DownloadOrganizerPro_GUI_Window')
    $owned = $false
    try {
        try { $owned = $mutex.WaitOne(0) }
        catch [Threading.AbandonedMutexException] { $owned = $true }
        if ($owned) { Show-OrganizerWindow -ConfigPath $ConfigPath -Config $Config }
    }
    finally { if ($owned) { $mutex.ReleaseMutex() }; $mutex.Dispose() }
}

function Show-OrganizerWindow {
    [CmdletBinding()]
    param([string]$ConfigPath = '', $Config, [string]$TaskName = 'DownloadOrganizerPro')
    $projectRoot = Split-Path $PSScriptRoot -Parent
    if (-not $ConfigPath) { $ConfigPath = Join-Path $projectRoot 'config.json' }
    if (-not $Config) { $Config = Get-OrganizerConfig -Path $ConfigPath }
    $window = [Windows.Markup.XamlReader]::Parse((Get-Content -LiteralPath "$projectRoot/assets/OrganizerWindow.xaml" -Raw -Encoding UTF8))
    $version = (Import-PowerShellDataFile "$projectRoot/DownloadOrganizerPro.psd1").ModuleVersion
    $controls = Initialize-OrganizerWindowControls $window $Config $version
    $state = @{ Worker = $null; Handle = $null; Runspace = $null; Queue = $null; Closing = $false; IsUndo = $false; WatcherError = '' }
    $busyControls = @('BtnStart', 'BtnUndo', 'BtnWatcher', 'BtnSchedule', 'BtnBrowse', 'TxtFolderPath', 'ChkSmartRules', 'ChkDryRun', 'ChkRecurse', 'ChkExportHTML', 'ChkExportCSV')
    $setBusy = { param([bool]$busy) foreach ($name in $busyControls) { $controls[$name].IsEnabled = -not $busy } }
    $readConfig = {
        $copy = $Config | ConvertTo-Json -Depth 12 | ConvertFrom-Json
        $copy.Settings.DownloadsPath = Resolve-EnvironmentPath $controls.TxtFolderPath.Text
        Test-OrganizerConfiguration $copy | Out-Null
        foreach ($pair in @(@('ChkSmartRules', 'EnableSmartRules'), @('ChkDryRun', 'DryRun'), @('ChkRecurse', 'Recursive'), @('ChkExportHTML', 'ExportHTML'), @('ChkExportCSV', 'ExportCSV'))) {
            $copy.Settings.($pair[1]) = [bool]$controls[$pair[0]].IsChecked
        }
        $copy
    }
    $controls.BtnBrowse.Add_Click({
        $dialog = [Windows.Forms.FolderBrowserDialog]::new()
        try { if ($dialog.ShowDialog() -eq 'OK') { $controls.TxtFolderPath.Text = $dialog.SelectedPath } }
        finally { $dialog.Dispose() }
    })
    $controls.BtnStart.Add_Click({
        try {
            $effective = & $readConfig
            & $setBusy $true
            $controls.TxtLogConsole.AppendText("[EXEC] Organizing $($effective.Settings.DownloadsPath)`n")
            Start-OrganizerGUIWorker $state $effective $projectRoot
        }
        catch { & $setBusy $false; $controls.TxtLogConsole.AppendText("[ERROR] $($_.Exception.Message)`n") }
    })
    $controls.BtnUndo.Add_Click({
        try {
            $logsDir = Join-Path $projectRoot 'logs'
            $logs = @((Get-UndoLog (Join-Path $logsDir 'transactions')) + (Get-UndoLog $logsDir) | Sort-Object LastWriteTime -Descending)
            if ($logs.Count -eq 0) { $controls.TxtLogConsole.AppendText("[UNDO] No transactions available.`n"); return }
            & $setBusy $true
            Start-OrganizerGUIWorker $state $null $projectRoot $logs[0].FullName
        }
        catch { & $setBusy $false; $controls.TxtLogConsole.AppendText("[ERROR] $($_.Exception.Message)`n") }
    })
    $controls.BtnWatcher.Add_Click({
        try {
            if ((Get-OrganizerWatcherStatus).IsActive) { Stop-OrganizerWatcher | Out-Null; $controls.BtnWatcher.Content = 'START WATCHER' }
            else {
                $effective = & $readConfig
                Start-OrganizerWatcher -Path $effective.Settings.DownloadsPath -ScriptPath "$projectRoot/DownloadOrganizer.ps1" -ConfigPath $ConfigPath -DebounceSeconds $effective.Settings.WatcherDebounceSeconds -IgnorePatterns $effective.Settings.IgnorePatterns | Out-Null
                $controls.BtnWatcher.Content = 'STOP WATCHER'
            }
        }
        catch { $controls.TxtLogConsole.AppendText("[ERROR] $($_.Exception.Message)`n") }
    })
    $controls.BtnSchedule.Add_Click({
        try {
            if ((Get-OrganizerTask -TaskName $TaskName).IsRegistered) { Unregister-OrganizerTask -TaskName $TaskName | Out-Null; $controls.TxtLogConsole.AppendText("[SCHEDULE] Removed.`n") }
            else {
                $effective = & $readConfig
                Register-OrganizerTask -TaskName $TaskName -ScriptPath "$projectRoot/DownloadOrganizer.ps1" -ConfigPath ([IO.Path]::GetFullPath($ConfigPath)) -DownloadsPath $effective.Settings.DownloadsPath -IntervalMinutes $effective.Settings.ScheduleIntervalMinutes | Out-Null
                $controls.TxtLogConsole.AppendText("[SCHEDULE] Registered every $($effective.Settings.ScheduleIntervalMinutes) minutes.`n")
            }
        }
        catch { $controls.TxtLogConsole.AppendText("[ERROR] $($_.Exception.Message)`n") }
    })
    $controls.BtnReportStats.Add_Click({
        try {
            $stats = Get-OrganizerStatistics -LogPath (Join-Path $projectRoot 'logs')
            $controls.TxtLogConsole.AppendText("[STATS] Executions: $($stats.TotalExecutions); Moved: $($stats.TotalMoved); Failed: $($stats.TotalFailed)`n")
        }
        catch { $controls.TxtLogConsole.AppendText("[ERROR] $($_.Exception.Message)`n") }
    })
    $timer = [Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [timespan]::FromMilliseconds(150)
    # DispatcherTimer callbacks run on the window's dispatcher; workers never touch controls.
    $timer.Add_Tick({
        $watcherStatus = Get-OrganizerWatcherStatus
        if ($watcherStatus.LastError -and $watcherStatus.LastError -ne $state.WatcherError) {
            $state.WatcherError = $watcherStatus.LastError
            $controls.TxtLogConsole.AppendText("[WATCHER ERROR] $($watcherStatus.LastError)`n")
        }
        if (-not $state.Worker) { return }
        $message = ''
        $messages = [Text.StringBuilder]::new()
        $count = 0
        while ($count -lt 100 -and $state.Queue.TryDequeue([ref]$message)) { [void]$messages.AppendLine($message); $count++ }
        if ($messages.Length) { $controls.TxtLogConsole.AppendText($messages.ToString()); $controls.TxtLogConsole.ScrollToEnd() }
        if (-not $state.Handle.IsCompleted) { return }
        try {
            $output = @($state.Worker.EndInvoke($state.Handle))
            if ($state.Worker.HadErrors) { throw ($state.Worker.Streams.Error | Out-String) }
            $run = $output[-1]
            if ($state.IsUndo) {
                $controls.TxtLogConsole.AppendText("[UNDO] Restored: $($run.RestoredCount); Failed: $($run.FailedCount)`n$($run.Errors -join "`n")`n")
            }
            else {
                $controls.GridResults.ItemsSource = @($run.Results | Select-Object -First 500)
                $summary = $run.Summary
                $controls.TxtKpiScanned.Text = [string]$summary.TotalFiles
                $controls.TxtKpiMoved.Text = [string]$summary.Moved
                $controls.TxtKpiFailed.Text = [string]$summary.Failed
                $controls.TxtKpiSize.Text = "$($summary.TotalSizeMB) MB"
                $controls.TxtLogConsole.AppendText((Show-OrganizerSummary $summary) + "`n")
                if ($summary.Failed -gt 0) {
                    $failure = $run.Results | Where-Object Status -eq 'Failed' | Select-Object -First 1
                    $controls.TxtLogConsole.AppendText("[ERROR] $($failure.File): $($failure.Reason)`nSee reports for all failed files.`n")
                }
                foreach ($path in $run.Reports.Values) { $controls.TxtLogConsole.AppendText("[REPORT] $path`n") }
                if ($run.Results.Count -gt 500) { $controls.TxtLogConsole.AppendText("[INFO] Showing first 500 rows; reports contain every result.`n") }
            }
        }
        catch { $controls.TxtLogConsole.AppendText("[ERROR] $($_.Exception.Message)`n") }
        finally {
            $state.Worker.Dispose(); $state.Runspace.Dispose(); $state.Worker = $null
            & $setBusy $false
            if ($state.Closing) { $window.Close() }
        }
    })
    $window.Add_Closing({
        param($sender, $eventArgs)
        Stop-OrganizerWatcher | Out-Null
        if ($state.Worker) {
            $eventArgs.Cancel = $true
            $state.Closing = $true
            $controls.TxtLogConsole.AppendText("[INFO] Waiting for the active transaction before closing...`n")
        }
    })
    $timer.Start()
    try { $window.ShowDialog() | Out-Null }
    finally { $timer.Stop(); Stop-OrganizerWatcher | Out-Null }
}
<#
.SYNOPSIS
Compatibility entrypoint for the organizer interface.
#>
function New-OrganizerWindow {
    [CmdletBinding()]
    param()
    Show-OrganizerGUI
}
Export-ModuleMember -Function Show-OrganizerGUI, New-OrganizerWindow
