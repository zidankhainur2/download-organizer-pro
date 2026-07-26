$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Scheduler.psm1" -Force

Describe "Scheduler Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("SchedTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        $dummyScript = Join-Path $tempDir "DownloadOrganizer.ps1"
        "Write-Host 'Dummy Script'" | Set-Content -Path $dummyScript
    }

    AfterEach {
        Unregister-OrganizerTask -TaskName "DownloadOrganizerTestTask" | Out-Null
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }

    It "Should check task existence via Get-OrganizerTask" {
        $task = Get-OrganizerTask -TaskName "NonExistentTestTask_999"
        $task.TaskName | Should Be "NonExistentTestTask_999"
        $task.IsRegistered | Should Be $false
    }
}
