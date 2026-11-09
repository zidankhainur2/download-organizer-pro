Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/Utils.psm1"
<#
.SYNOPSIS
Creates or returns the daily operational log path.
#>
function Initialize-Logger {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$LogPath)
    Initialize-Directory $LogPath | Out-Null
    $path = Join-Path $LogPath ('organizer-{0}.log' -f (Get-Date -Format yyyy-MM-dd))
    if (-not (Test-Path -LiteralPath $path)) { [IO.File]::WriteAllText($path, '') }
    $path
}
<#
.SYNOPSIS
Appends one UTF-8 operational log entry.
#>
function Write-OrganizerLog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$LogFile, [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')][string]$Level = 'INFO')
    Add-Content -LiteralPath $LogFile -Value ('[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message) -Encoding UTF8 -ErrorAction Stop
}
<#
.SYNOPSIS
Writes a batch of Moved, Failed, Skipped, or Planned outcomes.
#>
function Write-MoveLog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$LogFile, [Parameter(Mandatory)][AllowEmptyCollection()][array]$Results)
    $lines = foreach ($item in $Results) {
        $level = switch ($item.Status) { Moved { 'SUCCESS' }; Failed { 'ERROR' }; default { 'INFO' } }
        $separator = if ($item.Status -eq 'Failed') { ' | ' } else { ' -> ' }
        $detail = $item.Destination
        if ($item.PSObject.Properties['Reason'] -and $item.Reason) { $detail += ' | ' + $item.Reason }
        '[{0}] [{1}] {2}: {3}{4}{5}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $level, $item.Status, $item.File, $separator, $detail
    }
    if ($lines) { Add-Content -LiteralPath $LogFile -Value $lines -Encoding UTF8 -ErrorAction Stop }
}
Export-ModuleMember -Function Initialize-Logger, Write-OrganizerLog, Write-MoveLog
