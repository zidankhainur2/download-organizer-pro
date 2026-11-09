Set-StrictMode -Version Latest

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

    $normalized = ($Name.ToLowerInvariant() -replace '[_\-.]+', ' ' -replace '\s+', ' ').Trim()

    return $normalized

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

    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($expanded)

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

    if (-not (Test-Path -LiteralPath $Path)) {

        [IO.Directory]::CreateDirectory($Path) | Out-Null

    }

    return $Path

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

    if (-not (Test-Path -LiteralPath $Destination)) {

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
    until (-not (Test-Path -LiteralPath $candidate))

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
            -LiteralPath $Path -ErrorAction Stop
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

function Assert-DirectoryComponent {
    param([AllowEmptyString()][string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name -in @('.', '..') -or
        $Name -match '[<>:"/\\|?*\x00-\x1f]' -or $Name -match '[. ]$' -or
        $Name -match '^(?i:CON|PRN|AUX|NUL|CONIN\$|CONOUT\$|COM[1-9\u00b9\u00b2\u00b3]|LPT[1-9\u00b9\u00b2\u00b3])(?:\.|$)') {
        throw "Invalid directory component: '$Name'."
    }
}

function Assert-ContainedPath {
    param([string]$Path, [string]$BasePath)
    $root = [IO.Path]::GetFullPath($BasePath).TrimEnd('\', '/')
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside target directory: $Path"
    }
    $current = $full
    while ($current) {
        try { $attributes = [IO.File]::GetAttributes($current) }
        catch [IO.FileNotFoundException] { $attributes = 0 }
        catch [IO.DirectoryNotFoundException] { $attributes = 0 }
        if ($attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point is not allowed: $current" }
        $current = [IO.Path]::GetDirectoryName($current)
    }
    return $full
}

function Enter-OrganizerLock {
    param([string]$Path)
    $normalized = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/').ToUpperInvariant()
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $key = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalized))).Replace('-', '') }
    finally { $sha.Dispose() }
    $mutex = [Threading.Mutex]::new($false, "Local\DownloadOrganizerPro_$key")
    try {
        try { $acquired = $mutex.WaitOne(0) }
        catch [Threading.AbandonedMutexException] { $acquired = $true }
        if (-not $acquired) { throw "Another organizer operation is active for: $Path" }
        return $mutex
    }
    catch { $mutex.Dispose(); throw }
}

function ConvertTo-WindowsArgument {
    param([AllowEmptyString()][string]$Value)
    '"' + ([regex]::Replace([regex]::Replace($Value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1')) + '"'
}

Export-ModuleMember `
    -Function `
        Convert-BytesToMB,
        Format-FileName,
        Resolve-EnvironmentPath,
        Initialize-Directory,
        New-UniqueFilePath,
        Get-FileSHA256,
        Format-Duration, Assert-DirectoryComponent, Assert-ContainedPath, Enter-OrganizerLock, ConvertTo-WindowsArgument
