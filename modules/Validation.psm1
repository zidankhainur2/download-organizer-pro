Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/Utils.psm1"

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
        Assert-DirectoryComponent $category.Name

        if ($null -eq $category.Value) {

            throw "Category '$($category.Name)' is null."

        }

        if ($category.Value -isnot [System.Array]) {

            throw "Category '$($category.Name)' must be an array."

        }
        foreach ($extension in $category.Value) {
            if ($extension -isnot [string] -or $extension -notmatch '^\.?[\p{L}\p{N}]+$') { throw 'Extensions must be simple extension strings.' }
        }

    }

}

function Assert-SmartRules {

    param(

        [Parameter(Mandatory)]
        [psobject]$Rules

    )

    foreach ($category in $Rules.PSObject.Properties) {
        Assert-DirectoryComponent $category.Name

        foreach ($sub in $category.Value.PSObject.Properties) {
            Assert-DirectoryComponent $sub.Name

            $rule = $sub.Value

            if (-not $rule.PSObject.Properties.Match("Keywords")) {

                throw "Missing Keywords in SmartRule '$($sub.Name)'."

            }

            if (-not $rule.PSObject.Properties.Match("Priority")) {

                throw "Missing Priority in SmartRule '$($sub.Name)'."

            }

            if ($rule.Keywords -isnot [array] -or @($rule.Keywords | Where-Object { $_ -isnot [string] -or [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
                throw 'Keywords must be an array of nonempty strings.'
            }
            if (($rule.Priority -isnot [int] -and $rule.Priority -isnot [long]) -or $rule.Priority -lt 0 -or $rule.Priority -gt [int]::MaxValue) {

                throw 'Priority must be a nonnegative 32-bit integer.'

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

    if ($settings.ContainsKey('ConflictAction') -and $settings.ConflictAction -notin @('Rename', 'Skip', 'Overwrite')) {
        throw 'ConflictAction must be Rename, Skip, or Overwrite.'
    }
    foreach ($name in @('CreateLogs', 'MoveUnknownFiles', 'Overwrite', 'EnableSmartRules', 'CreateCategoryFolders', 'Verbose', 'DryRun', 'Recursive', 'EnableDuplicateDetection', 'ExportCSV', 'ExportJSON', 'ExportHTML')) {
        if ($settings.ContainsKey($name) -and $settings[$name] -isnot [bool]) { throw "$name must be a boolean." }
    }
    foreach ($name in @('MinAgeDays', 'MaxAgeDays', 'MinSizeBytes', 'MaxSizeBytes', 'WatcherDebounceSeconds', 'ScheduleIntervalMinutes')) {
        if ($settings.ContainsKey($name) -and (($settings[$name] -isnot [int] -and $settings[$name] -isnot [long]) -or $settings[$name] -lt 0)) { throw "$name must be a nonnegative integer." }
    }
    if ($settings.ContainsKey('ScheduleIntervalMinutes') -and $settings.ScheduleIntervalMinutes -lt 1) { throw 'Schedule interval must be at least one minute.' }
    if ($settings.ContainsKey('WatcherDebounceSeconds') -and $settings.WatcherDebounceSeconds -lt 1) { throw 'Watcher debounce must be at least one second.' }
    if ($settings.ContainsKey('IgnorePatterns') -and ($settings.IgnorePatterns -isnot [array] -or @($settings.IgnorePatterns | Where-Object { $_ -isnot [string] -or [string]::IsNullOrWhiteSpace($_) }).Count -gt 0)) { throw 'IgnorePatterns must be an array of nonempty strings.' }

    Assert-CategoryCollection `
        -Categories $Config.Categories

    Assert-SmartRules `
        -Rules $Config.SmartRules

    return $true

}

#endregion

Export-ModuleMember `
    -Function Test-OrganizerConfiguration
