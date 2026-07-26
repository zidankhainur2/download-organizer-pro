Set-StrictMode -Version Latest

#region Private Functions

function Assert-Setting {

    param(

        [Parameter(Mandatory)]
        [hashtable]$Settings,

        [Parameter(Mandatory)]
        [string]$Name

    )

    if (-not $Settings.ContainsKey($Name)) {

        throw "Missing setting '$Name'."

    }

}

function Assert-DirectoryExists {

    param(

        [Parameter(Mandatory)]
        [string]$Path

    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {

        throw "Directory does not exist: $Path"

    }

}

function Assert-CategoryCollection {

    param(

        [Parameter(Mandatory)]
        [psobject]$Categories

    )

    foreach ($category in $Categories.PSObject.Properties) {

        if ($null -eq $category.Value) {

            throw "Category '$($category.Name)' is null."

        }

        if ($category.Value -isnot [System.Array]) {

            throw "Category '$($category.Name)' must be an array."

        }

    }

}

function Assert-SmartRules {

    param(

        [Parameter(Mandatory)]
        [psobject]$Rules

    )

    foreach ($category in $Rules.PSObject.Properties) {

        foreach ($sub in $category.Value.PSObject.Properties) {

            $rule = $sub.Value

            if (-not $rule.PSObject.Properties.Match("Keywords")) {

                throw "Missing Keywords in SmartRule '$($sub.Name)'."

            }

            if (-not $rule.PSObject.Properties.Match("Priority")) {

                throw "Missing Priority in SmartRule '$($sub.Name)'."

            }

            if ($rule.Priority -lt 0) {

                throw "Priority cannot be negative."

            }

        }

    }

}

#endregion

#region Public Functions

<#
.SYNOPSIS
Validates the entire organizer configuration object.

.DESCRIPTION
Verifies required sections (Settings, Categories, SmartRules), confirms DownloadsPath exists, checks category structures, and validates SmartRule definitions.

.PARAMETER Config
Configuration object to validate.

.OUTPUTS
[bool] True if configuration is valid; throws exception on validation failure.

.EXAMPLE
Test-OrganizerConfiguration -Config $config
#>
function Test-OrganizerConfiguration {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [psobject]$Config

    )

    Write-Verbose "Validating configuration..."

    if ($null -eq $Config.Settings) {

        throw "Settings section not found."

    }

    if ($null -eq $Config.Categories) {

        throw "Categories section not found."

    }

    if ($null -eq $Config.SmartRules) {

        throw "SmartRules section not found."

    }

    $settings = @{}

    foreach ($property in $Config.Settings.PSObject.Properties) {

        $settings[$property.Name] = $property.Value

    }

    Assert-Setting `
        -Settings $settings `
        -Name "DownloadsPath"

    Assert-Setting `
        -Settings $settings `
        -Name "EnableSmartRules"

    Assert-Setting `
        -Settings $settings `
        -Name "Overwrite"

    $downloadPath =
        [Environment]::ExpandEnvironmentVariables(
            $Config.Settings.DownloadsPath
        )

    Assert-DirectoryExists `
        -Path $downloadPath

    Assert-CategoryCollection `
        -Categories $Config.Categories

    Assert-SmartRules `
        -Rules $Config.SmartRules

    return $true

}

#endregion

Export-ModuleMember `
    -Function Test-OrganizerConfiguration