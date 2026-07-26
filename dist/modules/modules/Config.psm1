Set-StrictMode -Version Latest

#region Public Functions

<#
.SYNOPSIS
Loads and validates organizer configuration.

.DESCRIPTION
Reads config.json from disk, expands environment variables in paths, and validates the configuration structure.

.PARAMETER Path
Path to the configuration JSON file.

.OUTPUTS
[PSCustomObject] Loaded and validated configuration object.

.EXAMPLE
Get-OrganizerConfig -Path ".\config.json"
#>
function Get-OrganizerConfig {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path

    )

    if (-not (Test-Path -LiteralPath $Path)) {

        throw "Configuration file not found: $Path"

    }

    try {

        $config =
            Get-Content `
                -LiteralPath $Path `
                -Raw |
            ConvertFrom-Json

    }
    catch {

        throw "Invalid JSON configuration file."

    }

    # Resolve DownloadsPath

    $config.Settings.DownloadsPath =
        Resolve-EnvironmentPath `
            -Path $config.Settings.DownloadsPath

    # Validate configuration

    Test-OrganizerConfiguration `
        -Config $config | Out-Null

    return $config

}

<#
.SYNOPSIS
Returns a list of configured categories.

.PARAMETER Config
Configuration object loaded by Get-OrganizerConfig.
#>
function Get-OrganizerCategories {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        $Config

    )

    return @(
        $Config.Categories.PSObject.Properties.Name
    )

}

<#
.SYNOPSIS
Returns all configured extensions across all categories.

.PARAMETER Config
Configuration object loaded by Get-OrganizerConfig.
#>
function Get-ConfiguredExtensions {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        $Config

    )

    $extensions = New-Object System.Collections.Generic.List[string]

    foreach ($category in $Config.Categories.PSObject.Properties) {

        foreach ($extension in $category.Value) {

            $extensions.Add($extension.ToLower())

        }

    }

    return $extensions |
        Sort-Object -Unique

}

<#
.SYNOPSIS
Returns Smart Rules for a category.

.PARAMETER Config
Configuration object loaded by Get-OrganizerConfig.

.PARAMETER Category
Category name to look up rules for.
#>
function Get-SmartRules {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        $Config,

        [Parameter(Mandatory)]
        [string]$Category

    )

    if ($Config.SmartRules.PSObject.Properties.Name -contains $Category) {

        return $Config.SmartRules.$Category

    }

    return $null

}

#endregion

Export-ModuleMember `
    -Function `
        Get-OrganizerConfig,
        Get-OrganizerCategories,
        Get-ConfiguredExtensions,
        Get-SmartRules