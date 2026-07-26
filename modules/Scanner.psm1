Set-StrictMode -Version Latest

#region Private Functions

function Get-FileItems {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Recurse

    )

    if ($Recurse) {
        return Get-ChildItem `
            -LiteralPath $Path `
            -File `
            -Recurse `
            -Force `
            -ErrorAction Stop
    }
    else {
        return Get-ChildItem `
            -LiteralPath $Path `
            -File `
            -Force `
            -ErrorAction Stop
    }

}

function Test-FileShouldBeIgnored {

    param(

        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File,

        [array]$IgnorePatterns,

        [int]$MinAgeDays = 0,

        [int]$MaxAgeDays = 0,

        [Int64]$MinSizeBytes = 0,

        [Int64]$MaxSizeBytes = 0

    )

    # Check Glob Ignore Patterns
    if ($null -ne $IgnorePatterns) {
        foreach ($pattern in $IgnorePatterns) {
            if ($File.Name -like $pattern) {
                return $true
            }
        }
    }

    # Check File Age Rules (Days)
    $now = Get-Date
    $ageDays = ($now - $File.LastWriteTime).TotalDays

    if ($MinAgeDays -gt 0 -and $ageDays -lt $MinAgeDays) {
        return $true
    }

    if ($MaxAgeDays -gt 0 -and $ageDays -gt $MaxAgeDays) {
        return $true
    }

    # Check File Size Rules (Bytes)
    if ($MinSizeBytes -gt 0 -and $File.Length -lt $MinSizeBytes) {
        return $true
    }

    if ($MaxSizeBytes -gt 0 -and $File.Length -gt $MaxSizeBytes) {
        return $true
    }

    return $false

}

#endregion

#region Public Functions

<#
.SYNOPSIS
Scans a directory and returns OrganizerFile objects.

.DESCRIPTION
Enumerates files in the target directory (optionally recursively), filters by ignore patterns, age rules, and size rules, and converts each file into an OrganizerFile model.

.PARAMETER Path
Directory to scan.

.PARAMETER Recurse
Perform recursive directory scan.

.PARAMETER IgnorePatterns
Array of glob patterns to ignore (e.g. *.tmp, *.crdownload).

.PARAMETER MinAgeDays
Minimum file age in days.

.PARAMETER MaxAgeDays
Maximum file age in days.

.PARAMETER MinSizeBytes
Minimum file size in bytes.

.PARAMETER MaxSizeBytes
Maximum file size in bytes.

.EXAMPLE
Get-DownloadFiles -Path "$env:USERPROFILE\Downloads" -Recurse -IgnorePatterns @("*.tmp")
#>

function Get-DownloadFiles {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Recurse,

        [array]$IgnorePatterns = @(),

        [int]$MinAgeDays = 0,

        [int]$MaxAgeDays = 0,

        [Int64]$MinSizeBytes = 0,

        [Int64]$MaxSizeBytes = 0

    )

    Write-Verbose "Scanning: $Path (Recurse: $Recurse)"

    if (-not (Test-Path -LiteralPath $Path)) {

        throw "Directory not found: $Path"

    }

    $result = New-Object System.Collections.Generic.List[object]

    $fileItems = Get-FileItems -Path $Path -Recurse:$Recurse

    foreach ($file in $fileItems) {

        try {

            $shouldIgnore = Test-FileShouldBeIgnored `
                -File $file `
                -IgnorePatterns $IgnorePatterns `
                -MinAgeDays $MinAgeDays `
                -MaxAgeDays $MaxAgeDays `
                -MinSizeBytes $MinSizeBytes `
                -MaxSizeBytes $MaxSizeBytes

            if (-not $shouldIgnore) {

                $result.Add(
                    (New-OrganizerFile -File $file)
                )

            }

        }

        catch {

            Write-Verbose (
                "Skipping file '{0}' : {1}" -f `
                $file.Name,
                $_.Exception.Message
            )

        }

    }

    return $result

}

#endregion

Export-ModuleMember `
    -Function Get-DownloadFiles