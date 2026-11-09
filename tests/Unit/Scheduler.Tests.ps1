BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Scheduler.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "Scheduler Module Unit Tests" {
    BeforeEach {
        Mock Get-ScheduledTask { $null } -ModuleName Scheduler
        Mock Unregister-ScheduledTask {} -ModuleName Scheduler
        Mock Register-ScheduledTask {} -ModuleName Scheduler -RemoveParameterType @('Action', 'Trigger', 'Principal', 'Settings') -RemoveParameterValidation @('Action', 'Trigger', 'Principal', 'Settings')

        $tempDir = Join-Path ($TestDrive) ("SchedTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        $dummyScript = Join-Path $tempDir "DownloadOrganizer.ps1"
        "Write-Host 'Dummy Script'" | Set-Content -Path $dummyScript
    }

    AfterEach {

        if (Test-Path $tempDir) {
            $resolved = [IO.Path]::GetFullPath($tempDir)
            if (-not $resolved.StartsWith([IO.Path]::GetFullPath($TestDrive).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped TestDrive.' }
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }

    It "Should check task existence via Get-OrganizerTask" {
        $task = Get-OrganizerTask -TaskName "NonExistentTestTask_999"
        $task.TaskName | Should -Be "NonExistentTestTask_999"
        $task.IsRegistered | Should -Be $false
    }
    It 'registers the current user with literal arguments and configured interval' {
        Mock New-ScheduledTaskAction { [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_TaskAction', 'Root/Microsoft/Windows/TaskScheduler') } -ModuleName Scheduler
        Mock New-ScheduledTaskTrigger { [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_TaskTrigger', 'Root/Microsoft/Windows/TaskScheduler') } -ModuleName Scheduler
        Mock New-ScheduledTaskPrincipal { [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_TaskPrincipal', 'Root/Microsoft/Windows/TaskScheduler') } -ModuleName Scheduler
        Mock New-ScheduledTaskSettingsSet { [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_TaskSettings', 'Root/Microsoft/Windows/TaskScheduler') } -ModuleName Scheduler
        Register-OrganizerTask -ScriptPath $dummyScript -TaskName 'test & literal' -DownloadsPath 'C:\a & [1]' -ConfigPath 'C:\config & [1].json' -IntervalMinutes 17 | Should -BeTrue
        Should -Invoke New-ScheduledTaskTrigger -ModuleName Scheduler -Exactly 1 -ParameterFilter { $RepetitionInterval.TotalMinutes -eq 17 }
        Should -Invoke New-ScheduledTaskPrincipal -ModuleName Scheduler -Exactly 1 -ParameterFilter { $LogonType -eq 'Interactive' -and $RunLevel -eq 'Limited' }
        Should -Invoke Register-ScheduledTask -ModuleName Scheduler -Exactly 1 -ParameterFilter { $TaskName -eq 'test & literal' }
        Should -Invoke New-ScheduledTaskAction -ModuleName Scheduler -Exactly 1 -ParameterFilter { $Argument.Contains('"C:\a & [1]"') -and $Argument.Contains('"C:\config & [1].json"') }
    }
    It 'reports registration failures' {
        Mock New-ScheduledTaskAction { [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_TaskAction', 'Root/Microsoft/Windows/TaskScheduler') } -ModuleName Scheduler
        Mock New-ScheduledTaskTrigger { [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_TaskTrigger', 'Root/Microsoft/Windows/TaskScheduler') } -ModuleName Scheduler
        Mock New-ScheduledTaskPrincipal { [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_TaskPrincipal', 'Root/Microsoft/Windows/TaskScheduler') } -ModuleName Scheduler
        Mock New-ScheduledTaskSettingsSet { [Microsoft.Management.Infrastructure.CimInstance]::new('MSFT_TaskSettings', 'Root/Microsoft/Windows/TaskScheduler') } -ModuleName Scheduler
        Mock Register-ScheduledTask { throw 'registration denied' } -ModuleName Scheduler -RemoveParameterType @('Action', 'Trigger', 'Principal', 'Settings') -RemoveParameterValidation @('Action', 'Trigger', 'Principal', 'Settings')
        { Register-OrganizerTask -ScriptPath $dummyScript } | Should -Throw '*registration denied*'
    }
}
