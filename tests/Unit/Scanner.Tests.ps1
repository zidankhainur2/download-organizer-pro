BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1"
Import-Module "$ProjectRoot\modules\Utils.psm1"
Import-Module "$ProjectRoot\modules\Scanner.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "Scanner Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ($TestDrive) ("ScannerTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            $resolved = [IO.Path]::GetFullPath($tempDir)
            if (-not $resolved.StartsWith([IO.Path]::GetFullPath($TestDrive).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped TestDrive.' }
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }

    It "Should return OrganizerFile objects for files in directory" {
        New-Item -ItemType File -Path (Join-Path $tempDir "file1.pdf") -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $tempDir "file2.jpg") -Force | Out-Null

        $files = @(Get-DownloadFiles -Path $tempDir)
        $files.Count | Should -Be 2
        $files[0].Name | Should -Be "file1.pdf"
        $files[0].Extension | Should -Be "pdf"
        $files[1].Name | Should -Be "file2.jpg"
        $files[1].Extension | Should -Be "jpg"
    }

    It "Should return empty list for empty directory" {
        $files = @(Get-DownloadFiles -Path $tempDir)
        $files.Count | Should -Be 0
    }

    It "Should ignore subdirectories and only return files" {
        New-Item -ItemType File -Path (Join-Path $tempDir "file1.txt") -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $tempDir "SubFolder") -Force | Out-Null

        $files = @(Get-DownloadFiles -Path $tempDir)
        $files.Count | Should -Be 1
        $files[0].Name | Should -Be "file1.txt"
    }

    It "Should throw exception when target directory path does not exist" {
        { Get-DownloadFiles -Path "C:\NonExistentPath_99999" } | Should -Throw
    }
}
