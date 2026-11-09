[CmdletBinding()]
param(
    [ValidateSet('Empty','Single','Mixed','SmartOff','UnknownOff','DryRun','Rename','Skip','Overwrite','Undo','UndoConflict','UndoRetry','Watcher','Scheduler','Unavailable','Locked','WorkerError','Scale','CloseDuringWork','Launcher')]
    [string]$Scenario = 'Single',
    [string]$SessionPath = '',
    [switch]$PrepareOnly,
    [switch]$VerifyOnly,
    [ValidateSet('belum diuji','lulus','gagal','terhalang')][string]$VisualStatus = 'belum diuji',
    [string]$Notes = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$parent = [IO.Path]::GetFullPath((Join-Path $projectRoot '.tools/verification'))
if ($PrepareOnly -and $VerifyOnly) { throw 'Choose PrepareOnly or VerifyOnly.' }
if ($VerifyOnly -and -not $SessionPath) { throw 'VerifyOnly requires SessionPath.' }

function Assert-Verification { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw $Message } }
function Get-Inventory {
    param([string]$Root)
    if (-not [IO.Directory]::Exists($Root)) { return }
    Get-ChildItem -LiteralPath $Root -Recurse -File | Sort-Object FullName | ForEach-Object {
        [pscustomobject]@{ Path = $_.FullName.Substring($Root.Length + 1); Size = $_.Length; SHA256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    }
}
function Write-Json { param($Value, [string]$Path) ConvertTo-Json -InputObject $Value -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8 }
function Assert-Inventory {
    param($Expected, $Actual)
    $left = @($Expected | ForEach-Object { "$($_.Path)|$($_.Size)|$($_.SHA256)" })
    $right = @($Actual | ForEach-Object { "$($_.Path)|$($_.Size)|$($_.SHA256)" })
    Assert-Verification (($left -join "`n") -ceq ($right -join "`n")) 'File paths, sizes or SHA256 differ from the expected inventory.'
}

if ($SessionPath) {
    $SessionPath = [IO.Path]::GetFullPath($SessionPath)
    Assert-Verification ($SessionPath.StartsWith($parent.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) 'Session escaped verification workspace.'
    $session = Get-Content -LiteralPath (Join-Path $SessionPath 'session.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Verification ((Split-Path $SessionPath -Leaf) -ceq ($session.Scenario + '-' + $session.Id)) 'Session identity mismatch.'
    Assert-Verification ($session.Id -cmatch '^[a-f0-9]{32}$' -and $session.TaskName -ceq ('DownloadOrganizerPro-Verify-' + $session.Id)) 'Invalid session task identity.'
    $Scenario = $session.Scenario
}
else {
    $id = [guid]::NewGuid().ToString('N')
    $SessionPath = Join-Path $parent "$Scenario-$id"
    [IO.Directory]::CreateDirectory($SessionPath) | Out-Null
    $session = [pscustomobject]@{ Id = $id; Scenario = $Scenario; Created = (Get-Date -Format o); TaskName = "DownloadOrganizerPro-Verify-$id" }
    Write-Json $session (Join-Path $SessionPath 'session.json')
}
$runtime = Join-Path $SessionPath 'runtime'
$target = Join-Path $SessionPath 'downloads & [1]'
$configPath = Join-Path $runtime 'config.json'
$ops = Join-Path $runtime 'logs'
$evidence = Join-Path $SessionPath 'evidence'
[IO.Directory]::CreateDirectory($evidence) | Out-Null
$env:DOP_VERIFY_TARGET = $target

if (-not $VerifyOnly -and -not [IO.Directory]::Exists($runtime)) {
    [IO.Directory]::CreateDirectory($runtime) | Out-Null
    foreach ($name in @('DownloadOrganizer.ps1','DownloadOrganizerPro.psd1','DownloadOrganizerPro.psm1','config.json')) {
        Copy-Item -LiteralPath (Join-Path $projectRoot $name) -Destination $runtime
    }
    foreach ($folder in @('modules','assets')) {
        $destination = Join-Path $runtime $folder
        [IO.Directory]::CreateDirectory($destination) | Out-Null
        Get-ChildItem -LiteralPath (Join-Path $projectRoot $folder) -File | Where-Object { $_.Extension -in @('.psm1','.xaml','.ico') } | Copy-Item -Destination $destination
    }
    if ($Scenario -eq 'Launcher') { Copy-Item -LiteralPath (Join-Path $projectRoot 'dist/DownloadOrganizerPro.exe') -Destination $runtime }
    $snapshot = @(Get-Inventory $runtime)
    Write-Json ([ordered]@{ Head = (git -C $projectRoot rev-parse HEAD); RuntimeFiles = $snapshot; PowerShell = $PSVersionTable.PSVersion.ToString(); Apartment = [Threading.Thread]::CurrentThread.ApartmentState.ToString(); OS = [Environment]::OSVersion.VersionString }) (Join-Path $evidence 'source.json')
    [IO.Directory]::CreateDirectory($target) | Out-Null
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $config.Settings.DownloadsPath = '%DOP_VERIFY_TARGET%'
    foreach ($format in @('CSV','JSON','HTML')) { $config.Settings."Export$format" = $true }
    $config.Settings.WatcherDebounceSeconds = 1
    $config.Settings.ScheduleIntervalMinutes = 17
    $fixtures = [ordered]@{}
    switch ($Scenario) {
        Empty {}
        { $_ -in @('Mixed','SmartOff','UnknownOff','DryRun') } {
            $fixtures['resume [1].pdf'] = 'cv payload'
            $fixtures['invoice 2026.pdf'] = 'finance payload'
            $fixtures['photo.png'] = 'duplicate payload'
            $fixtures['copy.png'] = 'duplicate payload'
            $fixtures['setup.exe'] = 'installer fixture, never execute'
            $fixtures['file.unknown'] = 'unknown payload'
            $fixtures[('catatan ' + [char]0x65e5 + [char]0x672c + '.txt')] = 'unicode payload'
            if ($Scenario -eq 'SmartOff') { $config.Settings.EnableSmartRules = $false }
            if ($Scenario -eq 'UnknownOff') { $config.Settings.MoveUnknownFiles = $false }
            if ($Scenario -eq 'DryRun') { $config.Settings.DryRun = $true }
        }
        { $_ -in @('Rename','Skip','Overwrite','Undo','UndoConflict','UndoRetry') } {
            $fixtures['a.pdf'] = 'new a'
            $fixtures['b.pdf'] = 'new b'
            $fixtures['Documents/a.pdf'] = 'old a'
            $config.Settings | Add-Member ConflictAction $(if ($_ -in @('Rename','Skip')) { $_ } else { 'Overwrite' })
        }
        { $_ -in @('Scale','CloseDuringWork') } {
            $config.Settings.Recursive = $true
            for ($i = 0; $i -lt 10000; $i++) { $fixtures[('batch-{0}/invoice_{1}.pdf' -f [int][math]::Floor($i / 1000), ($i % 1000))] = "payload $i" }
        }
        Watcher {
            $config.Settings.DownloadsPath = Join-Path $SessionPath 'default decoy'
            [IO.Directory]::CreateDirectory($config.Settings.DownloadsPath) | Out-Null
            [IO.File]::WriteAllText((Join-Path $config.Settings.DownloadsPath 'untouched.pdf'), 'decoy')
        }
        default { $fixtures['a.pdf'] = 'single payload' }
    }
    foreach ($path in $fixtures.Keys) {
        $file = Join-Path $target $path
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($file)) | Out-Null
        [IO.File]::WriteAllText($file, $fixtures[$path])
    }
    Write-Json $config $configPath
    Copy-Item -LiteralPath $configPath -Destination (Join-Path $evidence 'effective-config.json')
    Write-Json @(Get-Inventory $target) (Join-Path $evidence 'initial.json')
    if ($Scenario -in @('Undo','UndoConflict','UndoRetry')) {
        Import-Module (Join-Path $runtime 'DownloadOrganizerPro.psd1')
        $null = Invoke-Organizer $config -OperationalPath $ops
        $transaction = (Get-UndoLog (Join-Path $ops 'transactions'))[0].FullName
        if ($Scenario -in @('UndoConflict','UndoRetry')) {
            [IO.File]::WriteAllText((Join-Path $target 'a.pdf'), 'source conflict')
            $partial = Invoke-UndoOperation $transaction
            Assert-Verification ($partial.RestoredCount -eq 1 -and $partial.FailedCount -eq 1) 'Partial Undo fixture failed.'
            Write-Json $partial (Join-Path $evidence 'partial-undo.json')
            if ($Scenario -eq 'UndoRetry') { [IO.File]::Move((Join-Path $target 'a.pdf'), (Join-Path $evidence 'source-conflict.saved')) }
        }
    }
    if ($Scenario -eq 'WorkerError') {
        [IO.Directory]::CreateDirectory($ops) | Out-Null
        [IO.File]::WriteAllText((Join-Path $ops 'reports'), 'deliberate report directory obstacle')
    }
    if ($Scenario -eq 'Watcher') {
        @'
param([ValidateSet('Created','Renamed','Burst')][string]$Action = 'Created')
$target = Join-Path $PSScriptRoot 'downloads & [1]'
switch ($Action) {
    Created { [IO.File]::WriteAllText((Join-Path $target 'created.pdf'), 'created payload') }
    Renamed {
        [IO.File]::WriteAllText((Join-Path $target 'setup.crdownload'), 'rename payload')
        Start-Sleep -Seconds 3
        [IO.File]::Move((Join-Path $target 'setup.crdownload'), (Join-Path $target 'setup.exe'))
    }
    Burst {
        1..20 | ForEach-Object { [IO.File]::WriteAllText((Join-Path $target "burst-$_.txt"), "burst $_") }
        [IO.File]::WriteAllText((Join-Path $target 'ignored.tmp'), 'ignored payload')
    }
}
'@ | Set-Content -LiteralPath (Join-Path $SessionPath 'Feed-Watcher.ps1') -Encoding UTF8
    }
    $action = switch ($Scenario) {
        { $_ -in @('Undo','UndoConflict','UndoRetry') } { 'Fixture already organized. Click UNDO LAST MOVE directly once. Do not click START ORGANIZING.' }
        Watcher { 'Browse to the printed target (not default decoy). START WATCHER; feed Created/Renamed/Burst from another terminal, then STOP/START/STOP. Do not click START ORGANIZING.' }
        Scheduler { 'Click SCHEDULE; wait until Documents/a.pdf appears, then click SCHEDULE again and check Removed. Do not click START ORGANIZING.' }
        CloseDuringWork { 'Click START ORGANIZING, then X while busy. Wait for the transaction to finish.' }
        Launcher { 'Wait for evidence/launcher.json, then click START ORGANIZING. Do not use Schedule in the public launcher scenario.' }
        default { 'Click START ORGANIZING, wait for completion, inspect results and STATS REPORT, then close.' }
    }
    @"
Scenario: $Scenario
Session: $SessionPath
Target: $target
Task: $($session.TaskName)
Checklist: $projectRoot/docs/GUI_VERIFICATION.md
REQUIRED ACTION: $action
After the required actions, close the window. Assertions then run; visual status stays pending until explicitly recorded.
"@ | Set-Content -LiteralPath (Join-Path $SessionPath 'instructions.txt') -Encoding UTF8
}
if ($PrepareOnly) { Write-Output $SessionPath; return }
Assert-Verification (Test-Path -LiteralPath $configPath) 'Session runtime is missing.'
$capture = @{ Window = $null; Samples = [Collections.Generic.List[object]]::new(); LastBusy = $false; LastTick = [datetime]::UtcNow; MaxTickGapMs = 0.0; FeedbackMs = $null; BusyStart = $null; Scheduler = $false; SchedulerError = '' }
$conflictingControls = @('BtnStart','BtnUndo','BtnWatcher','BtnSchedule','BtnBrowse','TxtFolderPath','ChkSmartRules','ChkDryRun','ChkRecurse','ChkExportHTML','ChkExportCSV')
$lockHandle = $null
$timer = $null
$errorText = ''
$filesystemStatus = 'gagal'
$started = Get-Date
try {
    if (-not $VerifyOnly) {
        Assert-Verification ([Threading.Thread]::CurrentThread.ApartmentState -eq 'STA') 'Run this script with -STA.'
        Get-Content -LiteralPath (Join-Path $SessionPath 'instructions.txt') | Write-Host
        Import-Module (Join-Path $runtime 'DownloadOrganizerPro.psd1')
        $windowConfig = $null
        if ($Scenario -eq 'Unavailable') {
            $windowConfig = Get-OrganizerConfig -Path $configPath
            [IO.File]::Delete((Join-Path $target 'a.pdf'))
            [IO.Directory]::Delete($target)
        }
        if ($Scenario -eq 'Locked') { $lockHandle = [IO.File]::Open((Join-Path $target 'a.pdf'), 'Open', 'ReadWrite', 'None') }
        $timer = [Windows.Threading.DispatcherTimer]::new()
        $timer.Interval = [timespan]::FromMilliseconds(250)
        $timer.Add_Tick({
            $now = [datetime]::UtcNow
            $capture.MaxTickGapMs = [math]::Max($capture.MaxTickGapMs, ($now - $capture.LastTick).TotalMilliseconds)
            $capture.LastTick = $now
            if (-not $capture.Window) {
                $capture.Window = @([Windows.Interop.HwndSource]::CurrentSources | ForEach-Object { $_.RootVisual } | Where-Object { $_ -is [Windows.Window] -and $_.FindName('BtnStart') }) | Select-Object -First 1
            }
            $win = $capture.Window
            if (-not $win) { return }
            $busy = -not $win.FindName('BtnStart').IsEnabled
            if ($busy -and -not $capture.LastBusy) { $capture.BusyStart = $now }
            if ($capture.BusyStart -and $null -eq $capture.FeedbackMs -and $win.FindName('TxtLogConsole').Text.Contains('Scanning and classifying')) { $capture.FeedbackMs = ($now - $capture.BusyStart).TotalMilliseconds }
            if ($busy -ne $capture.LastBusy) {
                $capture.Samples.Add([pscustomobject]@{ At = $now.ToString('o'); Busy = $busy; Rows = $win.FindName('GridResults').Items.Count; Scanned = $win.FindName('TxtKpiScanned').Text; EnabledControls = @($conflictingControls | Where-Object { $win.FindName($_).IsEnabled }).Count })
                $capture.LastBusy = $busy
            }
            if ($Scenario -eq 'Scheduler' -and -not $capture.Scheduler -and -not $capture.SchedulerError) {
                try {
                    $task = Get-ScheduledTask -TaskName $session.TaskName -ErrorAction SilentlyContinue
                    if ($task) {
                        Write-Json ([ordered]@{ TaskName = $task.TaskName; Execute = $task.Actions.Execute; Arguments = $task.Actions.Arguments; Interval = $task.Triggers.Repetition.Interval; LogonType = [string]$task.Principal.LogonType; RunLevel = [string]$task.Principal.RunLevel }) (Join-Path $evidence 'scheduled-task.json')
                        Assert-Verification ($task.Actions.Arguments.Contains($runtime) -and $task.Actions.Arguments.Contains($target)) 'Scheduled task does not target this sandbox.'
                        Assert-Verification ($task.Triggers.Repetition.Interval -eq 'PT17M') 'Wrong task interval.'
                        Start-ScheduledTask -TaskName $session.TaskName -ErrorAction Stop
                        $capture.Scheduler = $true
                    }
                }
                catch { $capture.SchedulerError = $_.Exception.Message }
            }
        })
        $capture.LastTick = [datetime]::UtcNow
        $timer.Start()
        if ($Scenario -eq 'Launcher') {
            $timer.Stop()
            $mutex = [Threading.Mutex]::new($false, 'Local\DownloadOrganizerPro_GUI')
            $owned = $false
            try {
                try { $owned = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $owned = $true }
                Assert-Verification $owned 'A public GUI launcher is already open; close it before this scenario.'
            }
            finally { if ($owned) { $mutex.ReleaseMutex() }; $mutex.Dispose() }
            $exe = Join-Path $runtime 'DownloadOrganizerPro.exe'
            $guiArgs = '-GUI -ConfigPath ' + (ConvertTo-WindowsArgument $configPath)
            $public = Start-Process -FilePath $exe -ArgumentList $guiArgs -PassThru -WindowStyle Hidden
            $null = $public.Handle
            try {
                # The launcher takes its mutex before starting PowerShell; wait for that boundary.
                $deadline = (Get-Date).AddSeconds(15)
                do {
                    Start-Sleep -Milliseconds 150
                    $probe = [Threading.Mutex]::new($false, 'Local\DownloadOrganizerPro_GUI')
                    $owned = $false
                    try { try { $owned = $probe.WaitOne(0) } catch [Threading.AbandonedMutexException] { $owned = $true }; $ready = -not $owned }
                    finally { if ($owned) { $probe.ReleaseMutex() }; $probe.Dispose() }
                } while (-not $ready -and -not $public.HasExited -and (Get-Date) -lt $deadline)
                Assert-Verification $ready 'Public GUI launcher did not acquire its mutex.'
                $second = Start-Process -FilePath $exe -ArgumentList $guiArgs -PassThru -WindowStyle Hidden
                $null = $second.Handle
                try { Assert-Verification ($second.WaitForExit(15000) -and $second.ExitCode -eq 0) 'Second GUI launcher did not exit cleanly.' } finally { $second.Dispose() }
                $silent = Start-Process -FilePath $exe -ArgumentList ('-Silent -DryRun -ConfigPath ' + (ConvertTo-WindowsArgument $configPath)) -PassThru -WindowStyle Hidden
                $null = $silent.Handle
                try { Assert-Verification ($silent.WaitForExit(30000) -and $silent.ExitCode -eq 0) 'Silent DryRun did not work while GUI launcher was open.' } finally { $silent.Dispose() }
                Write-Json @{ SecondGUIExitCode = 0; SilentDryRunExitCode = 0 } (Join-Path $evidence 'launcher.json')
                $public.WaitForExit()
                Assert-Verification ($public.ExitCode -eq 0) 'Public GUI launcher failed.'
            }
            finally { $public.WaitForExit(); $public.Dispose() }
        }
        else {
            & (Get-Module GUI -All | Where-Object Path -eq (Join-Path $runtime 'modules/GUI.psm1') | Select-Object -First 1) { param($path, $name, $config) Show-OrganizerWindow -ConfigPath $path -TaskName $name -Config $config } $configPath $session.TaskName $windowConfig
        }
        $timer.Stop()
        if ($lockHandle) { $lockHandle.Dispose(); $lockHandle = $null }
        $win = $capture.Window
        if ($win) {
            $win.FindName('TxtLogConsole').Text | Set-Content -LiteralPath (Join-Path $evidence 'console.txt') -Encoding UTF8
            Write-Json ([ordered]@{ Rows = $win.FindName('GridResults').Items.Count; Scanned = $win.FindName('TxtKpiScanned').Text; Moved = $win.FindName('TxtKpiMoved').Text; Failed = $win.FindName('TxtKpiFailed').Text; Samples = $capture.Samples.ToArray(); MaxDispatcherGapMs = $capture.MaxTickGapMs; FirstFeedbackMs = $capture.FeedbackMs; PeakProcessWorkingSetMB = [math]::Round([Diagnostics.Process]::GetCurrentProcess().PeakWorkingSet64 / 1MB, 2); SessionSeconds = ((Get-Date) - $started).TotalSeconds }) (Join-Path $evidence 'gui.json')
            Assert-Verification (@($conflictingControls | Where-Object { -not $win.FindName($_).IsEnabled }).Count -eq 0) 'Controls did not recover after worker completion/error.'
            Assert-Verification (@($capture.Samples | Where-Object { $_.Busy -and $_.EnabledControls -gt 0 }).Count -eq 0) 'Conflicting controls remained enabled during work.'
        }
        Assert-Verification (@(Get-EventSubscriber | Where-Object SourceIdentifier -like 'OrganizerWatcher-*').Count -eq 0) 'Watcher subscriptions remain.'
    }
    $initial = Get-Content -LiteralPath (Join-Path $evidence 'initial.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $initial = @($initial)
    $actual = @(Get-Inventory $target)
    Write-Json $actual (Join-Path $evidence 'final.json')
    $reports = @(if ([IO.Directory]::Exists((Join-Path $ops 'reports'))) { Get-ChildItem -LiteralPath (Join-Path $ops 'reports') -Filter '*.json' -File | Sort-Object LastWriteTime })
    $runs = @($reports | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json })
    $console = if (Test-Path -LiteralPath (Join-Path $evidence 'console.txt')) { Get-Content -LiteralPath (Join-Path $evidence 'console.txt') -Raw -Encoding UTF8 } else { '' }
    if ($Scenario -in @('Unavailable','Locked','WorkerError')) {
        Assert-Verification ($console -match '\[ERROR\]|Failed:|FAILED|Failed\s+:\s+1') 'Expected actionable failure is missing from the console.'
        if ($Scenario -eq 'Unavailable') { Assert-Verification (-not [IO.Directory]::Exists($target)) 'Missing target was created.' }
        elseif ($Scenario -eq 'Locked') {
            Assert-Inventory $initial $actual
            Assert-Verification ($runs.Count -gt 0 -and $console.Contains($runs[-1].Results[0].Reason)) 'Locked-file failure reason is missing from the GUI console.'
        }
        else { Assert-Verification ([IO.File]::ReadAllText((Join-Path $target 'Documents/a.pdf')) -ceq 'single payload') 'Worker failure lost file content.' }
    }
    elseif ($Scenario -in @('Undo','UndoRetry','UndoConflict')) {
        if ($Scenario -eq 'UndoConflict') {
            Assert-Verification ([IO.File]::ReadAllText((Join-Path $target 'a.pdf')) -ceq 'source conflict') 'Undo overwrote source conflict.'
            Assert-Verification ($console.Contains('Undo conflict at source:')) 'Undo conflict was not presented.'
            Assert-Verification ([IO.File]::ReadAllText((Join-Path $target 'Documents/a.pdf')) -ceq 'new a') 'Undo lost destination content.'
            $backups = @(Get-ChildItem -LiteralPath (Join-Path $ops 'transactions/backups') -Recurse -File)
            Assert-Verification ($backups.Count -eq 1 -and [IO.File]::ReadAllText($backups[0].FullName) -ceq 'old a') 'Overwrite backup was lost.'
        }
        else { Assert-Inventory $initial $actual; Assert-Verification (@(Get-ChildItem -LiteralPath (Join-Path $ops 'transactions') -Filter '*.undone').Count -eq 1) 'Undo did not complete.' }
    }
    elseif ($Scenario -eq 'Watcher') {
        Assert-Verification ([IO.File]::ReadAllText((Join-Path $SessionPath 'default decoy/untouched.pdf')) -ceq 'decoy') 'Watcher changed the configuration default folder.'
        Assert-Verification ([IO.File]::ReadAllText((Join-Path $target 'Documents/created.pdf')) -ceq 'created payload') 'Created event failed.'
        Assert-Verification ([IO.File]::ReadAllText((Join-Path $target 'Applications/setup.exe')) -ceq 'rename payload') 'Renamed event failed.'
        foreach ($i in 1..20) { Assert-Verification ([IO.File]::ReadAllText((Join-Path $target "Documents/burst-$i.txt")) -ceq "burst $i") 'Burst lost content.' }
        Assert-Verification ([IO.File]::ReadAllText((Join-Path $target 'ignored.tmp')) -ceq 'ignored payload') 'Ignore pattern failed.'
    }
    else {
        Assert-Verification ($runs.Count -gt 0) 'No JSON execution report: required action was not completed.'
        $run = $runs[-1]
        Assert-Verification ($run.Summary.TotalFiles -eq @($run.Results).Count) 'Report does not account for all results.'
        foreach ($report in $reports) {
            $csv = @((Import-Csv -LiteralPath ([IO.Path]::ChangeExtension($report.FullName, '.csv'))))
            $data = Get-Content -LiteralPath $report.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            Assert-Verification ($csv.Count -eq $data.Summary.TotalFiles) 'CSV count differs from JSON.'
            $html = Get-Content -LiteralPath ([IO.Path]::ChangeExtension($report.FullName, '.html')) -Raw -Encoding UTF8
            Assert-Verification ([regex]::Matches($html, "<td class='status-").Count -eq (8 * $data.Summary.TotalFiles)) 'HTML row count differs from JSON.'
        }
        if ($Scenario -eq 'DryRun') {
            Assert-Inventory $initial $actual
            Assert-Verification (@(Get-ChildItem -LiteralPath $target -Directory).Count -eq 0) 'DryRun created category folders.'
            Assert-Verification (-not (Test-Path -LiteralPath (Join-Path $ops 'transactions'))) 'DryRun created transactions or backups.'
            Assert-Verification ($run.Summary.Planned -eq $initial.Count) 'DryRun did not report Planned for every input.'
            # Execute an equivalent fixture in a separate reference folder, then compare literal relative destinations.
            $reference = Join-Path $SessionPath 'reference'
            [IO.Directory]::CreateDirectory($reference) | Out-Null
            Get-ChildItem -LiteralPath $target -File | Copy-Item -Destination $reference
            Import-Module (Join-Path $runtime 'DownloadOrganizerPro.psd1')
            $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $config.Settings.DownloadsPath = $reference; $config.Settings.DryRun = $false
            $real = Invoke-Organizer $config -OperationalPath (Join-Path $SessionPath 'reference-logs')
            $planned = @($run.Results | ForEach-Object { $_.Destination.Substring($target.Length) } | Sort-Object)
            $moved = @($real.Results | ForEach-Object { $_.Destination.Substring($reference.Length) } | Sort-Object)
            Assert-Verification (($planned -join '|') -ceq ($moved -join '|')) 'DryRun destinations differ from execution.'
        }
        elseif ($Scenario -in @('Scale','CloseDuringWork')) {
            if ($Scenario -eq 'CloseDuringWork') { Assert-Verification ($console.Contains('Waiting for the active transaction before closing...')) 'Close was not requested while the worker was active.' }
            Assert-Verification ($runs[0].Summary.Moved -eq 10000 -and $actual.Count -eq 10000) 'Scale run did not move every input.'
            $expectedHashes = @($initial.SHA256 | Sort-Object)
            $actualHashes = @($actual.SHA256 | Sort-Object)
            Assert-Verification (($expectedHashes -join '|') -ceq ($actualHashes -join '|')) 'Scale run changed file content.'
            $beforeSecond = $actual
            Import-Module (Join-Path $runtime 'DownloadOrganizerPro.psd1')
            $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $second = Invoke-Organizer $config -OperationalPath $ops
            Assert-Verification ($second.Summary.TotalFiles -eq 10000 -and $second.Summary.Moved -eq 0) 'Second run changed organized names.'
            Assert-Inventory $beforeSecond @(Get-Inventory $target)
            if (-not $VerifyOnly -and $Scenario -eq 'Scale') { Assert-Verification ($capture.Window.FindName('GridResults').Items.Count -eq 500) 'GUI must show exactly 500 of 10000 results.' }
        }
        elseif ($Scenario -eq 'Empty') { Assert-Verification ($run.Summary.TotalFiles -eq 0 -and $actual.Count -eq 0) 'Empty run is not empty.' }
        else {
            $retained = @($actual) + @(Get-Inventory (Join-Path $ops 'transactions/backups'))
            $expectedHashes = @($initial.SHA256 | Sort-Object)
            $actualHashes = @($retained.SHA256 | Sort-Object)
            Assert-Verification (($expectedHashes -join '|') -ceq ($actualHashes -join '|')) 'Organize lost or duplicated file content.'
            if ($Scenario -in @('Mixed','SmartOff','UnknownOff','Single')) {
                foreach ($item in $initial) {
                    $category = switch ([IO.Path]::GetExtension($item.Path)) { '.pdf' { 'Documents' }; '.txt' { 'Documents' }; '.png' { 'Images' }; '.exe' { 'Applications' }; default { 'Others' } }
                    $relative = Join-Path $category $item.Path
                    if ($item.Path -eq 'resume [1].pdf' -and $Scenario -ne 'SmartOff') { $relative = 'Documents/CV/resume [1].pdf' }
                    if ($item.Path -eq 'invoice 2026.pdf' -and $Scenario -ne 'SmartOff') { $relative = 'Documents/Finance/invoice 2026.pdf' }
                    if ($category -eq 'Others' -and $Scenario -eq 'UnknownOff') { $relative = $item.Path }
                    Assert-Verification ((Get-FileHash -LiteralPath (Join-Path $target $relative) -Algorithm SHA256).Hash -ceq $item.SHA256) "Wrong destination/content: $relative"
                }
                if ($Scenario -ne 'Single') { Assert-Verification ($run.Summary.Duplicates -eq 1) 'Duplicate flag count is wrong.' }
            }
            if ($Scenario -in @('Rename','Skip','Overwrite')) {
                $destinationContent = [IO.File]::ReadAllText((Join-Path $target 'Documents/a.pdf'))
                Assert-Verification ($destinationContent -ceq $(if ($Scenario -eq 'Overwrite') { 'new a' } else { 'old a' })) 'Conflict policy changed the wrong file.'
                if ($Scenario -eq 'Rename') { Assert-Verification ([IO.File]::ReadAllText((Join-Path $target 'Documents/a (1).pdf')) -ceq 'new a') 'Rename did not preserve both files.' }
                if ($Scenario -eq 'Skip') { Assert-Verification ([IO.File]::ReadAllText((Join-Path $target 'a.pdf')) -ceq 'new a') 'Skip moved conflicting source.' }
            }
        }
        if ($Scenario -eq 'Scheduler') {
            Assert-Verification (Test-Path -LiteralPath (Join-Path $evidence 'scheduled-task.json')) 'Scheduler task was not observed.'
            Assert-Verification (-not (Get-ScheduledTask -TaskName $session.TaskName -ErrorAction SilentlyContinue)) 'Schedule button did not remove its task.'
            Assert-Verification (-not $capture.SchedulerError) $capture.SchedulerError
        }
        Import-Module (Join-Path $runtime 'DownloadOrganizerPro.psd1')
        $stats = Get-OrganizerStatistics $ops
        Assert-Verification ($stats.TotalExecutions -ge $runs.Count) 'Statistics missed executions.'
        Write-Json $stats (Join-Path $evidence 'statistics.json')
        if (-not $VerifyOnly -and $capture.Window -and $Scenario -notin @('Scheduler')) {
            Assert-Verification ([int]$capture.Window.FindName('TxtKpiScanned').Text -eq $run.Summary.TotalFiles) 'GUI scanned KPI differs from report.'
            Assert-Verification ([int]$capture.Window.FindName('TxtKpiMoved').Text -eq $run.Summary.Moved) 'GUI moved KPI differs from report.'
            Assert-Verification ([int]$capture.Window.FindName('TxtKpiFailed').Text -eq $run.Summary.Failed) 'GUI failed KPI differs from report.'
        }
    }
    $filesystemStatus = 'lulus'
}
catch { $errorText = $_.Exception.Message }
finally {
    if ($timer) { $timer.Stop() }
    if ($lockHandle) { $lockHandle.Dispose() }
    try {
        if ($Scenario -eq 'Scheduler' -or ($capture.Window -and $capture.Window.FindName('TxtLogConsole').Text.Contains('[SCHEDULE] Registered'))) {
            $task = Get-ScheduledTask -TaskName $session.TaskName -ErrorAction SilentlyContinue
            if ($task) {
                # Allow a worker to finish its journal; never terminate an active transaction.
                $deadline = (Get-Date).AddSeconds(60)
                while ($task.State -eq 'Running' -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 250; $task = Get-ScheduledTask -TaskName $session.TaskName }
                Assert-Verification ($task.State -ne 'Running') 'Session task is still running; retained for recovery.'
                Unregister-ScheduledTask -TaskName $session.TaskName -Confirm:$false -ErrorAction Stop
            }
        }
    }
    catch { $filesystemStatus = 'gagal'; $errorText += " Cleanup: $($_.Exception.Message)" }
    $status = if ($filesystemStatus -eq 'gagal' -or $VisualStatus -eq 'gagal') { 'gagal' } elseif ($VisualStatus -eq 'lulus') { 'lulus' } else { $VisualStatus }
    Write-Json ([ordered]@{ Scenario = $Scenario; Date = (Get-Date -Format o); Status = $status; Filesystem = $filesystemStatus; Visual = $VisualStatus; Notes = $Notes; Error = $errorText; Session = $SessionPath }) (Join-Path $evidence 'result.json')
    Write-Host "Evidence: $evidence; filesystem: $filesystemStatus; visual: $VisualStatus"
}
if ($errorText) { throw $errorText }
