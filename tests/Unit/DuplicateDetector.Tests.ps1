BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1"
Import-Module "$ProjectRoot\modules\Utils.psm1"
Import-Module "$ProjectRoot\modules\DuplicateDetector.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "DuplicateDetector Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ($TestDrive) ("DupTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            $resolved = [IO.Path]::GetFullPath($tempDir)
            if (-not $resolved.StartsWith([IO.Path]::GetFullPath($TestDrive).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped TestDrive.' }
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }

    It "Should calculate SHA256 hash match via Test-FileDuplicate" {
        $f1 = Join-Path $tempDir "file1.txt"
        $f2 = Join-Path $tempDir "file2.txt"
        "identical content" | Set-Content -Path $f1
        "identical content" | Set-Content -Path $f2

        $isDup = Test-FileDuplicate -Path1 $f1 -Path2 $f2
        $isDup | Should -Be $true
    }

    It "Should identify duplicate files and set IsDuplicate flag" {
        $f1 = Join-Path $tempDir "file1.txt"
        $f2 = Join-Path $tempDir "file2.txt"
        $f3 = Join-Path $tempDir "unique.txt"

        "same data" | Set-Content -Path $f1
        "same data" | Set-Content -Path $f2
        "different data" | Set-Content -Path $f3

        $org1 = New-OrganizerFile -File (Get-Item $f1)
        $org2 = New-OrganizerFile -File (Get-Item $f2)
        $org3 = New-OrganizerFile -File (Get-Item $f3)

        $dups = Get-DuplicateFiles -Files @($org1, $org2, $org3)
        @($dups).Count | Should -Be 1
        $dups[0].Name | Should -Be "file2.txt"
        $dups[0].IsDuplicate | Should -Be $true
    }
}
