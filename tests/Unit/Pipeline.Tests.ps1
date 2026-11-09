BeforeAll {
    $ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$ProjectRoot/DownloadOrganizerPro.psd1"
    . "$ProjectRoot/tests/TestHelpers.ps1"
}
Describe 'Shared organizer pipeline' {
    BeforeEach {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($root) | Out-Null
        $config = New-TestConfig $root
        $ops = Join-Path $root '.organizer'
    }
    It 'runs empty and singleton scans with complete status accounting' {
        $empty = Invoke-Organizer $config -OperationalPath $ops
        $empty.Files.Count | Should -Be 0
        [IO.File]::WriteAllText("$root/a.pdf", 'content')
        $one = Invoke-Organizer $config -OperationalPath $ops
        $one.Summary.TotalFiles | Should -Be 1
        $one.Summary.Moved | Should -Be 1
        $one.Summary.Duration.TotalSeconds | Should -BeGreaterThan 0
        $config.Settings.Recursive = $true
        $again = Invoke-Organizer $config -OperationalPath $ops
        $again.Summary.Skipped | Should -Be 1
        $again.Results.Count | Should -Be 1
        $stats = Get-OrganizerStatistics $ops
        $stats.TotalExecutions | Should -Be 3
        $stats.TotalMoved | Should -Be 1
    }
    It 'uses Planned consistently and leaves no safety or category artifacts in DryRun' {
        [IO.File]::WriteAllText("$root/a.pdf", 'same')
        [IO.File]::WriteAllText("$root/b.pdf", 'same')
        $config.Settings.DryRun = $true
        $config.Settings.CreateLogs = $false
        $run = Invoke-Organizer $config -OperationalPath $ops
        $run.Summary.Planned | Should -Be 2
        $run.Summary.Failed | Should -Be 0
        $run.Summary.Duplicates | Should -Be 1
        Test-Path -LiteralPath $ops | Should -BeFalse
        Test-Path -LiteralPath "$root/Documents" | Should -BeFalse
        $run.Summary.TotalFiles | Should -Be ($run.Summary.Moved + $run.Summary.Failed + $run.Summary.Skipped + $run.Summary.Planned)
    }
    It 'writes requested reports independently from operational logging' {
        [IO.File]::WriteAllText("$root/a.pdf", '')
        $config.Settings.CreateLogs = $false
        $config.Settings.ExportHTML = $true
        $config.Settings.ExportCSV = $true
        $config.Settings.ExportJSON = $true
        $run = Invoke-Organizer $config -OperationalPath $ops
        $run.Reports.Count | Should -Be 3
        @(Get-ChildItem -LiteralPath $ops -Filter '*.log').Count | Should -Be 0
        (Get-UndoLog "$ops/transactions").Count | Should -Be 1
        foreach ($path in $run.Reports.Values) { Test-Path -LiteralPath $path | Should -BeTrue }
    }
    It 'honors legacy overwrite and explicit conflict precedence' {
        [IO.File]::WriteAllText("$root/a.pdf", 'new')
        [IO.Directory]::CreateDirectory("$root/Documents") | Out-Null
        [IO.File]::WriteAllText("$root/Documents/a.pdf", 'old')
        $config.Settings.Overwrite = $true
        $config.Settings | Add-Member ConflictAction Skip
        (Invoke-Organizer $config -OperationalPath $ops).Summary.Skipped | Should -Be 1
        (Invoke-Organizer $config -OperationalPath $ops -ConflictAction Overwrite).Summary.Moved | Should -Be 1
        [IO.File]::ReadAllText("$root/Documents/a.pdf") | Should -Be new
        (Invoke-UndoOperation (Get-UndoLog "$ops/transactions")[0].FullName).FailedCount | Should -Be 0
        $config.Settings.PSObject.Properties.Remove('ConflictAction')
        (Invoke-Organizer $config -OperationalPath $ops).Summary.Moved | Should -Be 1
        [IO.File]::ReadAllText("$root/Documents/a.pdf") | Should -Be new
    }
    It 'disables duplicate detection when configured' {
        [IO.File]::WriteAllText("$root/a.pdf", '')
        [IO.File]::WriteAllText("$root/b.pdf", '')
        $config.Settings.EnableDuplicateDetection = $false
        (Invoke-Organizer $config -OperationalPath $ops).Summary.Duplicates | Should -Be 0
    }
    It 'gives explicit Verbose parameters precedence over configuration' {
        [IO.File]::WriteAllText("$root/a.pdf", '')
        $config.Settings.DryRun = $true
        $config.Settings.CreateLogs = $false
        $config.Settings.Verbose = $true
        $configured = @(Invoke-Organizer $config -OperationalPath $ops 4>&1)
        @($configured | Where-Object { $_ -is [Management.Automation.VerboseRecord] }).Count | Should -BeGreaterThan 0
        $quiet = @(Invoke-Organizer $config -OperationalPath $ops -Verbose:$false 4>&1)
        @($quiet | Where-Object { $_ -is [Management.Automation.VerboseRecord] }).Count | Should -Be 0
        $config.Settings.Verbose = $false
        $explicit = @(Invoke-Organizer $config -OperationalPath $ops -Verbose 4>&1)
        @($explicit | Where-Object { $_ -is [Management.Automation.VerboseRecord] }).Count | Should -BeGreaterThan 0
    }
    It 'detects empty duplicates but does not merge equal size different content' {
        foreach ($pair in @(@('a.pdf', ''), @('b.pdf', ''), @('c.pdf', 'one'), @('d.pdf', 'two'))) { [IO.File]::WriteAllText((Join-Path $root $pair[0]), $pair[1]) }
        $run = Invoke-Organizer $config -OperationalPath $ops
        $run.Summary.Duplicates | Should -Be 1
        @($run.Results | Where-Object IsDuplicate).Count | Should -Be 1
        $run.Summary.Moved | Should -Be 4
    }
    It 'does not interpret hashing failures as duplicate evidence' {
        [IO.File]::WriteAllText("$root/a.pdf", '')
        [IO.File]::WriteAllText("$root/b.pdf", '')
        Mock Get-FileSHA256 { throw 'hash unavailable' } -ModuleName DuplicateDetector
        $files = @(Get-DownloadFiles $root)
        @(Get-DuplicateFiles $files -WarningAction SilentlyContinue).Count | Should -Be 0
        @($files | Where-Object IsDuplicate).Count | Should -Be 0
    }
    It 'restricts smart rules to extension category and ignores extension keywords' {
        foreach ($name in @('project_banner.png', 'resume_builder_setup.exe', 'invoice.pdf', 'banking.pdf')) { [IO.File]::WriteAllText((Join-Path $root $name), '') }
        $config.Settings.DryRun = $true
        $run = Invoke-Organizer $config -OperationalPath $ops
        ($run.Files | Where-Object Name -eq project_banner.png).DestinationPath | Should -Be Images
        ($run.Files | Where-Object Name -eq resume_builder_setup.exe).DestinationPath | Should -Be Applications
        ($run.Files | Where-Object Name -eq invoice.pdf).SubCategory | Should -Be Finance
        ($run.Files | Where-Object Name -eq banking.pdf).SubCategory | Should -Be ''
        (Get-SmartCategory -FileName 'ordinary.pdf' -SmartRules ([pscustomobject]@{ Documents = [pscustomobject]@{ PDF = [pscustomobject]@{ Priority = 1; Keywords = @('pdf') } } })).Score | Should -BeNullOrEmpty
    }
    It 'matches phrases across separators and breaks equal scores by declaration order' {
        $rules = [pscustomobject]@{ Documents = [pscustomobject][ordered]@{
            First = [pscustomobject]@{ Keywords = @('annual report'); Priority = 4 }
            Second = [pscustomobject]@{ Keywords = @('annual', 'report'); Priority = 2 }
        } }
        (Get-SmartCategory 'annual_report-2026.pdf' $rules -Category Documents).SubCategory | Should -Be First
        Get-SmartCategory 'biannual_report.pdf' $rules -Category Documents | Should -Not -BeNullOrEmpty
        Get-SmartCategory 'ordinary.pdf' $rules -Category Documents | Should -BeNullOrEmpty
    }
    It 'supports classifier pipeline and explicit array inputs' {
        [IO.File]::WriteAllText("$root/a.pdf", '')
        [IO.File]::WriteAllText("$root/b.png", '')
        $files = @(Get-DownloadFiles $root | Set-FileCategory -Categories $config.Categories)
        $files.Count | Should -Be 2
        $files.Category | Should -Contain Documents
        $files.Category | Should -Contain Images
    }
    It 'applies unknown folder and smart settings in the shared pipeline' {
        [IO.File]::WriteAllText("$root/file.unknown", '')
        [IO.File]::WriteAllText("$root/resume.pdf", '')
        $config.Settings.MoveUnknownFiles = $false
        $config.Settings.CreateCategoryFolders = $false
        $config.Settings.EnableSmartRules = $false
        $run = Invoke-Organizer $config -OperationalPath $ops
        $run.Summary.Skipped | Should -Be 2
        [IO.Directory]::CreateDirectory("$root/Documents") | Out-Null
        $run = Invoke-Organizer $config -OperationalPath $ops
        $run.Summary.Moved | Should -Be 1
        Test-Path -LiteralPath "$root/Documents/resume.pdf" | Should -BeTrue
        $config.Settings.MoveUnknownFiles = $true
        $config.Settings.CreateCategoryFolders = $true
        (Invoke-Organizer $config -OperationalPath $ops).Summary.Moved | Should -Be 1
        Test-Path -LiteralPath "$root/Others/file.unknown" | Should -BeTrue
    }
    It 'encodes dynamic HTML and counts starts within a daily log' {
        $summary = New-OrganizerSummary
        $summary.Categories['<script>alert(1)</script>'] = 1
        $result = [pscustomobject]@{ File = '<script>'; Category = '<b>'; SubCategory = '&'; Status = '<img>'; Destination = '"'; IsDuplicate = $false; SHA256Hash = ''; Reason = '<unsafe>' }
        $path = Export-OrganizerHTMLReport $summary @($result) "$root/report.html"
        $html = Get-Content -LiteralPath $path -Raw
        $html | Should -Not -Match '<script>|<img>|<unsafe>'
        $html | Should -Match '&lt;script&gt;'
        $log = Initialize-Logger $ops
        Write-OrganizerLog $log 'Organizer Started'
        Write-OrganizerLog $log 'Organizer Started'
        Write-MoveLog $log @([pscustomobject]@{ File = 'a'; Status = 'Planned'; Destination = 'b' })
        $stats = Get-OrganizerStatistics $ops
        $stats.TotalExecutions | Should -Be 2
        $stats.TotalFailed | Should -Be 0
    }
    It 'filters age size and patterns and excludes operational directories while recursing' {
        [IO.Directory]::CreateDirectory("$root/sub") | Out-Null
        [IO.Directory]::CreateDirectory($ops) | Out-Null
        [IO.File]::WriteAllText("$root/sub/yes.pdf", 'yes')
        [IO.File]::WriteAllText("$root/sub/no.tmp", 'yes')
        [IO.File]::WriteAllText("$ops/log.pdf", 'yes')
        (Get-Item -LiteralPath "$root/sub/yes.pdf").LastWriteTime = (Get-Date).AddDays(-5)
        $files = @(Get-DownloadFiles $root -Recurse -IgnorePatterns @('*.tmp') -MinAgeDays 1 -MaxAgeDays 10 -MinSizeBytes 2 -MaxSizeBytes 5 -ExcludePaths @($ops))
        $files.Count | Should -Be 1
        $files[0].Name | Should -Be yes.pdf
        @(Get-DownloadFiles $root -Recurse -MinSizeBytes 100).Count | Should -Be 0
        @(Get-DownloadFiles $root -Recurse -MaxSizeBytes 1).Count | Should -Be 0
        @(Get-DownloadFiles "$root/sub" -MaxAgeDays 1 -IgnorePatterns @('*.tmp')).Count | Should -Be 0
    }
}
