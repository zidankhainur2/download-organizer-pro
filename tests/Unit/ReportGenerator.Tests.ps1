$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1" -Force
Import-Module "$ProjectRoot\modules\Utils.psm1" -Force
Import-Module "$ProjectRoot\modules\Summary.psm1" -Force
Import-Module "$ProjectRoot\modules\ReportGenerator.psm1" -Force

Describe "ReportGenerator Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ReportTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }

    It "Should export move results to CSV report file" {
        $results = @(
            [PSCustomObject]@{ File = "test1.pdf"; Category = "Documents"; SubCategory = "CV"; Status = "Moved"; Destination = "Documents\CV\test1.pdf" }
        )
        $csvPath = Join-Path $tempDir "reports\report.csv"
        $exported = Export-OrganizerCSV -Results $results -OutputPath $csvPath

        Test-Path $exported | Should Be $true
        $content = Get-Content $exported -Raw
        ($content -match "test1\.pdf") | Should Be $true
    }

    It "Should export summary metrics to JSON report file" {
        $summary = New-OrganizerSummary
        $summary.TotalFiles = 1
        $summary.Moved = 1

        $results = @(
            [PSCustomObject]@{ File = "test1.pdf"; Category = "Documents"; Status = "Moved" }
        )
        $jsonPath = Join-Path $tempDir "reports\report.json"
        $exported = Export-OrganizerJSON -Summary $summary -Results $results -OutputPath $jsonPath

        Test-Path $exported | Should Be $true
        $content = Get-Content $exported -Raw
        ($content -match "GeneratedAt") | Should Be $true
    }

    It "Should generate standalone HTML dashboard report file" {
        $summary = New-OrganizerSummary
        $summary.TotalFiles = 2
        $summary.Moved = 2
        $summary.TotalSizeMB = 0.5
        $summary.Duration = [TimeSpan]::FromSeconds(1)
        $summary.Categories["Documents"] = 2

        $results = @(
            [PSCustomObject]@{ File = "doc1.pdf"; Category = "Documents"; SubCategory = "CV"; Status = "Moved"; Destination = "Documents\CV\doc1.pdf" }
        )
        $htmlPath = Join-Path $tempDir "reports\report.html"
        $exported = Export-OrganizerHTMLReport -Summary $summary -Results $results -OutputPath $htmlPath

        Test-Path $exported | Should Be $true
        $content = Get-Content $exported -Raw
        ($content -match "Download Organizer Pro") | Should Be $true
    }

    It "Should aggregate historical statistics across log files" {
        $logsDir = Join-Path $tempDir "logs"
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
        $logFile = Join-Path $logsDir "organizer-2026-07-26.log"
        "[2026-07-26 12:00:00] [SUCCESS] Moved: f1.pdf -> Documents\f1.pdf`n[2026-07-26 12:00:01] [ERROR] Failed: f2.pdf | Access Denied" | Set-Content -Path $logFile

        $stats = Get-OrganizerStatistics -LogPath $logsDir
        $stats.TotalExecutions | Should Be 1
        $stats.TotalMoved | Should Be 1
        $stats.TotalFailed | Should Be 1
    }
}
