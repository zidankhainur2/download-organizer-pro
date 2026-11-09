Set-StrictMode -Version Latest
foreach ($name in @('Utils', 'Validation', 'Scanner', 'Classifier', 'SmartClassifier', 'DuplicateDetector', 'Mover', 'Logger', 'Summary', 'ReportGenerator')) {
    Import-Module "$PSScriptRoot/$name.psm1"
}

<#
.SYNOPSIS
Runs the shared configuration, scan, classify, duplicate, move, logging, and report pipeline.
#>
function Invoke-Organizer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Config,
        [string]$DownloadsPath,
        [Parameter(Mandatory)][string]$OperationalPath,
        [ValidateSet('Rename', 'Skip', 'Overwrite')][string]$ConflictAction,
        $ProgressQueue
    )
    $start = Get-Date
    if ($DownloadsPath) { $Config.Settings.DownloadsPath = Resolve-EnvironmentPath $DownloadsPath }
    Test-OrganizerConfiguration $Config | Out-Null
    $settings = $Config.Settings
    if (-not $PSBoundParameters.ContainsKey('Verbose')) { $VerbosePreference = if ($settings.Verbose) { 'Continue' } else { 'SilentlyContinue' } }
    $target = Resolve-EnvironmentPath $settings.DownloadsPath
    $lock = Enter-OrganizerLock $target
    try {
        if (-not $ConflictAction) {
            $ConflictAction = if ($settings.PSObject.Properties['ConflictAction']) { $settings.ConflictAction }
            elseif ($settings.Overwrite) { 'Overwrite' } else { 'Rename' }
        }
        $logFile = ''
        if ($settings.CreateLogs) {
            $logFile = Initialize-Logger $OperationalPath
            Write-OrganizerLog $logFile -Message 'Organizer Started'
        }
        if ($ProgressQueue) { $ProgressQueue.Enqueue('Scanning and classifying files...') }
        $files = @(Get-DownloadFiles -Path $target -Recurse:$settings.Recursive -IgnorePatterns $settings.IgnorePatterns `
            -MinAgeDays $settings.MinAgeDays -MaxAgeDays $settings.MaxAgeDays -MinSizeBytes $settings.MinSizeBytes `
            -MaxSizeBytes $settings.MaxSizeBytes -ExcludePaths @($OperationalPath) -Verbose:($VerbosePreference -eq 'Continue'))
        if ($files.Count -gt 0) {
            $files = @(Set-FileCategory -Files $files -Categories $Config.Categories)
            if ($settings.EnableSmartRules) { $files = @(Invoke-SmartClassification -Files $files -SmartRules $Config.SmartRules) }
            if ($settings.EnableDuplicateDetection) { Get-DuplicateFiles -Files $files | Out-Null }
        }
        $results = @(Move-OrganizerFiles -Files $files -BasePath $target -DryRun:$settings.DryRun `
            -TransactionPath (Join-Path $OperationalPath 'transactions') -ConflictAction $ConflictAction `
            -MoveUnknownFiles $settings.MoveUnknownFiles -CreateCategoryFolders $settings.CreateCategoryFolders -LockHeld -ProgressQueue $ProgressQueue)
        $summary = Get-OrganizerSummary -Files $files -Results $results -StartTime $start -EndTime (Get-Date)
        if ($logFile) { Write-MoveLog $logFile -Results $results; Write-OrganizerLog $logFile -Message 'Organizer completed.' }
        $reports = @{}
        $stamp = (Get-Date -Format yyyyMMdd-HHmmss) + '-' + [guid]::NewGuid().ToString('N')
        foreach ($format in @('CSV', 'JSON', 'HTML')) {
            if (-not $settings."Export$format") { continue }
            $path = Join-Path $OperationalPath "reports/report-$stamp.$($format.ToLowerInvariant())"
            switch ($format) {
                CSV { Export-OrganizerCSV -Results $results -OutputPath $path | Out-Null }
                JSON { Export-OrganizerJSON -Summary $summary -Results $results -OutputPath $path | Out-Null }
                HTML { Export-OrganizerHTMLReport -Summary $summary -Results $results -OutputPath $path | Out-Null }
            }
            $reports[$format] = $path
        }
        [pscustomobject]@{ Files = $files; Results = $results; Summary = $summary; Reports = $reports; LogFile = $logFile }
    }
    finally { $lock.ReleaseMutex(); $lock.Dispose() }
}
Export-ModuleMember -Function Invoke-Organizer
