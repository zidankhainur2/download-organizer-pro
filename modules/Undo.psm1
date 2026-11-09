Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/Utils.psm1"
Import-Module "$PSScriptRoot/Transactions.psm1"

<#
.SYNOPSIS
Lists incomplete transaction manifests, newest first.
#>
function Get-UndoLog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$LogPath)
    if (-not (Test-Path -LiteralPath $LogPath)) { return ,@() }
    return ,@(Get-ChildItem -LiteralPath $LogPath -Filter 'transaction-*.json' -File -ErrorAction Stop | Sort-Object LastWriteTime -Descending)
}

<#
.SYNOPSIS
Restores transaction entries in reverse order without replacing occupied sources.
#>
function Invoke-UndoOperation {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$TransactionFile)
    $TransactionFile = Resolve-EnvironmentPath $TransactionFile
    $manifest = Read-OrganizerTransaction $TransactionFile
    $basePath = if ($manifest.PSObject.Properties['BasePath']) { $manifest.BasePath } else {
        # Legacy transactions have no root; find their common ancestor.
        $root = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($manifest.Moves[0].SourcePath))
        foreach ($entry in $manifest.Moves) {
            foreach ($path in @($entry.SourcePath, $entry.DestinationPath)) {
                while (-not ([IO.Path]::GetFullPath($path)).StartsWith($root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
                    $root = [IO.Path]::GetDirectoryName($root)
                    if (-not $root) { throw 'Legacy transaction has no common target directory.' }
                }
            }
        }
        $root
    }
    $lock = Enter-OrganizerLock $basePath
    try {
        $restored = 0
        $errors = [Collections.Generic.List[string]]::new()
        $entries = @($manifest.Moves)
        [array]::Reverse($entries)
        foreach ($entry in $entries) {
            if ($entry.State -eq 'Undone') { continue }
            try {
                $null = Assert-ContainedPath $entry.SourcePath $basePath
                $null = Assert-ContainedPath $entry.DestinationPath $basePath
                $sourceExists = Test-Path -LiteralPath $entry.SourcePath
                $destinationExists = Test-Path -LiteralPath $entry.DestinationPath
                $sourceIsOriginal = $sourceExists -and $entry.SourceHash -and ((Get-FileSHA256 $entry.SourcePath) -eq $entry.SourceHash)
                if ($entry.State -eq 'SourceReturned' -and (-not $sourceExists -or ($entry.SourceHash -and -not $sourceIsOriginal))) { throw 'Restored source changed or disappeared.' }
                if ($entry.State -ne 'SourceReturned') {
                    if ($sourceExists -and -not $sourceIsOriginal) { throw "Undo conflict at source: $($entry.SourcePath)" }
                    if ($destinationExists -and -not $sourceExists) {
                        if ($entry.SourceHash -and (Get-FileSHA256 $entry.DestinationPath) -ne $entry.SourceHash) { throw 'Destination content changed; manual recovery required.' }
                        Initialize-Directory ([IO.Path]::GetDirectoryName($entry.SourcePath)) | Out-Null
                        [IO.File]::Move($entry.DestinationPath, $entry.SourcePath)
                    }
                    elseif (-not $sourceExists) { throw 'Both source and destination are missing.' }
                    elseif ($destinationExists -and $entry.State -eq 'Moved') { throw "Undo conflict at source: $($entry.SourcePath)" }
                }
            }
            catch { $errors.Add($_.Exception.Message); continue }
            Write-TransactionProgress $TransactionFile $entry 'SourceReturned'
            try {
                if ($entry.BackupPath -and (Test-Path -LiteralPath $entry.BackupPath)) {
                    $null = Assert-ContainedPath $entry.BackupPath ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($TransactionFile)))
                    if (Test-Path -LiteralPath $entry.DestinationPath) { throw 'Undo backup destination is occupied.' }
                    if ($entry.BackupHash -and (Get-FileSHA256 $entry.BackupPath) -ne $entry.BackupHash) { throw 'Backup content changed.' }
                    [IO.File]::Move($entry.BackupPath, $entry.DestinationPath)
                }
                elseif ($entry.BackupPath -and $entry.BackupHash) {
                    if (-not (Test-Path -LiteralPath $entry.DestinationPath) -or (Get-FileSHA256 $entry.DestinationPath) -ne $entry.BackupHash) { throw 'Overwrite backup is missing.' }
                }
            }
            catch { $errors.Add($_.Exception.Message); continue }
            Write-TransactionProgress $TransactionFile $entry 'Undone'
            $restored++
        }
        if ($errors.Count -eq 0) { Move-Item -LiteralPath $TransactionFile -Destination ($TransactionFile + '.undone') -ErrorAction Stop }
        [pscustomobject]@{ TransactionFile = $TransactionFile; RestoredCount = $restored; FailedCount = $errors.Count; Errors = $errors.ToArray() }
    }
    finally { $lock.ReleaseMutex(); $lock.Dispose() }
}
Export-ModuleMember -Function Get-UndoLog, Invoke-UndoOperation
