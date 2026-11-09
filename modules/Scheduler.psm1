Set-StrictMode -Version Latest
Import-Module ScheduledTasks -ErrorAction Stop
Import-Module "$PSScriptRoot/Utils.psm1"

<#
.SYNOPSIS
Registers a current-user interactive task using separate executable and literal arguments.
#>
function Register-OrganizerTask {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ScriptPath, [string]$TaskName = 'DownloadOrganizerPro',
        [ValidateRange(1, 525600)][int]$IntervalMinutes = 60, [string]$DownloadsPath, [string]$ConfigPath)
    $ScriptPath = Resolve-EnvironmentPath $ScriptPath
    if ($DownloadsPath) { $DownloadsPath = Resolve-EnvironmentPath $DownloadsPath }
    if ($ConfigPath) { $ConfigPath = Resolve-EnvironmentPath $ConfigPath }
    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) { throw "Organizer script not found: $ScriptPath" }
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File ' + (ConvertTo-WindowsArgument ([IO.Path]::GetFullPath($ScriptPath))) + ' -Silent'
    if ($DownloadsPath) { $arguments += ' -DownloadsPath ' + (ConvertTo-WindowsArgument $DownloadsPath) }
    if ($ConfigPath) { $arguments += ' -ConfigPath ' + (ConvertTo-WindowsArgument $ConfigPath) }
    $action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $arguments -ErrorAction Stop
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval ([timespan]::FromMinutes($IntervalMinutes)) -ErrorAction Stop
    $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited -ErrorAction Stop
    $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ErrorAction Stop
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null
    $true
}
<#
.SYNOPSIS
Removes the named organizer task and reports errors.
#>
function Unregister-OrganizerTask {
    [CmdletBinding()]
    param([string]$TaskName = 'DownloadOrganizerPro')
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
    $true
}
<#
.SYNOPSIS
Returns whether the named organizer task is registered.
#>
function Get-OrganizerTask {
    [CmdletBinding()]
    param([string]$TaskName = 'DownloadOrganizerPro')
    $task = Get-ScheduledTask -ErrorAction Stop | Where-Object { $null -ne $_ -and $_.TaskName -eq $TaskName }
    [pscustomobject]@{ TaskName = $TaskName; IsRegistered = ($null -ne $task) }
}
Export-ModuleMember -Function Register-OrganizerTask, Unregister-OrganizerTask, Get-OrganizerTask
