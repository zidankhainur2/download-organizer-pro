Set-StrictMode -Version Latest

#region Public Functions

<#
.SYNOPSIS
Moves classified OrganizerFile objects to their target destination folders.

.DESCRIPTION
Iterates through classified OrganizerFile instances, creates required target directory hierarchies, resolves filename duplicates, updates file status, and optionally writes transaction history logs and supports DryRun simulation mode.

.PARAMETER Files
Array of OrganizerFile objects to move.

.PARAMETER BasePath
Root target directory (e.g., Downloads folder path).

.PARAMETER DryRun
Simulate move operations without modifying disk contents.

.PARAMETER TransactionPath
Optional directory path to write transaction manifest JSON for undo operations.

.OUTPUTS
PSCustomObject[] Array of move operation summary results.

.EXAMPLE
Move-OrganizerFiles -Files $classifiedFiles -BasePath $downloadPath -DryRun
#>
function Move-OrganizerFiles {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [array]$Files,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BasePath,

        [switch]$DryRun,

        [string]$TransactionPath = ""

    )

    $results = New-Object System.Collections.Generic.List[PSCustomObject]
    $movesForTransaction = New-Object System.Collections.Generic.List[PSCustomObject]

    $total = $Files.Count
    $current = 0

    foreach ($file in $Files) {

        $current++

        $current++

        try {

            $targetFolder = Join-Path `
                $BasePath `
                $file.DestinationPath

            if (-not $DryRun) {
                Initialize-Directory -Path $targetFolder | Out-Null
            }

            $destination = Join-Path `
                $targetFolder `
                $file.Name

            if (-not $DryRun) {
                $destination = New-UniqueFilePath `
                    -Destination $destination

                Move-Item `
                    -Path $file.FullPath `
                    -Destination $destination

                $file.MarkMoved($destination)

                $movesForTransaction.Add(
                    [PSCustomObject]@{
                        SourcePath      = $file.FullPath
                        DestinationPath = $destination
                    }
                )
            }
            else {
                $file.MarkSkipped("DryRun Mode")
            }

            $results.Add(
                [PSCustomObject]@{
                    File        = $file.Name
                    Category    = $file.Category
                    SubCategory = $file.SubCategory
                    Status      = if ($DryRun) { "Moved (DryRun)" } else { "Moved" }
                    Destination = $destination
                }
            )

        }
        catch {

            $reason = $_.Exception.Message
            $file.MarkFailed($reason)

            $results.Add(
                [PSCustomObject]@{
                    File        = $file.Name
                    Category    = $file.Category
                    SubCategory = $file.SubCategory
                    Status      = "Failed"
                    Destination = $reason
                }
            )

        }

    }

    # Removed Write-Progress

    # Write Transaction Manifest if enabled and not DryRun
    if (-not $DryRun -and -not [string]::IsNullOrWhiteSpace($TransactionPath) -and $movesForTransaction.Count -gt 0) {
        try {
            Initialize-Directory -Path $TransactionPath | Out-Null
            $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
            $manifestPath = Join-Path $TransactionPath "transaction-$timestamp.json"

            $manifestObj = [PSCustomObject]@{
                Timestamp = (Get-Date -Format "o")
                Moves     = $movesForTransaction
            }

            $jsonContent = $manifestObj | ConvertTo-Json -Depth 5
            Set-Content -Path $manifestPath -Value $jsonContent
        }
        catch {
            Write-Verbose "Failed to write transaction log: $_"
        }
    }

    return $results

}

<#
.SYNOPSIS
Alias wrapper for Move-OrganizerFiles.
#>
function Move-OrganizedFiles {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [array]$Files,

        [Parameter(Mandatory)]
        [string]$BasePath,

        [switch]$DryRun

    )

    return Move-OrganizerFiles `
        -Files $Files `
        -BasePath $BasePath `
        -DryRun:$DryRun

}

#endregion

Export-ModuleMember `
    -Function `
        Move-OrganizerFiles,
        Move-OrganizedFiles