BeforeAll {
    $ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$ProjectRoot/DownloadOrganizerPro.psd1"
    Import-Module "$ProjectRoot/modules/GUI.psm1"
    . "$ProjectRoot/tests/TestHelpers.ps1"
    function Wait-TestCondition {
        param([scriptblock]$Condition, [int]$Seconds = 20)
        $deadline = (Get-Date).AddSeconds($Seconds)
        do {
            if (& $Condition) { return $true }
            Start-Sleep -Milliseconds 150
        } while ((Get-Date) -lt $deadline)
        return $false
    }
}
Describe 'Sandbox integration' {
    BeforeEach {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($root) | Out-Null
    }
    AfterEach { Stop-OrganizerWatcher | Out-Null }
    It 'handles real Created and Renamed events, debounces bursts, and cleans subscriptions' {
        $downloads = Join-Path $root 'downloads & [1] $thing'
        [IO.Directory]::CreateDirectory($downloads) | Out-Null
        $worker = Join-Path $root 'worker & [1].ps1'
        $configPath = Join-Path $root 'config & [1].json'
        $marker = $configPath + '.ran'
        @'
param([switch]$Silent, [string]$DownloadsPath, [string]$ConfigPath)
@{ DownloadsPath = $DownloadsPath; ConfigPath = $ConfigPath } | ConvertTo-Json -Compress | Add-Content -LiteralPath ($ConfigPath + '.ran')
Start-Sleep -Milliseconds 1000
'@ | Set-Content -LiteralPath $worker
        Start-OrganizerWatcher -Path $downloads -ScriptPath $worker -ConfigPath $configPath -DebounceSeconds 1 | Out-Null
        foreach ($name in @('setup.exe', 'data.json', 'page.html')) { [IO.File]::WriteAllText((Join-Path $downloads $name), 'download') }
        Wait-TestCondition { Test-Path -LiteralPath $marker } | Should -BeTrue
        Start-Sleep -Milliseconds 1600
        $lines = @(Get-Content -LiteralPath $marker)
        $lines.Count | Should -Be 1
        ($lines[0] | ConvertFrom-Json).DownloadsPath | Should -Be $downloads
        ($lines[0] | ConvertFrom-Json).ConfigPath | Should -Be $configPath
        [IO.File]::WriteAllText("$downloads/next.crdownload", 'partial')
        Start-Sleep -Milliseconds 1200
        @(Get-Content -LiteralPath $marker).Count | Should -Be 1
        [IO.File]::Move("$downloads/next.crdownload", "$downloads/next.exe")
        $renamed = Wait-TestCondition { @(Get-Content -LiteralPath $marker).Count -ge 2 }
        if (-not $renamed) {
            $errors = & (Get-Module Watcher) { $script:WatcherState.Jobs | ForEach-Object { $_.Error | Out-String } }
            throw "Renamed download did not trigger worker: $((Get-OrganizerWatcherStatus).LastError) $errors"
        }
        @(Get-Content -LiteralPath $marker).Count | Should -Be 2
        Stop-OrganizerWatcher | Should -BeTrue
        @(Get-EventSubscriber | Where-Object SourceIdentifier -like 'OrganizerWatcher-*').Count | Should -Be 0
        @(Get-Job -Name 'OrganizerWatcher-*' -ErrorAction SilentlyContinue).Count | Should -Be 0
    }
    It 'rejects junction destinations and never scans junction children' {
        $outside = Join-Path $root 'outside'
        $downloads = Join-Path $root 'downloads'
        [IO.Directory]::CreateDirectory($outside) | Out-Null
        [IO.Directory]::CreateDirectory($downloads) | Out-Null
        $junction = Join-Path $downloads 'Documents'
        New-Item -ItemType Junction -Path $junction -Target $outside -ErrorAction Stop | Out-Null
        try {
            [IO.File]::WriteAllText("$outside/hidden.pdf", 'outside')
            [IO.File]::WriteAllText("$downloads/file.pdf", 'source')
            $files = @(Get-DownloadFiles $downloads -Recurse)
            $files.Count | Should -Be 1
            $files[0].SetCategory('Documents')
            @(Move-OrganizerFiles $files $downloads)[0].Status | Should -Be Failed
            [IO.File]::ReadAllText("$outside/hidden.pdf") | Should -Be outside
        }
        finally { [IO.Directory]::Delete($junction) }
    }
    It 'finishes its active watcher worker before reporting a clean stop' {
        $worker = Join-Path $root 'finishing.ps1'
        $marker = Join-Path $root 'finished'
        @'
param($Marker)
Start-Sleep -Seconds 2
[IO.File]::WriteAllText($Marker, 'finished')
'@ | Set-Content -LiteralPath $worker
        Start-OrganizerWatcher -Path $root -ScriptPath $worker | Out-Null
        $arguments = '-NoProfile -File ' + (ConvertTo-WindowsArgument $worker) + ' ' + (ConvertTo-WindowsArgument $marker)
        $process = Start-Process powershell.exe -ArgumentList $arguments -PassThru -WindowStyle Hidden
        $observer = [Diagnostics.Process]::GetProcessById($process.Id)
        try {
            & (Get-Module Watcher -All | Select-Object -First 1) { param($process) $script:WatcherState.Process = $process } $process
            Stop-OrganizerWatcher | Should -BeTrue
            $observer.HasExited | Should -BeTrue
            [IO.File]::ReadAllText($marker) | Should -Be finished
        }
        finally { $observer.WaitForExit(); $observer.Dispose() }
    }
    It 'shares the folder lock across processes and permits recovery after the owner exits' {
        $signal = Join-Path $root 'signal'
        $worker = Join-Path $root 'lock.ps1'
        @'
param($ProjectRoot, $Folder, $Signal)
Import-Module "$ProjectRoot/modules/Utils.psm1"
$lock = Enter-OrganizerLock $Folder
try { [IO.File]::WriteAllText($Signal, 'locked'); Start-Sleep -Seconds 3 }
finally { $lock.ReleaseMutex(); $lock.Dispose() }
'@ | Set-Content -LiteralPath $worker
        $argsText = '-NoProfile -File ' + (ConvertTo-WindowsArgument $worker) + ' ' + (ConvertTo-WindowsArgument $ProjectRoot) + ' ' + (ConvertTo-WindowsArgument $root) + ' ' + (ConvertTo-WindowsArgument $signal)
        $process = Start-Process powershell.exe -ArgumentList $argsText -PassThru -WindowStyle Hidden
        try {
            Wait-TestCondition { Test-Path -LiteralPath $signal } | Should -BeTrue
            { Enter-OrganizerLock $root } | Should -Throw
            $process.WaitForExit()
            $lock = Enter-OrganizerLock $root
            $lock.ReleaseMutex(); $lock.Dispose()
        }
        finally { $process.WaitForExit(); $process.Dispose() }
    }
    It 'runs the GUI worker asynchronously using the same result contract' {
        [IO.File]::WriteAllText("$root/a.pdf", 'content')
        $config = New-TestConfig $root
        $config.Settings.DryRun = $true
        $config.Settings.CreateLogs = $false
        $state = @{}
        & (Get-Module GUI) { param($state, $config, $root) Start-OrganizerGUIWorker $state $config $root } $state $config $ProjectRoot
        try {
            $state.Handle.AsyncWaitHandle.WaitOne(15000) | Should -BeTrue
            $result = @($state.Worker.EndInvoke($state.Handle))[-1]
            $state.Worker.HadErrors | Should -BeFalse
            $result.Summary.Planned | Should -Be 1
            Test-Path -LiteralPath "$root/a.pdf" | Should -BeTrue
        }
        finally { $state.Worker.Dispose(); $state.Runspace.Dispose() }
    }
}
