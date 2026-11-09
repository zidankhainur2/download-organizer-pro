Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/Utils.psm1"
Import-Module "$PSScriptRoot/Transactions.psm1"

<#
.SYNOPSIS
Plans literal destinations and moves files with durable, recoverable transactions.
#>
function Move-OrganizerFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][array]$Files,
        [Parameter(Mandatory)][string]$BasePath,
        [switch]$DryRun,
        [string]$TransactionPath = '',
        [ValidateSet('Rename', 'Skip', 'Overwrite')][string]$ConflictAction = 'Rename',
        [bool]$MoveUnknownFiles = $true,
        [bool]$CreateCategoryFolders = $true,
        [switch]$LockHeld,
        $ProgressQueue
    )
    $BasePath = Resolve-EnvironmentPath $BasePath
    $lock = $null
    if (-not $LockHeld) { $lock = Enter-OrganizerLock $BasePath }
    try {
        $results = [Collections.Generic.List[object]]::new()
        $entries = [Collections.Generic.List[object]]::new()
        $reserved = @{}
        $counters = @{}
        $transactionId = [guid]::NewGuid().ToString('N')
        if (-not $TransactionPath) { $TransactionPath = Join-Path $BasePath '.organizer/transactions' }
        $TransactionPath = Resolve-EnvironmentPath $TransactionPath
        $manifestPath = Join-Path $TransactionPath "transaction-$transactionId.json"
        foreach ($file in $Files) {
            $destination = ''
            try {
                Assert-DirectoryComponent $file.Category
                if ($file.SubCategory) { Assert-DirectoryComponent $file.SubCategory }
                Assert-DirectoryComponent $file.Name
                $source = Assert-ContainedPath $file.FullPath $BasePath
                $targetFolder = Join-Path $BasePath $file.Category
                if ($file.SubCategory) { $targetFolder = Join-Path $targetFolder $file.SubCategory }
                $destination = Assert-ContainedPath (Join-Path $targetFolder $file.Name) $BasePath
                if ($source.Equals($destination, [StringComparison]::OrdinalIgnoreCase)) {
                    $file.MarkSkipped('Already at destination')
                }
                elseif (-not $MoveUnknownFiles -and $file.Category -eq 'Others') {
                    $file.MarkSkipped('Unknown files disabled')
                }
                elseif (-not $CreateCategoryFolders -and -not (Test-Path -LiteralPath $targetFolder -PathType Container)) {
                    $file.MarkSkipped('Category folder does not exist')
                }
                else {
                    $occupied = $reserved.ContainsKey($destination) -or (Test-Path -LiteralPath $destination)
                    if ($occupied -and $ConflictAction -eq 'Skip') { $file.MarkSkipped('Destination exists') }
                    else {
                        if ($occupied -and $ConflictAction -eq 'Rename') {
                            $original = $destination
                            $number = if ($counters.ContainsKey($original)) { $counters[$original] } else { 1 }
                            do {
                                $destination = Join-Path $targetFolder ('{0} ({1}){2}' -f [IO.Path]::GetFileNameWithoutExtension($file.Name), $number, [IO.Path]::GetExtension($file.Name))
                                $number++
                            } while ($reserved.ContainsKey($destination) -or (Test-Path -LiteralPath $destination))
                            $counters[$original] = $number
                        }
                        $backup = ''
                        if ($occupied -and $ConflictAction -eq 'Overwrite') {
                            if (Test-Path -LiteralPath $destination -PathType Container) { throw 'Destination is a directory.' }
                            $backup = Join-Path $TransactionPath "backups/$transactionId/$($entries.Count).bak"
                        }
                        $entry = [pscustomobject]@{
                            Id = [string]$entries.Count; SourcePath = $source; DestinationPath = $destination
                            BackupPath = $backup; SourceHash = ''; BackupHash = ''; State = 'Intent'
                        }
                        if (-not $DryRun) {
                            $entry.SourceHash = Get-FileSHA256 $source
                            if ($backup) {
                                $entry.BackupHash = if ($reserved.ContainsKey($destination)) { $reserved[$destination] } else { Get-FileSHA256 $destination }
                            }
                        }
                        $reserved[$destination] = $entry.SourceHash
                        $entries.Add($entry)
                        $file.MarkPlanned($destination)
                    }
                }
            }
            catch { $file.MarkFailed($_.Exception.Message) }
            $results.Add([pscustomobject]@{
                File = $file.Name; Category = $file.Category; SubCategory = $file.SubCategory
                Status = $file.Status.ToString(); Destination = $destination; Reason = $file.ErrorMessage
                IsDuplicate = $file.IsDuplicate; SHA256Hash = $file.SHA256Hash
            })
        }
        if (-not $DryRun -and $entries.Count -gt 0) {
            $null = Assert-ContainedPath $manifestPath $TransactionPath
            Initialize-Directory $TransactionPath | Out-Null
            $manifest = [pscustomobject]@{
                Version = 2; Id = $transactionId; Timestamp = (Get-Date -Format o)
                BasePath = [IO.Path]::GetFullPath($BasePath); Moves = @($entries.ToArray())
            }
            # Persist all intent before the first disk mutation.
            $pendingPath = $manifestPath + '.pending'
            $stream = [IO.File]::Open($pendingPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
            try {
                $bytes = [Text.Encoding]::UTF8.GetBytes(($manifest | ConvertTo-Json -Depth 6))
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Flush($true)
            }
            finally { $stream.Dispose() }
            [IO.File]::Move($pendingPath, $manifestPath)
            $entryIndex = 0
            for ($i = 0; $i -lt $Files.Count; $i++) {
                $file = $Files[$i]
                if ($file.Status.ToString() -ne 'Planned') { continue }
                $entry = $entries[$entryIndex++]
                # Journal failures stop the batch and leave persisted intent for recovery.
                $errorMessage = ''
                try {
                    $null = Assert-ContainedPath $entry.SourcePath $BasePath
                    $null = Assert-ContainedPath $entry.DestinationPath $BasePath
                    Initialize-Directory ([IO.Path]::GetDirectoryName($entry.DestinationPath)) | Out-Null
                    if ($entry.BackupPath) {
                        $null = Assert-ContainedPath $entry.BackupPath $TransactionPath
                        if (-not (Test-Path -LiteralPath $entry.DestinationPath -PathType Leaf)) { throw 'Overwrite destination changed after planning.' }
                        if ($entry.BackupHash -and (Get-FileSHA256 $entry.DestinationPath) -ne $entry.BackupHash) { throw 'Overwrite destination changed after planning.' }
                        Initialize-Directory ([IO.Path]::GetDirectoryName($entry.BackupPath)) | Out-Null
                        [IO.File]::Move($entry.DestinationPath, $entry.BackupPath)
                    }
                }
                catch { $errorMessage = $_.Exception.Message }
                if (-not $errorMessage) {
                    if ($entry.BackupPath) { Write-TransactionProgress $manifestPath $entry 'BackupReady' }
                    try {
                        if ((Get-FileSHA256 $entry.SourcePath) -ne $entry.SourceHash) { throw 'Source content changed after planning.' }
                        [IO.File]::Move($entry.SourcePath, $entry.DestinationPath)
                        $file.MarkMoved($entry.DestinationPath)
                    }
                    catch { $errorMessage = $_.Exception.Message }
                }
                if ($errorMessage) { $file.MarkFailed($errorMessage) }
                Write-TransactionProgress $manifestPath $entry $(if ($errorMessage) { 'Failed' } else { 'Moved' })
                $results[$i].Status = $file.Status.ToString()
                $results[$i].Reason = $file.ErrorMessage
                if ($ProgressQueue) { $ProgressQueue.Enqueue("$($i + 1)/$($Files.Count): $($results[$i].Status) $($file.Name)") }
            }
        }
        return $results.ToArray()
    }
    finally { if ($lock) { $lock.ReleaseMutex(); $lock.Dispose() } }
}

<#
.SYNOPSIS
Compatibility entrypoint for moving classified files.
#>
function Move-OrganizedFiles {
    [CmdletBinding()]
    param([Parameter(Mandatory)][array]$Files, [Parameter(Mandatory)][string]$BasePath, [switch]$DryRun)
    Move-OrganizerFiles -Files $Files -BasePath $BasePath -DryRun:$DryRun
}
Export-ModuleMember -Function Move-OrganizerFiles, Move-OrganizedFiles
