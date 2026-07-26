$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Models.psm1" -Force
Import-Module "$ProjectRoot\modules\Utils.psm1" -Force
Import-Module "$ProjectRoot\modules\Mover.psm1" -Force
Import-Module "$ProjectRoot\modules\Undo.psm1" -Force

Describe "Undo Module Unit Tests" {
    BeforeEach {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("UndoTest_" + [Guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    AfterEach {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
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
        @($logs).Count | Should Be 1

        # File moved away from root
        Test-Path $sourceFile | Should Be $false

        # Execute Undo
        $undoRes = Invoke-UndoOperation -TransactionFile $logs[0].FullName
        $undoRes.RestoredCount | Should Be 1
        Test-Path $sourceFile | Should Be $true
    }
}
