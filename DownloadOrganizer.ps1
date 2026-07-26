# ===========================================
# Download Organizer Pro
# Version 2.1 (Desktop Edition)
# ===========================================

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Recurse,
    [switch]$Undo,
    [switch]$Silent,
    [switch]$Background,
    [switch]$Watcher,
    [switch]$ExportCSV,
    [switch]$ExportJSON,
    [switch]$ExportHTML,
    [switch]$Report,
    [switch]$GUI
)

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

$currentPath = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} elseif ($MyInvocation -and $MyInvocation.MyCommand -and (Get-Member -InputObject $MyInvocation.MyCommand -Name "Path") -and $MyInvocation.MyCommand.Path) {
    $MyInvocation.MyCommand.Path
} else {
    [System.AppDomain]::CurrentDomain.BaseDirectory
}

$ProjectRoot = if (Test-Path -LiteralPath $currentPath -PathType Leaf) {
    Split-Path -Parent $currentPath
} else {
    $currentPath
}

# Ensure ProjectRoot resolves to directory containing modules/
if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "modules"))) {
    $parentDir = Split-Path -Parent $ProjectRoot
    if (Test-Path -LiteralPath (Join-Path $parentDir "modules")) {
        $ProjectRoot = $parentDir
    }
}

# Import Modules
Import-Module "$ProjectRoot\modules\Models.psm1" -Force
Import-Module "$ProjectRoot\modules\Utils.psm1" -Force
Import-Module "$ProjectRoot\modules\Validation.psm1" -Force
Import-Module "$ProjectRoot\modules\Config.psm1" -Force
Import-Module "$ProjectRoot\modules\Scanner.psm1" -Force
Import-Module "$ProjectRoot\modules\Classifier.psm1" -Force
Import-Module "$ProjectRoot\modules\SmartClassifier.psm1" -Force
Import-Module "$ProjectRoot\modules\DuplicateDetector.psm1" -Force
Import-Module "$ProjectRoot\modules\Mover.psm1" -Force
Import-Module "$ProjectRoot\modules\Logger.psm1" -Force
Import-Module "$ProjectRoot\modules\Summary.psm1" -Force
Import-Module "$ProjectRoot\modules\Undo.psm1" -Force
Import-Module "$ProjectRoot\modules\Watcher.psm1" -Force
Import-Module "$ProjectRoot\modules\Scheduler.psm1" -Force
Import-Module "$ProjectRoot\modules\ReportGenerator.psm1" -Force
Import-Module "$ProjectRoot\modules\GUI.psm1" -Force

# Launch Desktop GUI Mode if -GUI is specified or run without parameters in interactive session
$isInteractiveNoArgs = (-not $PSBoundParameters.Count -and [Environment]::UserInteractive)

if ($GUI -or $isInteractiveNoArgs) {
    Show-OrganizerGUI -ConfigPath (Join-Path $ProjectRoot "config.json")
    return
}

