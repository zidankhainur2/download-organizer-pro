Set-StrictMode -Version Latest

#region Public Functions

<#
.SYNOPSIS
Registers a Windows Scheduled Task to run Download Organizer automatically.

.DESCRIPTION
Registers a scheduled task named "DownloadOrganizerPro" that executes DownloadOrganizer.ps1 in silent background mode.

.PARAMETER ScriptPath
Path to DownloadOrganizer.ps1 script.

.PARAMETER TaskName
Name of scheduled task. Default is DownloadOrganizerPro.

.PARAMETER IntervalMinutes
Run interval in minutes. Default is 60.

.OUTPUTS
[bool]
#>
function Register-OrganizerTask {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath,

        [string]$TaskName = "DownloadOrganizerPro",

        [int]$IntervalMinutes = 60

    )

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        throw "Organizer script not found: $ScriptPath"
    }

    $command = "powershell.exe"
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -Silent"

    # Use schtasks.exe for standard user compatibility without admin requirements
    $schtasksCmd = "schtasks /Create /TN `"$TaskName`" /TR `"$command $args`" /SC MINUTE /MO $IntervalMinutes /F"

    try {
        $output = Invoke-Expression $schtasksCmd 2>&1
        return $true
    }
    catch {
        throw "Failed to register scheduled task: $_"
    }

}

<#
.SYNOPSIS
Unregisters the Download Organizer Windows Scheduled Task.

.PARAMETER TaskName
Name of scheduled task to unregister. Default is DownloadOrganizerPro.

.OUTPUTS
[bool]
#>
function Unregister-OrganizerTask {

    [CmdletBinding()]

    param(

        [string]$TaskName = "DownloadOrganizerPro"

    )

    $schtasksCmd = "schtasks /Delete /TN `"$TaskName`" /F"

    try {
        $output = Invoke-Expression $schtasksCmd 2>&1
        return $true
    }
    catch {
        return $false
    }

}

<#
.SYNOPSIS
Checks if the Download Organizer Scheduled Task exists.

.PARAMETER TaskName
Name of scheduled task to check. Default is DownloadOrganizerPro.

.OUTPUTS
PSCustomObject
#>
function Get-OrganizerTask {

    [CmdletBinding()]

    param(

        [string]$TaskName = "DownloadOrganizerPro"

    )

    $schtasksCmd = "schtasks /Query /TN `"$TaskName`" /FO CSV"

    try {
        $output = Invoke-Expression $schtasksCmd 2>&1
        if ($LASTEXITCODE -eq 0) {
            return [PSCustomObject]@{
                TaskName = $TaskName
                IsRegistered = $true
            }
        }
    }
    catch {
    }

    return [PSCustomObject]@{
        TaskName = $TaskName
        IsRegistered = $false
    }

}

#endregion

Export-ModuleMember `
    -Function `
        Register-OrganizerTask,
        Unregister-OrganizerTask,
        Get-OrganizerTask
