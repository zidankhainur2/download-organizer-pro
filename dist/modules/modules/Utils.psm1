Set-StrictMode -Version Latest

#region Private Functions

function Test-IsNullOrWhiteSpace {

    param(
        [AllowNull()]
        [string]$Value
    )

    return [string]::IsNullOrWhiteSpace($Value)

}

#endregion

#region Public Functions

<#
.SYNOPSIS
Converts bytes to megabytes.
#>
function Convert-BytesToMB {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [Int64]$Bytes

    )

    return [Math]::Round(
        ($Bytes / 1MB),
        2
    )

}

<#
.SYNOPSIS
Normalizes a filename for keyword matching.
#>
function Format-FileName {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [string]$Name

    )

    $normalized = $Name.ToLower()

    $normalized = $normalized.Replace("_"," ")
    $normalized = $normalized.Replace("-"," ")
    $normalized = $normalized.Replace("."," ")

    return $normalized

}

function Normalize-FileName {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)
    return Format-FileName -Name $Name
}

<#
.SYNOPSIS
Expands environment variables inside a path.
#>
function Resolve-EnvironmentPath {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [string]$Path

    )

    return [Environment]::ExpandEnvironmentVariables(
        $Path
    )

}

<#
.SYNOPSIS
Creates directory if it doesn't exist.
#>
function Initialize-Directory {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [string]$Path

    )

    if (-not (Test-Path $Path)) {

        New-Item `
            -ItemType Directory `
            -Path $Path `
            -Force | Out-Null

    }

    return $Path

}

function Ensure-Directory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    return Initialize-Directory -Path $Path
}

<#
.SYNOPSIS
Returns a unique destination filename.
#>
function New-UniqueFilePath {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [string]$Destination

    )

    if (-not (Test-Path $Destination)) {

        return $Destination

    }

    $directory =
        Split-Path $Destination

    $filename =
        [IO.Path]::GetFileNameWithoutExtension(
            $Destination
        )

    $extension =
        [IO.Path]::GetExtension(
            $Destination
        )

    $counter = 1

    do {

        $candidate =
            Join-Path `
                $directory `
                (
                    "{0} ({1}){2}" -f `
                    $filename,
                    $counter,
                    $extension
                )

        $counter++

    }
    until (-not (Test-Path $candidate))

    return $candidate

}

<#
.SYNOPSIS
Returns SHA256 hash of a file.
#>
function Get-FileSHA256 {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [string]$Path

    )

    return (
        Get-FileHash `
            -Algorithm SHA256 `
            -Path $Path
    ).Hash

}

<#
.SYNOPSIS
Formats elapsed time.
#>
function Format-Duration {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [timespan]$Duration

    )

    if ($Duration.TotalSeconds -lt 60) {

        return "{0:N2} sec" -f `
            $Duration.TotalSeconds

    }

    elseif ($Duration.TotalMinutes -lt 60) {

        return "{0:N2} min" -f `
            $Duration.TotalMinutes

    }

    else {

        return "{0:N2} hr" -f `
            $Duration.TotalHours

    }

}

#endregion

Export-ModuleMember `
    -Function `
        Convert-BytesToMB,
        Format-FileName,
        Resolve-EnvironmentPath,
        Initialize-Directory,
        New-UniqueFilePath,
        Get-FileSHA256,
        Format-Duration