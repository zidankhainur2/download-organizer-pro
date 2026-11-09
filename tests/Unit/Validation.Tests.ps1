BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1"
Import-Module "$ProjectRoot\modules\Utils.psm1"
Import-Module "$ProjectRoot\modules\Validation.psm1"
Import-Module "$ProjectRoot\modules\Config.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "Validation Module Unit Tests" {
    BeforeAll {
        $validConfig = Get-OrganizerConfig -Path $testConfigPath
    }

    It "Should return true for valid configuration" {
        $result = Test-OrganizerConfiguration -Config $validConfig
        $result | Should -Be $true
    }

    It "Should throw exception when Settings section is missing" {
        $invalid = [PSCustomObject]@{
            Categories = $validConfig.Categories
            SmartRules = $validConfig.SmartRules
        }
        { Test-OrganizerConfiguration -Config $invalid } | Should -Throw
    }

    It "Should throw exception when Categories section is missing" {
        $invalid = [PSCustomObject]@{
            Settings = $validConfig.Settings
            SmartRules = $validConfig.SmartRules
        }
        { Test-OrganizerConfiguration -Config $invalid } | Should -Throw
    }

    It "Should throw exception when SmartRules section is missing" {
        $invalid = [PSCustomObject]@{
            Settings = $validConfig.Settings
            Categories = $validConfig.Categories
        }
        { Test-OrganizerConfiguration -Config $invalid } | Should -Throw
    }

    It "Should throw exception when DownloadsPath setting is missing" {
        $invalidSettings = [PSCustomObject]@{
            EnableSmartRules = $true
            Overwrite = $false
        }
        $invalid = [PSCustomObject]@{
            Settings = $invalidSettings
            Categories = $validConfig.Categories
            SmartRules = $validConfig.SmartRules
        }
        { Test-OrganizerConfiguration -Config $invalid } | Should -Throw
    }

    It "Should throw exception when DownloadsPath directory does not exist" {
        $invalidSettings = [PSCustomObject]@{
            DownloadsPath = "C:\NonExistentDirectory_12345"
            EnableSmartRules = $true
            Overwrite = $false
        }
        $invalid = [PSCustomObject]@{
            Settings = $invalidSettings
            Categories = $validConfig.Categories
            SmartRules = $validConfig.SmartRules
        }
        { Test-OrganizerConfiguration -Config $invalid } | Should -Throw
    }

    It "Should throw exception when Category value is null or non-array" {
        $invalidCategories = [PSCustomObject]@{
            Documents = "not-an-array"
        }
        $invalid = [PSCustomObject]@{
            Settings = $validConfig.Settings
            Categories = $invalidCategories
            SmartRules = $validConfig.SmartRules
        }
        { Test-OrganizerConfiguration -Config $invalid } | Should -Throw
    }

    It "Should throw exception when SmartRule priority is negative" {
        $invalidSmartRules = [PSCustomObject]@{
            Documents = [PSCustomObject]@{
                BadRule = [PSCustomObject]@{
                    Priority = -10
                    Keywords = @("bad")
                }
            }
        }
        $invalid = [PSCustomObject]@{
            Settings = $validConfig.Settings
            Categories = $validConfig.Categories
            SmartRules = $invalidSmartRules
        }
        { Test-OrganizerConfiguration -Config $invalid } | Should -Throw
    }
}
