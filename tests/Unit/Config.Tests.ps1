$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1" -Force
Import-Module "$ProjectRoot\modules\Utils.psm1" -Force
Import-Module "$ProjectRoot\modules\Validation.psm1" -Force
Import-Module "$ProjectRoot\modules\Config.psm1" -Force

Describe "Config Module Unit Tests" {
    Context "Get-OrganizerConfig" {
        It "Should load valid config.json successfully" {
            $configPath = "$ProjectRoot\config.json"
            $config = Get-OrganizerConfig -Path $configPath
            $config | Should Not Be $null
            $config.Settings | Should Not Be $null
            $config.Categories | Should Not Be $null
            $config.SmartRules | Should Not Be $null
        }

        It "Should throw exception when config path does not exist" {
            { Get-OrganizerConfig -Path ".\nonexistent_path_config.json" } | Should Throw
        }

        It "Should throw exception when file contains invalid JSON" {
            $tempFile = [System.IO.Path]::GetTempFileName()
            try {
                "{ invalid json syntax ... " | Set-Content -Path $tempFile
                { Get-OrganizerConfig -Path $tempFile } | Should Throw
            }
            finally {
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }
    }

    Context "Get-OrganizerCategories" {
        It "Should return array of category names" {
            $config = Get-OrganizerConfig -Path "$ProjectRoot\config.json"
            $categories = Get-OrganizerCategories -Config $config
            $categories.Length | Should BeGreaterThan 0
            ($categories -contains "Documents") | Should Be $true
            ($categories -contains "Images") | Should Be $true
            ($categories -contains "Archives") | Should Be $true
        }
    }

    Context "Get-ConfiguredExtensions" {
        It "Should return sorted unique list of configured extensions" {
            $config = Get-OrganizerConfig -Path "$ProjectRoot\config.json"
            $extensions = Get-ConfiguredExtensions -Config $config
            $extensions.Count | Should BeGreaterThan 0
            ($extensions -contains "pdf") | Should Be $true
            ($extensions -contains "zip") | Should Be $true
            ($extensions -contains "exe") | Should Be $true
        }
    }

    Context "Get-SmartRules" {
        It "Should return smart rules for configured category" {
            $config = Get-OrganizerConfig -Path "$ProjectRoot\config.json"
            $rules = Get-SmartRules -Config $config -Category "Documents"
            $rules | Should Not Be $null
            $rules.CV | Should Not Be $null
        }

        It "Should return null for non-existent category" {
            $config = Get-OrganizerConfig -Path "$ProjectRoot\config.json"
            $rules = Get-SmartRules -Config $config -Category "NonExistentCategory"
            $rules | Should Be $null
        }
    }
}
