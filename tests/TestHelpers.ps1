$ProjectRoot = Split-Path $PSScriptRoot -Parent
function New-TestConfig {
    param([string]$Path)
    $config = Get-Content -LiteralPath "$ProjectRoot/config.json" -Raw | ConvertFrom-Json
    $config.Settings.DownloadsPath = $Path
    $config
}
