BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1"
Import-Module "$ProjectRoot\modules\Utils.psm1"
Import-Module "$ProjectRoot\modules\Mover.psm1"
Import-Module "$ProjectRoot\modules\Undo.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "Undo Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ($TestDrive) ("UndoTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            $resolved = [IO.Path]::GetFullPath($tempDir)
            if (-not $resolved.StartsWith([IO.Path]::GetFullPath($TestDrive).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test cleanup escaped TestDrive.' }
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }

    It "Should record transaction log during move and restore files via Invoke-UndoOperation" {
        $sourceFile = Join-Path $tempDir "sample.pdf"
        "test payload" | Set-Content -Path $sourceFile

        $orgFile = New-OrganizerFile -File (Get-Item $sourceFile)
        $orgFile.SetCategory("Documents")

        $logsDir = Join-Path $tempDir "logs"
        $results = Move-OrganizerFiles -Files @($orgFile) -BasePath $tempDir -TransactionPath $logsDir

        $logs = Get-UndoLog -LogPath $logsDir
        @($logs).Count | Should -Be 1

        # File moved away from root
        Test-Path $sourceFile | Should -Be $false

        # Execute Undo
        $undoRes = Invoke-UndoOperation -TransactionFile $logs[0].FullName
        $undoRes.RestoredCount | Should -Be 1
        Test-Path $sourceFile | Should -Be $true
    }
}
