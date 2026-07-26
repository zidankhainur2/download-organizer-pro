Set-StrictMode -Version Latest

#region Public Functions

<#
.SYNOPSIS
Lists recent transaction history log files.

.PARAMETER LogPath
Directory where transaction logs are stored.

.OUTPUTS
[System.IO.FileInfo[]]
#>
function Get-UndoLog {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath

    )

    if (-not (Test-Path -LiteralPath $LogPath)) {
        return @()
    }

    return Get-ChildItem `
        -LiteralPath $LogPath `
        -Filter "transaction-*.json" `
        -File |
        Sort-Object LastWriteTime -Descending

}

<#
.SYNOPSIS
Restores moved files back to their original source paths using a transaction log manifest.

.PARAMETER TransactionFile
Path to transaction JSON manifest file.

.OUTPUTS
PSCustomObject Summary of restored files.

.EXAMPLE
Invoke-UndoOperation -TransactionFile ".\logs\transaction-2026-07-26-120000.json"
#>
function Invoke-UndoOperation {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TransactionFile

    )

    if (-not (Test-Path -LiteralPath $TransactionFile)) {
        throw "Transaction manifest file not found: $TransactionFile"
    }

    try {
        $manifest = Get-Content -LiteralPath $TransactionFile -Raw | ConvertFrom-Json
    }
    catch {
        throw "Invalid transaction manifest JSON file."
    }

    $restoredCount = 0
    $failedCount = 0

    foreach ($entry in $manifest.Moves) {

        try {

            if (Test-Path -LiteralPath $entry.DestinationPath) {

                $sourceDir = Split-Path $entry.SourcePath
                if (-not (Test-Path -LiteralPath $sourceDir)) {
                    New-Item -ItemType Directory -Path $sourceDir -Force | Out-Null
                }

                Move-Item `
                    -LiteralPath $entry.DestinationPath `
                    -Destination $entry.SourcePath `
                    -Force

                $restoredCount++

            }

        }
        catch {

            $failedCount++

        }

    }

    return [PSCustomObject]@{
        TransactionFile = $TransactionFile
        RestoredCount   = $restoredCount
        FailedCount     = $failedCount
    }

}

#endregion

Export-ModuleMember `
    -Function `
        Get-UndoLog,
        Invoke-UndoOperation
