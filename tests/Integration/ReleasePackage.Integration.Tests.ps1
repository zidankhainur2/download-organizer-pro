BeforeAll {
    $ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $version = (Import-PowerShellDataFile "$ProjectRoot/DownloadOrganizerPro.psd1").ModuleVersion
    $engine = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    function Invoke-ReleaseSmoke {
        param([string]$Archive)
        $ErrorActionPreference = 'Continue'
        $output = & $engine -NoProfile -STA -File "$ProjectRoot/tests/Smoke-Package.ps1" -PackagePath $Archive 2>&1
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
    }
}
Describe 'Release archive safety' {
    BeforeEach {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + ' spaces & [1]')
        [IO.Directory]::CreateDirectory($root) | Out-Null
        $archive = Join-Path $root "DownloadOrganizerPro-$version-portable.zip"
    }
    It 'rejects a changed download before reading or extracting its archive' {
        [IO.File]::WriteAllText($archive, 'corrupted download')
        (('0' * 64) + '  ' + [IO.Path]::GetFileName($archive)) | Set-Content -LiteralPath ($archive + '.sha256') -Encoding ASCII
        $result = Invoke-ReleaseSmoke $archive
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Release ZIP checksum mismatch'
    }
    It 'rejects an unexpected traversal entry even with a matching checksum and manifest' {
        $zip = [IO.Compression.ZipFile]::Open($archive, 'Create')
        try {
            $entry = $zip.CreateEntry('../escaped.txt')
            $stream = $entry.Open()
            try { $bytes = [Text.Encoding]::UTF8.GetBytes('untrusted'); $stream.Write($bytes,0,$bytes.Length) }
            finally { $stream.Dispose() }
        }
        finally { $zip.Dispose() }
        $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
        "$hash  $([IO.Path]::GetFileName($archive))" | Set-Content -LiteralPath ($archive + '.sha256') -Encoding ASCII
        @{ Version = $version; SHA256 = $hash; Archive = [IO.Path]::GetFileName($archive); Files = @(); SourceFiles = @() } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root "DownloadOrganizerPro-$version-release.json")
        $result = Invoke-ReleaseSmoke $archive
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Unexpected or missing file in release ZIP'
        Test-Path -LiteralPath (Join-Path $TestDrive 'escaped.txt') | Should -BeFalse
    }
}
