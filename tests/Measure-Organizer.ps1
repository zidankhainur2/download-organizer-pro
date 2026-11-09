[CmdletBinding()]
param(
    [ValidateSet('Before', 'After')][string]$Implementation = 'After',
    [ValidateRange(1, 100000)][int]$Count = 10000,
    [string]$BaselineModulePath = '',
    [string]$OutputPath = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not $OutputPath) { $OutputPath = Join-Path $projectRoot "docs/benchmarks/$Implementation.json" }
$parent = [IO.Path]::GetFullPath((Join-Path $projectRoot '.tools/benchmark-data'))
$root = Join-Path $parent ([guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root) | Out-Null
try {
    for ($i = 0; $i -lt $Count; $i++) {
        $group = [int][math]::Floor($i / 1000)
        $folder = Join-Path $root "batch-$group"
        [IO.Directory]::CreateDirectory($folder) | Out-Null
        [IO.File]::WriteAllText((Join-Path $folder "invoice_$($i % 1000).pdf"), "payload $i")
    }
    $config = Get-Content -LiteralPath "$projectRoot/config.json" -Raw | ConvertFrom-Json
    $config.Settings.DownloadsPath = $root
    $config.Settings.Recursive = $true
    $config.Settings.CreateLogs = $false
    if ($Implementation -eq 'Before') {
        if (-not $BaselineModulePath) { throw 'Provide the original modules directory for Before.' }
        $BaselineModulePath = [IO.Path]::GetFullPath($BaselineModulePath)
        foreach ($name in @('Models', 'Utils', 'Scanner', 'Classifier', 'SmartClassifier', 'Mover')) { Import-Module (Join-Path $BaselineModulePath "$name.psm1") }
    }
    else { Import-Module "$projectRoot/DownloadOrganizerPro.psd1" }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    if ($Implementation -eq 'Before') {
        $files = @(Get-DownloadFiles $root -Recurse)
        $files = @(Set-FileCategory -Files $files -Categories $config.Categories)
        $files = @(Invoke-SmartClassification -Files $files -SmartRules $config.SmartRules)
        $results = @(Move-OrganizerFiles $files $root)
    }
    else {
        $run = Invoke-Organizer $config -OperationalPath (Join-Path $root '.organizer')
        $results = $run.Results
    }
    $watch.Stop()
    if ($results.Count -ne $Count -or @($results | Where-Object Status -ne Moved).Count -gt 0) { throw 'Benchmark did not account for every input as Moved.' }
    $seconds = $watch.Elapsed.TotalSeconds
    $watch.Restart()
    if ($Implementation -eq 'Before') {
        $files = @(Get-DownloadFiles $root -Recurse)
        $files = @(Set-FileCategory -Files $files -Categories $config.Categories)
        $files = @(Invoke-SmartClassification -Files $files -SmartRules $config.SmartRules)
        $second = @(Move-OrganizerFiles $files $root)
    }
    else { $second = (Invoke-Organizer $config -OperationalPath (Join-Path $root '.organizer')).Results }
    $watch.Stop()
    $renamedAgain = @($second | Where-Object Status -eq Moved).Count
    if ($Implementation -eq 'After' -and ($second.Count -ne $Count -or $renamedAgain -ne 0)) { throw 'The second run changed organized files or lost results.' }
    $record = [ordered]@{
        Implementation = $Implementation; Date = (Get-Date -Format o); Machine = $env:COMPUTERNAME
        PowerShell = $PSVersionTable.PSVersion.ToString(); Count = $Count; FirstRunSeconds = $seconds
        SecondRunSeconds = $watch.Elapsed.TotalSeconds; SecondRunMoved = $renamedAgain
        PeakWorkingSetMB = [math]::Round([Diagnostics.Process]::GetCurrentProcess().PeakWorkingSet64 / 1MB, 2)
        Notes = '1000 repeated invoice names across batches; Before has no safety journal or duplicate integration. After includes both.'
    }
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($OutputPath))) | Out-Null
    $record | ConvertTo-Json | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    $record
}
finally {
    $resolved = [IO.Path]::GetFullPath($root)
    if (-not $resolved.StartsWith($parent.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Benchmark cleanup escaped its workspace.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
