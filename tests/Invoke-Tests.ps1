[CmdletBinding()]
param([string[]]$Path = @(), [switch]$Coverage, [string]$OutputDirectory = '')
$ErrorActionPreference = 'Stop'
if ($Path.Count -eq 0) { $Path = @("$PSScriptRoot/Unit", "$PSScriptRoot/Integration") }
$localPester = Join-Path $PSScriptRoot '../.tools/Pester/5.7.1/Pester.psd1'
if (Test-Path -LiteralPath $localPester) { Import-Module $localPester -RequiredVersion 5.7.1 }
else { Import-Module Pester -RequiredVersion 5.7.1 }
$configuration = New-PesterConfiguration
$configuration.Run.Path = $Path
$configuration.Run.PassThru = $true
$configuration.TestRegistry.Enabled = $false
if ($OutputDirectory) {
    $OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
    [IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null
}
if ($Coverage) {
    [IO.Directory]::CreateDirectory((Join-Path $PSScriptRoot '../.tools')) | Out-Null
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = @("$PSScriptRoot/../modules/*.psm1")
    $configuration.CodeCoverage.OutputPath = "$PSScriptRoot/../.tools/coverage.xml"
    $configuration.CodeCoverage.CoveragePercentTarget = 0
    if ($OutputDirectory) { $configuration.CodeCoverage.OutputPath = Join-Path $OutputDirectory 'coverage.xml' }
}
$configuration.Output.Verbosity = 'Detailed'
$result = Invoke-Pester -Configuration $configuration
if ($Coverage) {
    $coverageSummary = if ($OutputDirectory) { Join-Path $OutputDirectory 'coverage-summary.txt' } else { "$PSScriptRoot/../.tools/coverage-summary.txt" }
    $result.CodeCoverage | Format-List * | Out-File $coverageSummary
}
if ($OutputDirectory) {
    [ordered]@{ PowerShell = $PSVersionTable.PSVersion.ToString(); Apartment = [Threading.Thread]::CurrentThread.ApartmentState.ToString(); Pester = (Get-Module Pester).Version.ToString(); Result = [string]$result.Result; Total = $result.TotalCount; Passed = $result.PassedCount; Failed = $result.FailedCount; Skipped = $result.SkippedCount; FailedContainers = $result.FailedContainersCount; CoveragePercent = $(if ($Coverage) { $result.CodeCoverage.CoveragePercent } else { $null }) } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory 'summary.json') -Encoding UTF8
}
if ($result.Result -ne 'Passed' -or $result.TotalCount -eq 0 -or $result.FailedContainersCount -gt 0) {
    throw "Test run failed: $($result.Result), $($result.TotalCount) tests, $($result.FailedContainersCount) failed containers."
}
