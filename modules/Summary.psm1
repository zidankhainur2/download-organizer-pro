Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/Models.psm1"
Import-Module "$PSScriptRoot/Utils.psm1"

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
        [AllowEmptyCollection()][array]$Files,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [AllowEmptyCollection()][array]$Results,

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
    $summary.Planned = @($Results | Where-Object { $_.Status -eq 'Planned' }).Count
    $summary.Duplicates = @($Files | Where-Object { $_.IsDuplicate }).Count

    $totalBytes = 0L
    foreach ($file in $Files) { $totalBytes += $file.SizeBytes }

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

    $lines = @(
        'Download Organizer Pro report'
        "Files scanned: $($Summary.TotalFiles)"
        "Moved: $($Summary.Moved); Failed: $($Summary.Failed); Skipped: $($Summary.Skipped); Planned: $($Summary.Planned)"
        "Duplicates: $($Summary.Duplicates); Size: $($Summary.TotalSizeMB) MB"
        "Duration: $(Format-Duration $Summary.Duration)"
    )
    foreach ($key in ($Summary.Categories.Keys | Sort-Object)) { $lines += "$key : $($Summary.Categories[$key])" }
    if ($LogFile) { $lines += "Log: $LogFile" }
    $lines -join "`n"

}

#endregion

Export-ModuleMember `
    -Function `
        Get-OrganizerSummary,
        Show-OrganizerSummary