# Background Process Launcher
if ($Background) {
    Start-Process powershell.exe `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$currentPath`" -Silent" `
        -WindowStyle Hidden
    return
}

function Write-HostConditional {
    param([string]$Message = "")
    if (-not $Silent) {
        Write-Host $Message
    }
}

$startTime = Get-Date
$logFile = $null

try {

    Write-HostConditional ""
    Write-HostConditional "========================================="
    Write-HostConditional "        DOWNLOAD ORGANIZER PRO"
    Write-HostConditional "            Version 2.1"
    Write-HostConditional "========================================="
    Write-HostConditional ""

    # Statistics Report Dashboard Mode
    if ($Report) {
        $stats = Get-OrganizerStatistics -LogPath "$ProjectRoot\logs"
        Write-HostConditional "========================================="
        Write-HostConditional "    DOWNLOAD ORGANIZER STATISTICS"
        Write-HostConditional "========================================="
        Write-HostConditional "Total Executions Logged : $($stats.TotalExecutions)"
        Write-HostConditional "Total Files Moved      : $($stats.TotalMoved)"
        Write-HostConditional "Total Operations Failed: $($stats.TotalFailed)"
        Write-HostConditional "========================================="
        return
    }

    # Real-Time Watcher Execution
    if ($Watcher) {
        $config = Get-OrganizerConfig -Path (Join-Path $ProjectRoot "config.json")
        Write-HostConditional "Starting Folder Watcher for: $($config.Settings.DownloadsPath)..."
        $watcherInst = Start-OrganizerWatcher `
            -Path $config.Settings.DownloadsPath `
            -ScriptPath $currentPath `
            -DebounceSeconds ([int]$config.Settings.WatcherDebounceSeconds)
        Write-HostConditional "Folder Watcher Active. Press Ctrl+C to stop."
        return
    }

    # Undo Mode Execution
    if ($Undo) {
        $undoLogs = Get-UndoLog -LogPath "$ProjectRoot\logs"
        if ($undoLogs.Count -eq 0) {
            Write-HostConditional "No transaction logs found for undo operation."
            return
        }
        $latestTransaction = $undoLogs[0].FullName
        Write-HostConditional "Executing Undo operation using: $($undoLogs[0].Name)"
        $undoResult = Invoke-UndoOperation -TransactionFile $latestTransaction
        Write-HostConditional "Undo Completed: $($undoResult.RestoredCount) file(s) restored, $($undoResult.FailedCount) failed."
        return
    }

    $config = Get-OrganizerConfig `
        -Path (Join-Path $ProjectRoot "config.json")

    $logFile = Initialize-Logger `
        -LogPath (Join-Path $ProjectRoot "logs")

    Write-OrganizerLog `
        -LogFile $logFile `
        -Message "Organizer Started"

    $isDryRun = $DryRun.IsPresent -or [bool]$config.Settings.DryRun
    $isRecurse = $Recurse.IsPresent -or [bool]$config.Settings.Recursive

    if ($isDryRun) {
        Write-HostConditional "[DRY-RUN MODE ACTIVE] No files will be moved."
    }

    $downloadPath = $config.Settings.DownloadsPath

    Write-HostConditional "Scanning Downloads..."

    $files = Get-DownloadFiles `
        -Path $downloadPath `
        -Recurse:$isRecurse `
        -IgnorePatterns $config.Settings.IgnorePatterns `
        -MinAgeDays ([int]$config.Settings.MinAgeDays) `
        -MaxAgeDays ([int]$config.Settings.MaxAgeDays) `
        -MinSizeBytes ([Int64]$config.Settings.MinSizeBytes) `
        -MaxSizeBytes ([Int64]$config.Settings.MaxSizeBytes)

    if ($files.Count -eq 0) {

        Write-HostConditional ""
        Write-HostConditional "No files found matching criteria."

        Write-OrganizerLog `
            -LogFile $logFile `
            -Level WARNING `
            -Message "No files found matching criteria."

        return
    }

    Write-HostConditional "$($files.Count) file(s) found."

    $classifiedFiles = Set-FileCategory `
        -Files $files `
        -Categories $config.Categories

    if ($config.Settings.EnableSmartRules) {

        $classifiedFiles = Invoke-SmartClassification `
            -Files $classifiedFiles `
            -SmartRules $config.SmartRules

    }

    $moveResults = Move-OrganizerFiles `
        -Files $classifiedFiles `
        -BasePath $downloadPath `
        -DryRun:$isDryRun `
        -TransactionPath (Join-Path $ProjectRoot "logs")

    Write-MoveLog `
        -LogFile $logFile `
        -Results $moveResults

    $summary = Get-OrganizerSummary `
        -Files $classifiedFiles `
        -Results $moveResults `
        -StartTime $startTime `
        -EndTime (Get-Date)

    Write-OrganizerLog `
        -LogFile $logFile `
        -Level SUCCESS `
        -Message "Organizer completed."

    # Generate Reports
    $dateStamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $reportsDir = Join-Path $ProjectRoot "logs\reports"

    if ($ExportCSV -or [bool]$config.Settings.ExportCSV) {
        $csvFile = Join-Path $reportsDir "report-$dateStamp.csv"
        Export-OrganizerCSV -Results $moveResults -OutputPath $csvFile | Out-Null
        Write-HostConditional "CSV Report exported: $csvFile"
    }

    if ($ExportJSON -or [bool]$config.Settings.ExportJSON) {
        $jsonFile = Join-Path $reportsDir "report-$dateStamp.json"
        Export-OrganizerJSON -Summary $summary -Results $moveResults -OutputPath $jsonFile | Out-Null
        Write-HostConditional "JSON Report exported: $jsonFile"
    }

    if ($ExportHTML -or [bool]$config.Settings.ExportHTML) {
        $htmlFile = Join-Path $reportsDir "report-$dateStamp.html"
        Export-OrganizerHTMLReport -Summary $summary -Results $moveResults -OutputPath $htmlFile | Out-Null
        Write-HostConditional "HTML Dashboard Report exported: $htmlFile"
    }

    if (-not $Silent) {
        Show-OrganizerSummary `
            -Summary $summary `
            -LogFile $logFile
    }

}
catch {

    Write-HostConditional ""
    Write-HostConditional "ERROR"
    Write-HostConditional $_.Exception.Message
    Write-HostConditional ""

    if ($logFile) {

        Write-OrganizerLog `
            -LogFile $logFile `
            -Level ERROR `
            -Message $_.Exception.Message

    }

    exit 1

}