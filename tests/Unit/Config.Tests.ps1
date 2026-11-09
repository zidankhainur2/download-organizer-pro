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

Describe "Config Module Unit Tests" {
    It 'resolves relative paths against the PowerShell location' {
        Push-Location $TestDrive
        try { Resolve-EnvironmentPath '.\literal [1]' | Should -Be (Join-Path $TestDrive 'literal [1]') }
        finally { Pop-Location }
    }
    It 'parses and validates every complete JSON example in the configuration guide' {
        $guide = Get-Content -LiteralPath "$ProjectRoot/docs/CONFIGURATION.md" -Raw
        $examples = [regex]::Matches($guide, '(?s)```json\s*(.*?)```')
        $examples.Count | Should -BeGreaterThan 0
        foreach ($example in $examples) {
            $config = $example.Groups[1].Value | ConvertFrom-Json
            $config.Settings.DownloadsPath = $TestDrive
            Test-OrganizerConfiguration $config | Should -BeTrue
        }
    }
    It 'expands an override before checking a nonexistent default folder' {
        $original = New-TestConfig 'C:\missing-organizer-test-folder'
        $path = Join-Path $TestDrive 'override.json'
        $original.Settings.PSObject.Properties.Remove('EnableDuplicateDetection')
        $original | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $path
        $config = Get-OrganizerConfig -Path $path -DownloadsPath $TestDrive
        $config.Settings.DownloadsPath | Should -Be $TestDrive
        $config.Settings.EnableDuplicateDetection | Should -BeTrue
    }
    Context "Get-OrganizerConfig" {
        It "Should load valid config.json successfully" {
            $configPath = $testConfigPath
            $config = Get-OrganizerConfig -Path $configPath
            $config | Should -Not -Be $null
            $config.Settings | Should -Not -Be $null
            $config.Categories | Should -Not -Be $null
            $config.SmartRules | Should -Not -Be $null
        }

        It "Should throw exception when config path does not exist" {
            { Get-OrganizerConfig -Path ".\nonexistent_path_config.json" } | Should -Throw
        }

        It "Should throw exception when file contains invalid JSON" {
            $tempFile = [System.IO.Path]::GetTempFileName()
            try {
                "{ invalid json syntax ... " | Set-Content -Path $tempFile
                { Get-OrganizerConfig -Path $tempFile } | Should -Throw
            }
            finally {
                if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
            }
        }
    }

    Context "Get-OrganizerCategories" {
        It "Should return array of category names" {
            $config = Get-OrganizerConfig -Path $testConfigPath
            $categories = Get-OrganizerCategories -Config $config
            $categories.Length | Should -BeGreaterThan 0
            ($categories -contains "Documents") | Should -Be $true
            ($categories -contains "Images") | Should -Be $true
            ($categories -contains "Archives") | Should -Be $true
        }
    }

    Context "Get-ConfiguredExtensions" {
        It "Should return sorted unique list of configured extensions" {
            $config = Get-OrganizerConfig -Path $testConfigPath
            $extensions = Get-ConfiguredExtensions -Config $config
            $extensions.Count | Should -BeGreaterThan 0
            ($extensions -contains "pdf") | Should -Be $true
            ($extensions -contains "zip") | Should -Be $true
            ($extensions -contains "exe") | Should -Be $true
        }
    }

    Context "Get-SmartRules" {
        It "Should return smart rules for configured category" {
            $config = Get-OrganizerConfig -Path $testConfigPath
            $rules = Get-SmartRules -Config $config -Category "Documents"
            $rules | Should -Not -Be $null
            $rules.CV | Should -Not -Be $null
        }

        It "Should return null for non-existent category" {
            $config = Get-OrganizerConfig -Path $testConfigPath
            $rules = Get-SmartRules -Config $config -Category "NonExistentCategory"
            $rules | Should -Be $null
        }
    }
}
