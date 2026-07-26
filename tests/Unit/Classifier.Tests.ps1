$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1" -Force
Import-Module "$ProjectRoot\modules\Utils.psm1" -Force
Import-Module "$ProjectRoot\modules\Validation.psm1" -Force
Import-Module "$ProjectRoot\modules\Config.psm1" -Force
Import-Module "$ProjectRoot\modules\Classifier.psm1" -Force

Describe "Classifier Module Unit Tests" {
    BeforeAll {
        $config = Get-OrganizerConfig -Path "$ProjectRoot\config.json"
    }

    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ClassifierTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }

    It "Should categorize .pdf file as Documents" {
        $pdfPath = Join-Path $tempDir "document.pdf"
        "test" | Set-Content -Path $pdfPath
        $fileInfo = Get-Item $pdfPath
        $orgFile = New-OrganizerFile -File $fileInfo

        $classified = Set-FileCategory -Files @($orgFile) -Categories $config.Categories
        $classified[0].Category | Should Be "Documents"
    }

    It "Should handle case-insensitive extension matching (.PDF, .Jpg)" {
        $upperPath = Join-Path $tempDir "image.JPG"
        "test" | Set-Content -Path $upperPath
        $fileInfo = Get-Item $upperPath
        $orgFile = New-OrganizerFile -File $fileInfo

        $classified = Set-FileCategory -Files @($orgFile) -Categories $config.Categories
        $classified[0].Category | Should Be "Images"
    }

    It "Should assign unknown extensions to Others" {
        $unknownPath = Join-Path $tempDir "file.unknownext"
        "test" | Set-Content -Path $unknownPath
        $fileInfo = Get-Item $unknownPath
        $orgFile = New-OrganizerFile -File $fileInfo

        $classified = Set-FileCategory -Files @($orgFile) -Categories $config.Categories
        $classified[0].Category | Should Be "Others"
    }

    It "Should support pipeline input for Set-FileCategory" {
        $pdfPath = Join-Path $tempDir "report.pdf"
        "test" | Set-Content -Path $pdfPath
        $fileInfo = Get-Item $pdfPath
        $orgFile = New-OrganizerFile -File $fileInfo

        $result = $orgFile | Set-FileCategory -Categories $config.Categories
        $result.Category | Should Be "Documents"
    }

    It "Should support Invoke-FileClassification wrapper" {
        $zipPath = Join-Path $tempDir "archive.zip"
        "test" | Set-Content -Path $zipPath
        $fileInfo = Get-Item $zipPath
        $orgFile = New-OrganizerFile -File $fileInfo

        $result = Invoke-FileClassification -Files @($orgFile) -Categories $config.Categories
        $result[0].Category | Should Be "Archives"
    }
}
