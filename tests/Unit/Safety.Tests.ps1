BeforeAll {
    $ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Import-Module "$ProjectRoot/DownloadOrganizerPro.psd1"
    Import-Module "$ProjectRoot/modules/Transactions.psm1"
    . "$ProjectRoot/tests/TestHelpers.ps1"
    function New-SafetyFile {
        param([string]$Path, [string]$Content = 'payload', [string]$Category = 'Documents')
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path)) | Out-Null
        [IO.File]::WriteAllText($Path, $Content)
        $file = New-OrganizerFile (Get-Item -LiteralPath $Path)
        $file.SetCategory($Category)
        $file
    }
}
Describe 'File safety and recovery' {
    BeforeEach {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($root) | Out-Null
        $transactions = Join-Path $root '.organizer/transactions'
    }
    It 'moves bracket names literally and skips a second run' {
        $file = New-SafetyFile "$root/[1].pdf"
        $first = @(Move-OrganizerFiles @($file) $root)
        $first[0].Status | Should -Be Moved
        $again = New-OrganizerFile (Get-Item -LiteralPath $first[0].Destination)
        $again.SetCategory('Documents')
        $second = @(Move-OrganizerFiles @($again) $root)
        $second[0].Status | Should -Be Skipped
        [IO.File]::ReadAllText($first[0].Destination) | Should -Be payload
    }
    It 'preserves Unicode paths in UTF-8 transaction manifests' {
        $name = 'caf' + [char]0x00e9 + ' [1].pdf'
        $path = Join-Path $root $name
        $file = New-SafetyFile $path
        @(Move-OrganizerFiles @($file) $root)[0].Status | Should -Be Moved
        (Invoke-UndoOperation (Get-UndoLog $transactions)[0].FullName).FailedCount | Should -Be 0
        [IO.File]::ReadAllText($path) | Should -Be payload
    }
    It 'preserves both contents through overwrite and undo' {
        $source = New-SafetyFile "$root/a.pdf" 'new'
        $null = New-SafetyFile "$root/Documents/a.pdf" 'old'
        $result = @(Move-OrganizerFiles @($source) $root -ConflictAction Overwrite)
        $result[0].Status | Should -Be Moved
        [IO.File]::ReadAllText("$root/Documents/a.pdf") | Should -Be new
        $log = (Get-UndoLog $transactions)[0].FullName
        $undo = Invoke-UndoOperation $log
        $undo.FailedCount | Should -Be 0
        [IO.File]::ReadAllText("$root/a.pdf") | Should -Be new
        [IO.File]::ReadAllText("$root/Documents/a.pdf") | Should -Be old
        (Get-UndoLog $transactions).Count | Should -Be 0
        Test-Path -LiteralPath ($log + '.undone') | Should -BeTrue
    }
    It 'undoes repeated overwrites in reverse order' {
        $one = New-SafetyFile "$root/one/a.pdf" 'one'
        $two = New-SafetyFile "$root/two/a.pdf" 'two'
        $null = New-SafetyFile "$root/Documents/a.pdf" 'old'
        $results = @(Move-OrganizerFiles @($one, $two) $root -ConflictAction Overwrite)
        @($results | Where-Object Status -eq Moved).Count | Should -Be 2
        (Invoke-UndoOperation (Get-UndoLog $transactions)[0].FullName).FailedCount | Should -Be 0
        [IO.File]::ReadAllText("$root/one/a.pdf") | Should -Be one
        [IO.File]::ReadAllText("$root/two/a.pdf") | Should -Be two
        [IO.File]::ReadAllText("$root/Documents/a.pdf") | Should -Be old
    }
    It 'keeps partial undo retryable without replacing an occupied source' {
        $one = New-SafetyFile "$root/one.pdf" 'one'
        $two = New-SafetyFile "$root/two.pdf" 'two'
        $null = Move-OrganizerFiles @($one, $two) $root
        [IO.File]::WriteAllText("$root/one.pdf", 'unrelated')
        $log = (Get-UndoLog $transactions)[0].FullName
        $first = Invoke-UndoOperation $log
        $first.RestoredCount | Should -Be 1
        $first.FailedCount | Should -Be 1
        [IO.File]::ReadAllText("$root/one.pdf") | Should -Be unrelated
        [IO.File]::Delete("$root/one.pdf")
        $retry = Invoke-UndoOperation $log
        $retry.RestoredCount | Should -Be 1
        $retry.FailedCount | Should -Be 0
        [IO.File]::ReadAllText("$root/two.pdf") | Should -Be two
    }
    It 'recovers a crash after source move but before progress append' {
        $file = New-SafetyFile "$root/a.pdf"
        $null = Move-OrganizerFiles @($file) $root
        $log = (Get-UndoLog $transactions)[0].FullName
        [IO.File]::WriteAllText($log + '.progress', '')
        (Invoke-UndoOperation $log).FailedCount | Should -Be 0
        [IO.File]::ReadAllText("$root/a.pdf") | Should -Be payload
    }
    It 'refuses changed destination content during undo' {
        $file = New-SafetyFile "$root/a.pdf"
        $result = @(Move-OrganizerFiles @($file) $root)
        [IO.File]::WriteAllText($result[0].Destination, 'edited')
        (Invoke-UndoOperation (Get-UndoLog $transactions)[0].FullName).FailedCount | Should -Be 1
        [IO.File]::ReadAllText($result[0].Destination) | Should -Be edited
    }
    It 'does not mutate files when manifest creation fails' {
        $file = New-SafetyFile "$root/a.pdf"
        $blocker = "$root/not-a-directory"
        [IO.File]::WriteAllText($blocker, 'block')
        { Move-OrganizerFiles @($file) $root -TransactionPath $blocker } | Should -Throw
        [IO.File]::ReadAllText("$root/a.pdf") | Should -Be payload
        Test-Path -LiteralPath "$root/Documents" | Should -BeFalse
    }
    It 'does not replace a destination when creating its backup fails' {
        $file = New-SafetyFile "$root/a.pdf" 'new'
        $null = New-SafetyFile "$root/Documents/a.pdf" 'old'
        [IO.Directory]::CreateDirectory($transactions) | Out-Null
        [IO.File]::WriteAllText((Join-Path $transactions 'backups'), 'block')
        $result = @(Move-OrganizerFiles @($file) $root -ConflictAction Overwrite)
        $result[0].Status | Should -Be Failed
        [IO.File]::ReadAllText("$root/a.pdf") | Should -Be new
        [IO.File]::ReadAllText("$root/Documents/a.pdf") | Should -Be old
    }
    It 'stops before replacing an overwrite when progress cannot be persisted' {
        $file = New-SafetyFile "$root/a.pdf" 'new'
        $null = New-SafetyFile "$root/Documents/a.pdf" 'old'
        Mock Write-TransactionProgress { throw 'journal unavailable' } -ModuleName Mover
        { Move-OrganizerFiles @($file) $root -ConflictAction Overwrite } | Should -Throw '*journal unavailable*'
        [IO.File]::ReadAllText("$root/a.pdf") | Should -Be new
        $backup = @(Get-ChildItem -LiteralPath "$transactions/backups" -File -Recurse)[0]
        [IO.File]::ReadAllText($backup.FullName) | Should -Be old
        (Invoke-UndoOperation (Get-UndoLog $transactions)[0].FullName).FailedCount | Should -Be 0
        [IO.File]::ReadAllText("$root/Documents/a.pdf") | Should -Be old
    }
    It 'recovers and repairs a torn last progress record' {
        $file = New-SafetyFile "$root/a.pdf"
        $null = Move-OrganizerFiles @($file) $root
        $log = (Get-UndoLog $transactions)[0].FullName
        [IO.File]::AppendAllText($log + '.progress', '{"Id":')
        (Invoke-UndoOperation $log).FailedCount | Should -Be 0
        [IO.File]::ReadAllText("$root/a.pdf") | Should -Be payload
    }
    It 'restores an overwrite backup if the source move fails' {
        $file = New-SafetyFile "$root/a.pdf" 'new'
        $null = New-SafetyFile "$root/Documents/a.pdf" 'old'
        Mock Write-TransactionProgress {
            param($Path, $Entry, $State)
            if ($State -eq 'BackupReady') { [IO.File]::WriteAllText($Entry.SourcePath, 'changed') }
        } -ModuleName Mover
        $result = @(Move-OrganizerFiles @($file) $root -ConflictAction Overwrite)
        $result[0].Status | Should -Be Failed
        # The changed source must be preserved and the incomplete transaction retained.
        (Invoke-UndoOperation (Get-UndoLog $transactions)[0].FullName).FailedCount | Should -Be 1
        [IO.File]::ReadAllText("$root/a.pdf") | Should -Be changed
        @(Get-ChildItem -LiteralPath "$transactions/backups" -Recurse -File).Count | Should -Be 1
    }
    It 'reads legacy manifests and archives each undo once' {
        $destination = New-SafetyFile "$root/Documents/old.pdf"
        [IO.Directory]::CreateDirectory($transactions) | Out-Null
        $log = Join-Path $transactions 'transaction-legacy.json'
        @{ Moves = @(@{ SourcePath = "$root/old.pdf"; DestinationPath = $destination.FullPath }) } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $log
        (Invoke-UndoOperation $log).RestoredCount | Should -Be 1
        { Invoke-UndoOperation $log } | Should -Throw
    }
    It 'rejects invalid directory components' -ForEach @('..\outside', '../outside', 'C:\outside', 'a/b', 'CON', 'nul.txt', 'LPT1', 'trailing.', 'trailing ', 'bad:name', '.', '..', '') {
        { Assert-DirectoryComponent $_ } | Should -Throw
    }
    It 'rejects traversal even when mover is called directly' {
        $file = New-SafetyFile "$root/a.pdf" 'payload' '..\outside'
        $result = @(Move-OrganizerFiles @($file) $root)
        $result[0].Status | Should -Be Failed
        Test-Path -LiteralPath "$root/a.pdf" | Should -BeTrue
    }
    It 'plans conflicts identically without category folders or transactions' {
        $one = New-SafetyFile "$root/one/a.pdf" 'one'
        $two = New-SafetyFile "$root/two/a.pdf" 'two'
        $plan = @(Move-OrganizerFiles @($one, $two) $root -DryRun)
        $plan[0].Status | Should -Be Planned
        $one.Status.ToString() | Should -Be Planned
        $plan[1].Destination | Should -BeLike '*a (1).pdf'
        Test-Path -LiteralPath "$root/Documents" | Should -BeFalse
        Test-Path -LiteralPath $transactions | Should -BeFalse
        $actual = @(Move-OrganizerFiles @($one, $two) $root)
        $actual.Destination | Should -Be $plan.Destination
    }
    It 'skips conflicts and disabled unknown files and folder creation' {
        $file = New-SafetyFile "$root/a.pdf"
        $null = New-SafetyFile "$root/Documents/a.pdf" 'old'
        @(Move-OrganizerFiles @($file) $root -ConflictAction Skip)[0].Status | Should -Be Skipped
        $file.SetCategory('Others')
        @(Move-OrganizerFiles @($file) $root -MoveUnknownFiles $false)[0].Status | Should -Be Skipped
        $file.SetCategory('Images')
        @(Move-OrganizerFiles @($file) $root -CreateCategoryFolders $false)[0].Status | Should -Be Skipped
    }
}
