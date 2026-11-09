BeforeAll {
    $ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $harness = Join-Path $ProjectRoot 'tests/Invoke-GUIVerification.ps1'
    Import-Module "$ProjectRoot/DownloadOrganizerPro.psd1"
    function Invoke-HarnessProcess {
        param([string[]]$Arguments)
        $stdout = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '.stdout')
        $stderr = $stdout + '.stderr'
        $argsText = (@('-NoProfile','-STA','-File',$harness) + $Arguments | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' '
        $engine = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $process = Start-Process $engine -ArgumentList $argsText -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        try {
            $process.WaitForExit()
            [pscustomobject]@{ ExitCode = $process.ExitCode; Output = @(Get-Content -LiteralPath $stdout); Error = (Get-Content -LiteralPath $stderr -Raw) }
        }
        finally { $process.Dispose() }
    }
}
Describe 'GUI verification harness safety and assertions' {
    It 'shows the locked-file reason and recovers controls in the real window' {
        $probe = @{ Clicked = $false; Console = ''; Session = '' }
        $timer = [Windows.Threading.DispatcherTimer]::new()
        $timer.Interval = [timespan]::FromMilliseconds(150)
        $timer.Add_Tick({
            $win = @([Windows.Interop.HwndSource]::CurrentSources | ForEach-Object { $_.RootVisual } | Where-Object { $_ -is [Windows.Window] -and $_.FindName('BtnStart') }) | Select-Object -First 1
            if (-not $win) { return }
            if (-not $probe.Clicked) {
                $probe.Clicked = $true
                $probe.Session = Split-Path $win.FindName('TxtFolderPath').Text -Parent
                $win.FindName('BtnStart').RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent))
            }
            elseif ($win.FindName('BtnStart').IsEnabled) {
                $probe.Console = $win.FindName('TxtLogConsole').Text
                $timer.Stop()
                $win.Close()
            }
        }.GetNewClosure())
        $timer.Start()
        try { & $harness -Scenario Locked -Notes 'Automated locked-file GUI regression.' }
        finally { $timer.Stop() }
        $probe.Console | Should -Match '\[ERROR\] a.pdf:'
        $parent = [IO.Path]::GetFullPath((Join-Path $ProjectRoot '.tools/verification'))
        if (-not ([IO.Path]::GetFullPath($probe.Session)).StartsWith($parent + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped verification workspace.' }
        Remove-Item -LiteralPath $probe.Session -Recurse -Force
    }
    It 'runs a real watcher worker with compatible module paths and then supports Background mode' {
        $prepared = Invoke-HarnessProcess @('-Scenario','Single','-PrepareOnly')
        $prepared.ExitCode | Should -Be 0 -Because $prepared.Error
        $sessionPath = $prepared.Output[-1]
        $runtime = Join-Path $sessionPath 'runtime'
        $target = Join-Path $sessionPath 'downloads & [1]'
        $configPath = Join-Path $runtime 'config.json'
        $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        $config.Settings.DownloadsPath = $target
        $config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $configPath -Encoding UTF8
        $inheritedPath = $env:PSModulePath
        try {
            $env:PSModulePath = (Join-Path $ProjectRoot '.tools/pwsh/Modules') + ';' + $inheritedPath
            Start-OrganizerWatcher -Path $target -ScriptPath (Join-Path $runtime 'DownloadOrganizer.ps1') -ConfigPath $configPath -DebounceSeconds 1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $target 'trigger.pdf'), 'trigger payload')
            $deadline = (Get-Date).AddSeconds(25)
            while (-not [IO.File]::Exists((Join-Path $target 'Documents/a.pdf')) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 150 }
            Stop-OrganizerWatcher | Out-Null
            [IO.File]::ReadAllText((Join-Path $target 'Documents/a.pdf')) | Should -Be 'single payload'
            [IO.File]::WriteAllText((Join-Path $target 'background.pdf'), 'background payload')
            $completion = Join-Path $sessionPath 'background-complete.pid'
            $marker = "`n[IO.File]::WriteAllText('" + $completion.Replace("'", "''") + "', [string]" + '$PID' + ')'
            Add-Content -LiteralPath (Join-Path $runtime 'DownloadOrganizer.ps1') -Value $marker
            & (Join-Path $runtime 'DownloadOrganizer.ps1') -Background -ConfigPath $configPath
            $deadline = (Get-Date).AddSeconds(25)
            while (-not [IO.File]::Exists($completion) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 150 }
            Test-Path -LiteralPath $completion | Should -BeTrue
            $observer = Get-Process -Id ([int][IO.File]::ReadAllText($completion)) -ErrorAction SilentlyContinue
            if ($observer) { try { $observer.WaitForExit(10000) | Should -BeTrue } finally { $observer.Dispose() } }
            [IO.File]::ReadAllText((Join-Path $target 'Documents/background.pdf')) | Should -Be 'background payload'
        }
        finally {
            $env:PSModulePath = $inheritedPath
            Stop-OrganizerWatcher | Out-Null
            $parent = [IO.Path]::GetFullPath((Join-Path $ProjectRoot '.tools/verification'))
            if (-not ([IO.Path]::GetFullPath($sessionPath)).StartsWith($parent + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped verification workspace.' }
            Remove-Item -LiteralPath $sessionPath -Recurse -Force
        }
    }
    It 'rejects a session outside its workspace' {
        $result = Invoke-HarnessProcess @('-VerifyOnly','-SessionPath',$TestDrive)
        $result.ExitCode | Should -Not -Be 0
        $result.Error | Should -Match 'escaped verification workspace'
    }
    It 'verifies isolated <Scenario> fixtures without claiming human visual approval' -ForEach @(
        @{ Scenario = 'Mixed' }, @{ Scenario = 'DryRun' }, @{ Scenario = 'Overwrite' }, @{ Scenario = 'UndoRetry' }
    ) {
        $prepared = Invoke-HarnessProcess @('-Scenario',$Scenario,'-PrepareOnly')
        $prepared.ExitCode | Should -Be 0 -Because $prepared.Error
        $sessionPath = $prepared.Output[-1]
        $runtime = Join-Path $sessionPath 'runtime'
        $target = Join-Path $sessionPath 'downloads & [1]'
        try {
            $config = Get-Content -LiteralPath (Join-Path $runtime 'config.json') -Raw | ConvertFrom-Json
            $config.Settings.DownloadsPath = $target
            if ($Scenario -eq 'UndoRetry') {
                $transaction = (Get-UndoLog (Join-Path $runtime 'logs/transactions'))[0].FullName
                $retry = Invoke-UndoOperation $transaction
                $retry.RestoredCount | Should -Be 1
                $retry.FailedCount | Should -Be 0
            }
            else { $null = Invoke-Organizer $config -OperationalPath (Join-Path $runtime 'logs') }
            $verified = Invoke-HarnessProcess @('-VerifyOnly','-SessionPath',$sessionPath)
            $verified.ExitCode | Should -Be 0 -Because $verified.Error
            $result = Get-Content -LiteralPath (Join-Path $sessionPath 'evidence/result.json') -Raw | ConvertFrom-Json
            $result.Filesystem | Should -Be lulus
            $result.Visual | Should -Be 'belum diuji'
            $result.Status | Should -Be 'belum diuji'
            [IO.File]::WriteAllText((Join-Path $target 'tampered.txt'), 'unexpected')
            $tampered = Invoke-HarnessProcess @('-VerifyOnly','-SessionPath',$sessionPath)
            $tampered.ExitCode | Should -Not -Be 0
        }
        finally {
            $parent = [IO.Path]::GetFullPath((Join-Path $ProjectRoot '.tools/verification'))
            $resolved = [IO.Path]::GetFullPath($sessionPath)
            if (-not $resolved.StartsWith($parent + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped verification workspace.' }
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
}
