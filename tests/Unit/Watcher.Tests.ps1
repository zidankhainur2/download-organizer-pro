BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Watcher.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "Watcher Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ($TestDrive) ("WatcherTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        $dummyScript = Join-Path $tempDir "dummy_script.ps1"
        "Write-Host 'Running'" | Set-Content -Path $dummyScript
    }

    AfterEach {
        Stop-OrganizerWatcher | Out-Null
        if (Test-Path $tempDir) {
            $resolved = [IO.Path]::GetFullPath($tempDir)
            if (-not $resolved.StartsWith([IO.Path]::GetFullPath($TestDrive).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped TestDrive.' }
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }

    It "Should start watcher instance and return active status" {
        $dummyScript = Join-Path $tempDir "dummy_script.ps1"
        $inst = Start-OrganizerWatcher -Path $tempDir -ScriptPath $dummyScript -DebounceSeconds 1
        $inst | Should -Not -Be $null

        $status = Get-OrganizerWatcherStatus
        $status.IsActive | Should -Be $true
        $status.Path | Should -Be $tempDir
    }

    It "Should stop watcher instance cleanly" {
        $dummyScript = Join-Path $tempDir "dummy_script.ps1"
        Start-OrganizerWatcher -Path $tempDir -ScriptPath $dummyScript -DebounceSeconds 1

        $stopped = Stop-OrganizerWatcher
        $stopped | Should -Be $true

        $status = Get-OrganizerWatcherStatus
        $status.IsActive | Should -Be $false
    }
}
