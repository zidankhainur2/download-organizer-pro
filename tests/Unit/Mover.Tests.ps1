$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1" -Force
Import-Module "$ProjectRoot\modules\Utils.psm1" -Force
Import-Module "$ProjectRoot\modules\Mover.psm1" -Force

Describe "Mover Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("MoverTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }

    It "Should move file into category destination folder" {
        $filePath = Join-Path $tempDir "document.pdf"
        "test content" | Set-Content -Path $filePath
        $fileInfo = Get-Item $filePath
        $orgFile = New-OrganizerFile -File $fileInfo
        $orgFile.SetCategory("Documents")

        $results = Move-OrganizerFiles -Files @($orgFile) -BasePath $tempDir
        @($results).Count | Should Be 1
        $results[0].Status | Should Be "Moved"

        $expectedDest = Join-Path $tempDir "Documents\document.pdf"
        Test-Path $expectedDest | Should Be $true
        $orgFile.Status.ToString() | Should Be "Moved"
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
        Test-Path $expectedDest | Should Be $true
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
        $results[0].Status | Should Be "Moved"
        ($results[0].Destination -like "*invoice (1).pdf*") | Should Be $true
        Test-Path $results[0].Destination | Should Be $true
    }

    It "Should handle move failure gracefully and mark status as Failed" {
        $filePath = Join-Path $tempDir "locked.pdf"
        "test" | Set-Content -Path $filePath
        $fileInfo = Get-Item $filePath
        $orgFile = New-OrganizerFile -File $fileInfo
        $orgFile.SetCategory("Documents")

        # Mock Move-Item to throw exception
        Mock Move-Item { throw "Access Denied" } -ModuleName Mover

        $results = Move-OrganizerFiles -Files @($orgFile) -BasePath $tempDir
        $results[0].Status | Should Be "Failed"
        $orgFile.Status.ToString() | Should Be "Failed"
    }
}
