$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1" -Force
Import-Module "$ProjectRoot\modules\Utils.psm1" -Force
Import-Module "$ProjectRoot\modules\Summary.psm1" -Force

Describe "Summary Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("SummaryTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }

    It "Should calculate summary statistics correctly" {
        $f1 = Join-Path $tempDir "file1.pdf"
        $f2 = Join-Path $tempDir "file2.jpg"
        "content 1" | Set-Content -Path $f1
        "content 2" | Set-Content -Path $f2

        $fileInfo1 = Get-Item $f1
        $fileInfo2 = Get-Item $f2

        $org1 = New-OrganizerFile -File $fileInfo1
        $org1.SetCategory("Documents")
        $org2 = New-OrganizerFile -File $fileInfo2
        $org2.SetCategory("Images")

        $results = @(
            [PSCustomObject]@{ Status = "Moved" }
            [PSCustomObject]@{ Status = "Moved" }
        )

        $start = Get-Date
        $end = $start.AddSeconds(2)

        $summary = Get-OrganizerSummary -Files @($org1, $org2) -Results $results -StartTime $start -EndTime $end

        $summary.TotalFiles | Should Be 2
        $summary.Moved | Should Be 2
        $summary.Failed | Should Be 0
        $summary.Duration.TotalSeconds | Should Be 2
        $summary.Categories["Documents"] | Should Be 1
        $summary.Categories["Images"] | Should Be 1
    }

    It "Should display execution summary without error" {
        $summary = New-OrganizerSummary
        $summary.TotalFiles = 5
        $summary.Moved = 4
        $summary.Failed = 1
        $summary.TotalSizeMB = 1.25
        $summary.Duration = [TimeSpan]::FromSeconds(3.5)
        $summary.Categories["Documents"] = 3
        $summary.Categories["Images"] = 2

        { Show-OrganizerSummary -Summary $summary -LogFile ".\logs\test.log" } | Should Not Throw
    }
}
