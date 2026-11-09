Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/Utils.psm1"
$script:WatcherState = $null

<#
.SYNOPSIS
Monitors Created and Renamed files and starts serialized workers after stability checks.
#>
function Start-OrganizerWatcher {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$ScriptPath,
        [ValidateRange(1, 3600)][int]$DebounceSeconds = 3, [string]$ConfigPath,
        [string[]]$IgnorePatterns = @('*.tmp', '*.crdownload', '*.part'))
    $Path = [IO.Path]::GetFullPath((Resolve-EnvironmentPath $Path))
    $ScriptPath = Resolve-EnvironmentPath $ScriptPath
    if ($ConfigPath) { $ConfigPath = Resolve-EnvironmentPath $ConfigPath }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw "Target directory not found: $Path" }
    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) { throw "Organizer script not found: $ScriptPath" }
    Stop-OrganizerWatcher | Out-Null
    $executable = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File ' + (ConvertTo-WindowsArgument ([IO.Path]::GetFullPath($ScriptPath))) + ' -Silent -DownloadsPath ' + (ConvertTo-WindowsArgument $Path)
    if ($ScriptPath.EndsWith('.exe', [StringComparison]::OrdinalIgnoreCase)) {
        $executable = $ScriptPath
        $arguments = '-Silent -DownloadsPath ' + (ConvertTo-WindowsArgument $Path)
    }
    if ($ConfigPath) { $arguments += ' -ConfigPath ' + (ConvertTo-WindowsArgument ([IO.Path]::GetFullPath($ConfigPath))) }
    $startInfo = [Diagnostics.ProcessStartInfo]::new($executable, $arguments)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.WindowStyle = 'Hidden'
    # Let Windows PowerShell build compatible paths instead of inheriting PowerShell 7 modules.
    $startInfo.EnvironmentVariables.Remove('PSModulePath')
    $state = [hashtable]::Synchronized(@{
        Path = $Path; StartTime = (Get-Date); Pending = @{}; Process = $null
        StartInfo = $startInfo; DebounceSeconds = $DebounceSeconds
        IgnorePatterns = $IgnorePatterns; LastError = ''; Identifiers = @(); Jobs = @(); Watcher = $null; Timer = $null
    })
    $watcher = [IO.FileSystemWatcher]::new($Path, '*')
    $state.Watcher = $watcher
    $action = {
        $context = $Event.MessageData
        $path = $Event.SourceEventArgs.FullPath
        $name = [IO.Path]::GetFileName($path)
        foreach ($pattern in $context.IgnorePatterns) { if ($name -like $pattern) { return } }
        if ([IO.Directory]::Exists($path)) { return }
        $context.Pending[$path] = @{ Signature = ''; Since = Get-Date }
    }
    $tick = {
        $context = $Event.MessageData
        if ($context.Process) {
            if (-not $context.Process.HasExited) { return }
            if ($context.Process.ExitCode -ne 0) { $context.LastError = "Worker exit code: $($context.Process.ExitCode)" }
            $context.Process.Dispose()
            $context.Process = $null
        }
        $ready = @()
        foreach ($path in @($context.Pending.Keys)) {
            if (-not [IO.File]::Exists($path)) { $context.Pending.Remove($path); continue }
            try {
                $file = Get-Item -LiteralPath $path -ErrorAction Stop
                $signature = "$($file.Length):$($file.LastWriteTimeUtc.Ticks)"
                $item = $context.Pending[$path]
                if ($item.Signature -ne $signature) { $item.Signature = $signature; $item.Since = Get-Date }
                if (((Get-Date) - $item.Since).TotalSeconds -lt $context.DebounceSeconds) { return }
                $handle = [IO.File]::Open($path, 'Open', 'Read', 'None')
                $handle.Dispose()
                $ready += $path
            }
            catch { return }
        }
        if ($ready.Count -eq 0) { return }
        try {
            $context.Process = [Diagnostics.Process]::Start($context.StartInfo)
            foreach ($path in $ready) { $context.Pending.Remove($path) }
        }
        catch { $context.LastError = $_.Exception.Message }
    }
    try {
        foreach ($eventName in @('Created', 'Renamed')) {
            $id = 'OrganizerWatcher-' + [guid]::NewGuid().ToString('N')
            $state.Identifiers += $id
            $state.Jobs += Register-ObjectEvent -InputObject $watcher -EventName $eventName -SourceIdentifier $id -MessageData $state -Action $action
        }
        $timer = [Timers.Timer]::new(500)
        $state.Timer = $timer
        $id = 'OrganizerWatcher-' + [guid]::NewGuid().ToString('N')
        $state.Identifiers += $id
        $state.Jobs += Register-ObjectEvent -InputObject $timer -EventName Elapsed -SourceIdentifier $id -MessageData $state -Action $tick
        $script:WatcherState = $state
        $watcher.EnableRaisingEvents = $true
        $timer.Start()
        $watcher
    }
    catch { $script:WatcherState = $state; Stop-OrganizerWatcher | Out-Null; throw }
}
<#
.SYNOPSIS
Removes this module's subscriptions, event jobs, timer, and watcher.
#>
function Stop-OrganizerWatcher {
    [CmdletBinding()]
    param()
    $state = $script:WatcherState
    if (-not $state) { return $false }
    if ($state.Timer) { $state.Timer.Stop(); $state.Timer.Dispose() }
    if ($state.Watcher) { $state.Watcher.EnableRaisingEvents = $false; $state.Watcher.Dispose() }
    foreach ($id in $state.Identifiers) {
        Unregister-Event -SourceIdentifier $id -ErrorAction SilentlyContinue
        Get-Event -SourceIdentifier $id -ErrorAction SilentlyContinue | Remove-Event -ErrorAction SilentlyContinue
    }
    foreach ($job in $state.Jobs) { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue }
    if ($state.Process) {
        # Finish the owned worker's transaction before reporting a clean stop.
        $state.Process.WaitForExit()
        $state.Process.Dispose()
    }
    $script:WatcherState = $null
    $true
}
<#
.SYNOPSIS
Returns monitoring state and the last worker error.
#>
function Get-OrganizerWatcherStatus {
    [CmdletBinding()]
    param()
    if ($script:WatcherState) {
        [pscustomobject]@{ IsActive = $true; Path = $script:WatcherState.Path; StartTime = $script:WatcherState.StartTime; LastError = $script:WatcherState.LastError }
    }
    else { [pscustomobject]@{ IsActive = $false; Path = $null; StartTime = $null; LastError = '' } }
}
Export-ModuleMember -Function Start-OrganizerWatcher, Stop-OrganizerWatcher, Get-OrganizerWatcherStatus
