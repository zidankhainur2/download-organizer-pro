Set-StrictMode -Version Latest

#region Public Functions

<#
.SYNOPSIS
Initializes log file directory and creates daily log file if missing.

.PARAMETER LogPath
Directory path where logs are stored.

.OUTPUTS
[string] Full path to initialized log file.

.EXAMPLE
$logFile = Initialize-Logger -LogPath ".\logs"
#>
function Initialize-Logger {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath

    )

    if (-not (Test-Path -LiteralPath $LogPath)) {

        New-Item `
            -ItemType Directory `
            -Path $LogPath `
            | Out-Null

    }

    $date = Get-Date -Format "yyyy-MM-dd"

    $logFile = Join-Path `
        $LogPath `
        "organizer-$date.log"

    if (-not (Test-Path -LiteralPath $logFile)) {

        New-Item `
            -ItemType File `
            -Path $logFile `
            | Out-Null

    }

    return $logFile

}

<#
.SYNOPSIS
Writes a formatted log entry to the log file.

.PARAMETER LogFile
Target log file path.

.PARAMETER Message
Message to log.

.PARAMETER Level
Log level severity (INFO, SUCCESS, WARNING, ERROR).

.EXAMPLE
Write-OrganizerLog -LogFile $logFile -Message "Task complete" -Level SUCCESS
#>
function Write-OrganizerLog {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$LogFile,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet(
            "INFO",
            "SUCCESS",
            "WARNING",
            "ERROR"
        )]
        [string]$Level = "INFO"

    )

    $timestamp = Get-Date `
        -Format "yyyy-MM-dd HH:mm:ss"

    $entry = "[{0}] [{1}] {2}" -f `
        $timestamp,
        $Level,
        $Message

    Add-Content `
        -Path $LogFile `
        -Value $entry

}

<#
.SYNOPSIS
Logs the results of file move operations.

.PARAMETER LogFile
Target log file path.

.PARAMETER Results
Collection of move operation results.
#>
function Write-MoveLog {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$LogFile,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [array]$Results

    )

    foreach ($item in $Results) {

        if ($item.Status -eq "Moved") {

            Write-OrganizerLog `
                -LogFile $LogFile `
                -Level SUCCESS `
                -Message (
                    "Moved: {0} -> {1}" -f `
                    $item.File,
                    $item.Destination
                )

        }
        else {

            Write-OrganizerLog `
                -LogFile $LogFile `
                -Level ERROR `
                -Message (
                    "Failed: {0} | {1}" -f `
                    $item.File,
                    $item.Destination
                )

        }

    }

}

#endregion

Export-ModuleMember `
    -Function `
        Initialize-Logger,
        Write-OrganizerLog,
        Write-MoveLog