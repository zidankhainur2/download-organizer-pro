BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1"
Import-Module "$ProjectRoot\modules\Utils.psm1"
Import-Module "$ProjectRoot\modules\Mover.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "Mover Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ($TestDrive) ("MoverTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            $resolved = [IO.Path]::GetFullPath($tempDir)
            if (-not $resolved.StartsWith([IO.Path]::GetFullPath($TestDrive).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped TestDrive.' }
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }

    It "Should move file into category destination folder" {
        $filePath = Join-Path $tempDir "document.pdf"
        "test content" | Set-Content -Path $filePath
        $fileInfo = Get-Item $filePath
        $orgFile = New-OrganizerFile -File $fileInfo
        $orgFile.SetCategory("Documents")

        $results = Move-OrganizerFiles -Files @($orgFile) -BasePath $tempDir
        @($results).Count | Should -Be 1
        $results[0].Status | Should -Be "Moved"

        $expectedDest = Join-Path $tempDir "Documents\document.pdf"
        Test-Path $expectedDest | Should -Be $true
        $orgFile.Status.ToString() | Should -Be "Moved"
    }

    It "Should move file into subcategory subfolder hierarchy" {
        $filePath = Join-Path $tempDir "Resume.pdf"
        "test content" | Set-Content -Path $filePath
        $fileInfo = Get-Item $filePath
        $orgFile = New-OrganizerFile -File $fileInfo
        $orgFile.SetCategory("Documents")
        $orgFile.SetSubCategory("CV", 100)

        $results = Move-OrganizerFiles -Files @($orgFile) -BasePath $tempDir
        $expectedDest = Join-Path $tempDir "Documents\CV\Resume.pdf"
        Test-Path $expectedDest | Should -Be $true
    }

    It "Should rename duplicate destination files automatically" {
        # Create pre-existing file at target destination
        $targetDir = Join-Path $tempDir "Documents"
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        $existingTarget = Join-Path $targetDir "invoice.pdf"
        "existing" | Set-Content -Path $existingTarget

        # Source file to move
        $sourcePath = Join-Path $tempDir "invoice.pdf"
        "new content" | Set-Content -Path $sourcePath
        $fileInfo = Get-Item $sourcePath
        $orgFile = New-OrganizerFile -File $fileInfo
        $orgFile.SetCategory("Documents")

        $results = Move-OrganizerFiles -Files @($orgFile) -BasePath $tempDir
        $results[0].Status | Should -Be "Moved"
        ($results[0].Destination -like "*invoice (1).pdf*") | Should -Be $true
        Test-Path $results[0].Destination | Should -Be $true
    }

    It "Should handle move failure gracefully and mark status as Failed" {
        $filePath = Join-Path $tempDir "locked.pdf"
        "test" | Set-Content -Path $filePath
        $fileInfo = Get-Item $filePath
        $orgFile = New-OrganizerFile -File $fileInfo
        $orgFile.SetCategory("Documents")

        $handle = [IO.File]::Open($filePath, 'Open', 'Read', 'None')
        try { $results = Move-OrganizerFiles -Files @($orgFile) -BasePath $tempDir }
        finally { $handle.Dispose() }
        $results[0].Status | Should -Be "Failed"
        $orgFile.Status.ToString() | Should -Be "Failed"
    }
}
