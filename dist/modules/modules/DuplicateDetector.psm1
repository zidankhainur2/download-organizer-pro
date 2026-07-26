Set-StrictMode -Version Latest

#region Public Functions

<#
.SYNOPSIS
Detects duplicate files using file size pre-filtering and SHA256 checksum comparisons.

.DESCRIPTION
Groups input OrganizerFile objects by SizeBytes. For size collisions with 2 or more files, computes SHA256 hashes using Get-FileSHA256 and sets SHA256Hash and IsDuplicate properties.

.PARAMETER Files
Array of OrganizerFile objects.

.OUTPUTS
OrganizerFile[] Array of duplicate OrganizerFile objects.

.EXAMPLE
Get-DuplicateFiles -Files $files
#>
function Get-DuplicateFiles {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [array]$Files

    )

    $duplicates = New-Object System.Collections.Generic.List[object]

    # Pre-filter by file size (SizeBytes)
    $sizeGroups = $Files | Where-Object { $_.SizeBytes -gt 0 } | Group-Object SizeBytes | Where-Object { $_.Count -gt 1 }

    foreach ($group in $sizeGroups) {

        # Compute SHA256 hash for items in size group
        foreach ($file in $group.Group) {
            if ([string]::IsNullOrWhiteSpace($file.SHA256Hash) -and (Test-Path -LiteralPath $file.FullPath)) {
                $file.SHA256Hash = Get-FileSHA256 -Path $file.FullPath
            }
        }

        $hashGroups = $group.Group | Group-Object SHA256Hash | Where-Object { $_.Count -gt 1 }

        foreach ($hashGroup in $hashGroups) {

            $first = $true
            foreach ($file in $hashGroup.Group) {
                if (-not $first) {
                    $file.IsDuplicate = $true
                    $duplicates.Add($file)
                }
                else {
                    $first = $false
                }
            }

        }

    }

    return $duplicates

}

<#
.SYNOPSIS
Tests if two files have identical SHA256 hashes.

.PARAMETER Path1
First file path.

.PARAMETER Path2
Second file path.

.OUTPUTS
[bool]
#>
function Test-FileDuplicate {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path1,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path2

    )

    if (-not (Test-Path -LiteralPath $Path1) -or -not (Test-Path -LiteralPath $Path2)) {
        return $false
    }

    $fileInfo1 = Get-Item -LiteralPath $Path1
    $fileInfo2 = Get-Item -LiteralPath $Path2

    if ($fileInfo1.Length -ne $fileInfo2.Length) {
        return $false
    }

    $hash1 = Get-FileSHA256 -Path $Path1
    $hash2 = Get-FileSHA256 -Path $Path2

    return ($hash1 -eq $hash2)

}

#endregion

Export-ModuleMember `
    -Function `
        Get-DuplicateFiles,
        Test-FileDuplicate
