Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/Utils.psm1"

function Write-TransactionProgress {
    [CmdletBinding()]
    param([string]$Path, $Entry, [string]$State)
    $record = @{ Id = $Entry.Id; State = $State } | ConvertTo-Json -Compress
    $stream = [IO.File]::Open($Path + '.progress', [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::Read)
    try {
        if ($stream.Length -gt 0) {
            $stream.Position = $stream.Length - 1
            if ($stream.ReadByte() -ne 10) {
                $stream.Position = 0
                $buffer = New-Object byte[] $stream.Length
                $null = $stream.Read($buffer, 0, $buffer.Length)
                $lastNewline = [array]::LastIndexOf($buffer, [byte]10)
                $stream.SetLength($lastNewline + 1)
            }
        }
        $stream.Position = $stream.Length
        $bytes = [Text.Encoding]::UTF8.GetBytes($record + "`n")
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    }
    finally { $stream.Dispose() }
    $Entry.State = $State
}

function Read-OrganizerTransaction {
    [CmdletBinding()]
    param([string]$Path)
    $manifest = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $index = @{}
    $i = 0
    foreach ($entry in $manifest.Moves) {
        if (-not $entry.PSObject.Properties['Id']) {
            $entry | Add-Member Id ([string]$i)
            $entry | Add-Member State 'Moved'
            $entry | Add-Member BackupPath ''
            $entry | Add-Member SourceHash ''
            $entry | Add-Member BackupHash ''
        }
        $index[$entry.Id] = $entry
        $i++
    }
    if (Test-Path -LiteralPath ($Path + '.progress')) {
        $lines = @(Get-Content -LiteralPath ($Path + '.progress') -Encoding UTF8 -ErrorAction Stop)
        for ($n = 0; $n -lt $lines.Count; $n++) {
            try { $record = $lines[$n] | ConvertFrom-Json -ErrorAction Stop }
            catch {
                # A crash can leave the final append incomplete; disk contents are checked during recovery.
                if ($n -eq $lines.Count - 1) { break }
                throw
            }
            if (-not $index.ContainsKey($record.Id)) { throw 'Unknown transaction entry in progress journal.' }
            $index[$record.Id].State = $record.State
        }
    }
    return $manifest
}

Export-ModuleMember -Function Write-TransactionProgress, Read-OrganizerTransaction
