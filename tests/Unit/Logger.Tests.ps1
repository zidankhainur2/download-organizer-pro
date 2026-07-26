$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Logger.psm1" -Force

Describe "Logger Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("LoggerTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }

    It "Should initialize logger directory and create log file" {
        $logFile = Initialize-Logger -LogPath $tempDir
        Test-Path $logFile | Should Be $true
        ($logFile -match "organizer-") | Should Be $true
    }

    It "Should append formatted entry to log file with Write-OrganizerLog" {
        $logFile = Initialize-Logger -LogPath $tempDir
        Write-OrganizerLog -LogFile $logFile -Message "Test Info Message" -Level "INFO"
        Write-OrganizerLog -LogFile $logFile -Message "Test Error Message" -Level "ERROR"

        $lines = Get-Content $logFile
        ($lines | Where-Object { $_ -match "\[INFO\] Test Info Message" }) | Should Not Be $null
        ($lines | Where-Object { $_ -match "\[ERROR\] Test Error Message" }) | Should Not Be $null
    }

    It "Should write move results log entries with Write-MoveLog" {
        $logFile = Initialize-Logger -LogPath $tempDir
        $results = @(
            [PSCustomObject]@{ File = "doc1.pdf"; Status = "Moved"; Destination = "Documents\doc1.pdf" }
            [PSCustomObject]@{ File = "doc2.pdf"; Status = "Failed"; Destination = "Access Denied" }
        )

        Write-MoveLog -LogFile $logFile -Results $results
        $lines = Get-Content $logFile
        ($lines | Where-Object { $_ -match "\[SUCCESS\] Moved: doc1\.pdf -> Documents\\doc1\.pdf" }) | Should Not Be $null
        ($lines | Where-Object { $_ -match "\[ERROR\] Failed: doc2\.pdf \| Access Denied" }) | Should Not Be $null
    }
}
