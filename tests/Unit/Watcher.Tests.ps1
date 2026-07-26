$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Watcher.psm1" -Force

Describe "Watcher Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("WatcherTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        $dummyScript = Join-Path $tempDir "dummy_script.ps1"
        "Write-Host 'Running'" | Set-Content -Path $dummyScript
    }

    AfterEach {
        Stop-OrganizerWatcher | Out-Null
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }

    It "Should start watcher instance and return active status" {
        $dummyScript = Join-Path $tempDir "dummy_script.ps1"
        $inst = Start-OrganizerWatcher -Path $tempDir -ScriptPath $dummyScript -DebounceSeconds 1
        $inst | Should Not Be $null

        $status = Get-OrganizerWatcherStatus
        $status.IsActive | Should Be $true
        $status.Path | Should Be $tempDir
    }

    It "Should stop watcher instance cleanly" {
        $dummyScript = Join-Path $tempDir "dummy_script.ps1"
        Start-OrganizerWatcher -Path $tempDir -ScriptPath $dummyScript -DebounceSeconds 1

        $stopped = Stop-OrganizerWatcher
        $stopped | Should Be $true

        $status = Get-OrganizerWatcherStatus
        $status.IsActive | Should Be $false
    }
}
