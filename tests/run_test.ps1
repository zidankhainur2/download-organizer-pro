Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path $PSScriptRoot -Parent

Import-Module "$ProjectRoot\modules\Models.psm1" -Force
Import-Module "$ProjectRoot\modules\Utils.psm1" -Force
Import-Module "$ProjectRoot\modules\Validation.psm1" -Force
Import-Module "$ProjectRoot\modules\Config.psm1" -Force
Import-Module "$ProjectRoot\modules\Scanner.psm1" -Force
Import-Module "$ProjectRoot\modules\Classifier.psm1" -Force
Import-Module "$ProjectRoot\modules\SmartClassifier.psm1" -Force
Import-Module "$ProjectRoot\modules\Mover.psm1" -Force
Import-Module "$ProjectRoot\modules\Logger.psm1" -Force
Import-Module "$ProjectRoot\modules\Summary.psm1" -Force

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("OrganizerTestEnv_" + [Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $tempDir "Resume_Jane.pdf") -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $tempDir "Archive_Project.zip") -Force | Out-Null

try {
    $configPath = "$ProjectRoot\config.json"
    $configObj = Get-Content $configPath -Raw | ConvertFrom-Json
    $configObj.Settings.DownloadsPath = $tempDir

    $testConfigPath = Join-Path $tempDir "test_config.json"
    $jsonContent = $configObj | ConvertTo-Json -Depth 10
    Set-Content -Path $testConfigPath -Value $jsonContent

    $config = Get-OrganizerConfig -Path $testConfigPath
    $logFile = Initialize-Logger -LogPath (Join-Path $tempDir "logs")
    $files = Get-DownloadFiles -Path $config.Settings.DownloadsPath
    Write-Host "Files found: $($files.Count)"

    $classified = Set-FileCategory -Files $files -Categories $config.Categories
    $smartClassified = Invoke-SmartClassification -Files $classified -SmartRules $config.SmartRules
    $moveResults = Move-OrganizerFiles -Files $smartClassified -BasePath $config.Settings.DownloadsPath
    $summary = Get-OrganizerSummary -Files $smartClassified -Results $moveResults -StartTime (Get-Date) -EndTime (Get-Date)

    Show-OrganizerSummary -Summary $summary -LogFile $logFile
    Write-Host "Integration Test Completed Successfully!"
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
}
