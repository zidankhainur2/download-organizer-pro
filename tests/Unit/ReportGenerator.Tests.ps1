BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1"
Import-Module "$ProjectRoot\modules\Utils.psm1"
Import-Module "$ProjectRoot\modules\Summary.psm1"
Import-Module "$ProjectRoot\modules\ReportGenerator.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "ReportGenerator Module Unit Tests" {
    It 'encodes every dynamic summary metric in HTML' {
        $summary = [pscustomobject]@{
            TotalFiles = '<script>'; Moved = '<script>'; Failed = '<script>'; Skipped = '<script>'
            Planned = '<script>'; Duplicates = '<script>'; TotalSizeMB = '<script>'
            Duration = [timespan]::Zero; Categories = @{ '<script>' = '<script>' }
        }
        $path = Join-Path $TestDrive 'encoded-summary.html'
        Export-OrganizerHTMLReport -Summary $summary -Results @() -OutputPath $path | Out-Null
        $html = Get-Content -LiteralPath $path -Raw
        $html | Should -Not -Match '<script>'
        $html | Should -Match '&lt;script&gt;'
    }
    BeforeEach {
        $tempDir = Join-Path ($TestDrive) ("ReportTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            $resolved = [IO.Path]::GetFullPath($tempDir)
            if (-not $resolved.StartsWith([IO.Path]::GetFullPath($TestDrive).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped TestDrive.' }
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }

    It "Should export move results to CSV report file" {
        $results = @(
            [PSCustomObject]@{ File = "test1.pdf"; Category = "Documents"; SubCategory = "CV"; Status = "Moved"; Destination = "Documents\CV\test1.pdf" }
        )
        $csvPath = Join-Path $tempDir "reports\report.csv"
        $exported = Export-OrganizerCSV -Results $results -OutputPath $csvPath

        Test-Path $exported | Should -Be $true
        $content = Get-Content $exported -Raw
        ($content -match "test1\.pdf") | Should -Be $true
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

        Test-Path $exported | Should -Be $true
        $content = Get-Content $exported -Raw
        ($content -match "GeneratedAt") | Should -Be $true
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

        Test-Path $exported | Should -Be $true
        $content = Get-Content $exported -Raw
        ($content -match "Download Organizer Pro") | Should -Be $true
    }

    It "Should aggregate historical statistics across log files" {
        $logsDir = Join-Path $tempDir "logs"
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
        $logFile = Join-Path $logsDir "organizer-2026-07-26.log"
        "[2026-07-26 11:59:59] [INFO] Organizer Started`n[2026-07-26 12:00:00] [SUCCESS] Moved: f1.pdf -> Documents\f1.pdf`n[2026-07-26 12:00:01] [ERROR] Failed: f2.pdf | Access Denied" | Set-Content -Path $logFile

        $stats = Get-OrganizerStatistics -LogPath $logsDir
        $stats.TotalExecutions | Should -Be 1
        $stats.TotalMoved | Should -Be 1
        $stats.TotalFailed | Should -Be 1
    }
}
