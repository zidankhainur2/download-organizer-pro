Set-StrictMode -Version Latest

#region Global Module State

if (-not (Test-Path Variable:\Global:OrganizerWatcherInstance)) {
    $Global:OrganizerWatcherInstance = $null
}

#endregion

#region Public Functions

<#
.SYNOPSIS
Starts real-time folder monitoring using FileSystemWatcher.

.DESCRIPTION
Monitors the target directory for new file creation events, filters temporary download extensions, debounces file write completion, and automatically triggers Download Organizer.

.PARAMETER Path
Directory path to monitor.

.PARAMETER ScriptPath
Path to DownloadOrganizer.ps1 script to execute on file creation.

.PARAMETER DebounceSeconds
Seconds to wait after file creation before triggering organizer.

.OUTPUTS
[System.IO.FileSystemWatcher]
#>
function Start-OrganizerWatcher {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath,

        [int]$DebounceSeconds = 3

    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Target directory not found: $Path"
    }

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        throw "Organizer script not found: $ScriptPath"
    }

    if ($null -ne $Global:OrganizerWatcherInstance) {
        Stop-OrganizerWatcher
    }

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Path
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true

    $action = {
        param($sender, $eventArgs)
        $filePath = $eventArgs.FullPath
        $extension = [System.IO.Path]::GetExtension($filePath).ToLower()

        # Ignore temporary download extensions
        if ($extension -in @(".tmp", ".crdownload", ".part", ".partial")) {
            return
        }

        Start-Sleep -Seconds $DebounceSeconds

        if (Test-Path -LiteralPath $filePath) {
            try {
                powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -Silent
            }
            catch {
                # Ignore errors during async watcher trigger
            }
        }
    }

    $createdSubscriber = Register-ObjectEvent `
        -InputObject $watcher `
        -EventName "Created" `
        -Action $action

    $Global:OrganizerWatcherInstance = [PSCustomObject]@{
        Watcher    = $watcher
        Subscriber = $createdSubscriber
        Path       = $Path
        StartTime  = (Get-Date)
    }

    return $Global:OrganizerWatcherInstance

}

<#
.SYNOPSIS
Stops active folder watcher monitoring.
#>
function Stop-OrganizerWatcher {

    [CmdletBinding()]

    param()

    if ($null -ne $Global:OrganizerWatcherInstance) {
        try {
            $Global:OrganizerWatcherInstance.Watcher.EnableRaisingEvents = $false
            $Global:OrganizerWatcherInstance.Watcher.Dispose()
            Unregister-Event -SourceIdentifier $Global:OrganizerWatcherInstance.Subscriber.Name -ErrorAction SilentlyContinue
        }
        catch {
        }
        finally {
            $Global:OrganizerWatcherInstance = $null
        }
        return $true
    }

    return $false

}

<#
.SYNOPSIS
Returns the status of the folder watcher instance.

.OUTPUTS
PSCustomObject
#>
function Get-OrganizerWatcherStatus {

    [CmdletBinding()]

    param()

    if ($null -ne $Global:OrganizerWatcherInstance) {
        return [PSCustomObject]@{
            IsActive  = $true
            Path      = $Global:OrganizerWatcherInstance.Path
            StartTime = $Global:OrganizerWatcherInstance.StartTime
        }
    }

    return [PSCustomObject]@{
        IsActive  = $false
        Path      = ""
        StartTime = $null
    }

}

#endregion

Export-ModuleMember `
    -Function `
        Start-OrganizerWatcher,
        Stop-OrganizerWatcher,
        Get-OrganizerWatcherStatus
