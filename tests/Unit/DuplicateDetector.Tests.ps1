$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1" -Force
Import-Module "$ProjectRoot\modules\Utils.psm1" -Force
Import-Module "$ProjectRoot\modules\DuplicateDetector.psm1" -Force

Describe "DuplicateDetector Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("DupTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }

    It "Should calculate SHA256 hash match via Test-FileDuplicate" {
        $f1 = Join-Path $tempDir "file1.txt"
        $f2 = Join-Path $tempDir "file2.txt"
        "identical content" | Set-Content -Path $f1
        "identical content" | Set-Content -Path $f2

        $isDup = Test-FileDuplicate -Path1 $f1 -Path2 $f2
        $isDup | Should Be $true
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
        @($dups).Count | Should Be 1
        $dups[0].Name | Should Be "file2.txt"
        $dups[0].IsDuplicate | Should Be $true
    }
}
