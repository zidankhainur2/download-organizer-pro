BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1"
Import-Module "$ProjectRoot\modules\Utils.psm1"
Import-Module "$ProjectRoot\modules\Config.psm1"
Import-Module "$ProjectRoot\modules\Classifier.psm1"
Import-Module "$ProjectRoot\modules\SmartClassifier.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "SmartClassifier Module Unit Tests" {
    BeforeAll {
        $config = Get-OrganizerConfig -Path $testConfigPath
    }

    BeforeEach {
        $tempDir = Join-Path ($TestDrive) ("SmartClassifierTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            $resolved = [IO.Path]::GetFullPath($tempDir)
            if (-not $resolved.StartsWith([IO.Path]::GetFullPath($TestDrive).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped TestDrive.' }
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }

    It "Should assign CV subcategory to resume file" {
        $resumePath = Join-Path $tempDir "Resume_John_Doe.pdf"
        "dummy" | Set-Content -Path $resumePath

        $fileInfo = Get-Item $resumePath
        $orgFile = New-OrganizerFile -File $fileInfo
        $orgFile.SetCategory("Documents")

        $classified = Invoke-SmartClassification -Files @($orgFile) -SmartRules $config.SmartRules
        $classified[0].SubCategory | Should -Be "CV"
        $classified[0].SmartScore | Should -BeGreaterThan 0
        $classified[0].DestinationPath | Should -Be "Documents\CV"
    }

    It "Should evaluate rule priority when multiple keyword rules match" {
        $financePath = Join-Path $tempDir "Invoice_Billing_Receipt.pdf"
        "dummy" | Set-Content -Path $financePath

        $fileInfo = Get-Item $financePath
        $orgFile = New-OrganizerFile -File $fileInfo
        $orgFile.SetCategory("Documents")

        $classified = Invoke-SmartClassification -Files @($orgFile) -SmartRules $config.SmartRules
        $classified[0].SubCategory | Should -Be "Finance"
    }

    It "Should reset unmatched files to empty subcategory and 0 score" {
        $normalPath = Join-Path $tempDir "random_notes.txt"
        "dummy" | Set-Content -Path $normalPath

        $fileInfo = Get-Item $normalPath
        $orgFile = New-OrganizerFile -File $fileInfo
        $orgFile.SetCategory("Documents")

        $classified = Invoke-SmartClassification -Files @($orgFile) -SmartRules $config.SmartRules
        $classified[0].SubCategory | Should -Be ""
        $classified[0].SmartScore | Should -Be 0
        $classified[0].DestinationPath | Should -Be "Documents"
    }

    It "Should return null for Get-SmartCategory when no keywords match" {
        $match = Get-SmartCategory -FileName "no_match.pdf" -SmartRules $config.SmartRules
        $match | Should -Be $null
    }
}
