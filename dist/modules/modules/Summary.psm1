Set-StrictMode -Version Latest

#region Public Functions

<#
.SYNOPSIS
Calculates execution summary statistics and returns an OrganizerSummary object.

.DESCRIPTION
Aggregates file counts, success/failure status, total file sizes in MB, category distribution, and duration into a strongly typed OrganizerSummary object.

.PARAMETER Files
Array of scanned OrganizerFile objects.

.PARAMETER Results
Array of move result objects.

.PARAMETER StartTime
Execution start timestamp.

.PARAMETER EndTime
Execution end timestamp.

.OUTPUTS
OrganizerSummary

.EXAMPLE
Get-OrganizerSummary -Files $files -Results $results -StartTime $start -EndTime $end
#>
function Get-OrganizerSummary {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [array]$Files,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [array]$Results,

        [Parameter(Mandatory)]
        [datetime]$StartTime,

        [Parameter(Mandatory)]
        [datetime]$EndTime

    )

    $summary = New-OrganizerSummary

    $movedFiles = $Results | Where-Object { $_.Status -eq "Moved" }
    $failedFiles = $Results | Where-Object { $_.Status -eq "Failed" }
    $skippedFiles = $Results | Where-Object { $_.Status -eq "Skipped" }

    $summary.TotalFiles = $Files.Count
    $summary.Moved = if ($null -ne $movedFiles) { @($movedFiles).Count } else { 0 }
    $summary.Failed = if ($null -ne $failedFiles) { @($failedFiles).Count } else { 0 }
    $summary.Skipped = if ($null -ne $skippedFiles) { @($skippedFiles).Count } else { 0 }

    $totalBytes = ($Files | Measure-Object -Property SizeBytes -Sum).Sum

    if ($null -ne $totalBytes) {
        $summary.TotalSizeMB = [Math]::Round($totalBytes / 1MB, 2)
    }
    else {
        $summary.TotalSizeMB = 0.0
    }

    $summary.Duration = $EndTime - $StartTime

    $grouped = $Files | Group-Object Category | Sort-Object Count -Descending
    foreach ($group in $grouped) {
        $summary.Categories[$group.Name] = $group.Count
    }

    return $summary

}

<#
.SYNOPSIS
Displays the execution summary report to the console.

.PARAMETER Summary
OrganizerSummary object containing execution statistics.

.PARAMETER LogFile
Optional path to the log file to display.
#>
function Show-OrganizerSummary {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $Summary,

        [Parameter(Mandatory = $false)]
        [string]$LogFile

    )

    Write-Host ""
    Write-Host "===================================="
    Write-Host " DOWNLOAD ORGANIZER PRO REPORT"
    Write-Host "===================================="
    Write-Host ""

    $scanned = if ($null -ne $Summary.TotalFiles) { $Summary.TotalFiles } else { $Summary.TotalScanned }
    $moved   = if ($null -ne $Summary.Moved) { $Summary.Moved } else { $Summary.TotalMoved }
    $failed  = if ($null -ne $Summary.Failed) { $Summary.Failed } else { $Summary.TotalFailed }

    Write-Host "Files scanned : $scanned"
    Write-Host "Files moved   : $moved"
    Write-Host "Failed        : $failed"
    Write-Host ""

    Write-Host "Total Size:"
    Write-Host "$($Summary.TotalSizeMB) MB"
    Write-Host ""

    Write-Host "Categories:"
    Write-Host ""

    if ($Summary.Categories -is [hashtable]) {
        foreach ($key in ($Summary.Categories.Keys | Sort-Object)) {
            Write-Host ("{0,-20} {1}" -f $key, $Summary.Categories[$key])
        }
    }
    elseif ($null -ne $Summary.Categories) {
        foreach ($category in $Summary.Categories) {
            Write-Host ("{0,-20} {1}" -f $category.Category, $category.Count)
        }
    }

    Write-Host ""
    Write-Host "Duration:"
    $durationSeconds = if ($Summary.Duration -is [timespan]) { $Summary.Duration.TotalSeconds } else { $Summary.Duration }
    Write-Host ("{0:N2} seconds" -f $durationSeconds)

    if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
        Write-Host ""
        Write-Host "Log:"
        Write-Host $LogFile
    }

    Write-Host ""
    Write-Host "===================================="

}

#endregion

Export-ModuleMember `
    -Function `
        Get-OrganizerSummary,
        Show-OrganizerSummary