Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/Utils.psm1"

#region Public Functions

<#
.SYNOPSIS
Exports move execution details to a CSV report file.

.PARAMETER Results
Array of move result objects.

.PARAMETER OutputPath
Target CSV file path.

.OUTPUTS
[string]
#>
function Export-OrganizerCSV {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [AllowEmptyCollection()][array]$Results,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath

    )

    $parentDir = Split-Path $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($parentDir) -and -not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $Results | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    return $OutputPath

}

<#
.SYNOPSIS
Exports summary and execution metrics to a JSON report file.

.PARAMETER Summary
OrganizerSummary object.

.PARAMETER Results
Array of move result objects.

.PARAMETER OutputPath
Target JSON file path.

.OUTPUTS
[string]
#>
function Export-OrganizerJSON {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $Summary,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [AllowEmptyCollection()][array]$Results,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath

    )

    $parentDir = Split-Path $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($parentDir) -and -not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $reportObj = [PSCustomObject]@{
        GeneratedAt = (Get-Date -Format "o")
        Summary     = $Summary
        Results     = $Results
    }

    $jsonContent = $reportObj | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $OutputPath -Value $jsonContent -Encoding UTF8 -ErrorAction Stop
    return $OutputPath

}

<#
.SYNOPSIS
Generates a standalone HTML dashboard report with modern dark mode styling.

.PARAMETER Summary
OrganizerSummary object.

.PARAMETER Results
Array of move result objects.

.PARAMETER OutputPath
Target HTML file path.

.OUTPUTS
[string]
#>
function Export-OrganizerHTMLReport {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $Summary,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [AllowEmptyCollection()][array]$Results,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath

    )

    $parentDir = Split-Path $OutputPath
    if (-not [string]::IsNullOrWhiteSpace($parentDir) -and -not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $scanned = [Net.WebUtility]::HtmlEncode([string]$Summary.TotalFiles)
    $moved = [Net.WebUtility]::HtmlEncode([string]$Summary.Moved)
    $failed = [Net.WebUtility]::HtmlEncode([string]$Summary.Failed)
    $sizeMB = [Net.WebUtility]::HtmlEncode([string]$Summary.TotalSizeMB)
    $skipped = [Net.WebUtility]::HtmlEncode([string]$Summary.Skipped)
    $planned = [Net.WebUtility]::HtmlEncode([string]$Summary.Planned)
    $duplicates = [Net.WebUtility]::HtmlEncode([string]$Summary.Duplicates)
    $duration = [Net.WebUtility]::HtmlEncode((Format-Duration $Summary.Duration))
    $categoryRows = [Text.StringBuilder]::new()
    foreach ($key in ($Summary.Categories.Keys | Sort-Object)) {
        $encoded = [Net.WebUtility]::HtmlEncode([string]$key)
        $count = [Net.WebUtility]::HtmlEncode([string]$Summary.Categories[$key])
        [void]$categoryRows.AppendLine("<tr><td>$encoded</td><td>$count</td></tr>")
    }
    $fileRows = [Text.StringBuilder]::new()
    foreach ($item in $Results) {
        $statusClass = switch ($item.Status) { Moved { 'status-success' }; Failed { 'status-failed' }; Planned { 'status-planned' }; default { 'status-skipped' } }
        [void]$fileRows.Append('<tr>')
        foreach ($field in @('File', 'Category', 'SubCategory', 'Status', 'Destination', 'IsDuplicate', 'SHA256Hash', 'Reason')) {
            $value = if ($item.PSObject.Properties[$field]) { [string]$item.$field } else { '' }
            $value = [Net.WebUtility]::HtmlEncode($value)
            [void]$fileRows.Append("<td class='$statusClass'>$value</td>")
        }
        [void]$fileRows.AppendLine('</tr>')
    }

    $dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Download Organizer Pro - Execution Report</title>
    <style>
        :root {
            --bg: #0f172a;
            --panel: #1e293b;
            --border: #334155;
            --accent: #38bdf8;
            --text: #f8fafc;
            --muted: #94a3b8;
            --success: #22c55e;
            --error: #ef4444;
        }
        body { font-family: system-ui, -apple-system, sans-serif; background: var(--bg); color: var(--text); margin: 0; padding: 2rem; }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { color: var(--accent); margin-bottom: 0.5rem; }
        .meta { color: var(--muted); font-size: 0.9rem; margin-bottom: 2rem; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin-bottom: 2rem; }
        .card { background: var(--panel); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; }
        .card-label { color: var(--muted); font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.05em; }
        .card-value { font-size: 1.8rem; font-weight: 700; margin-top: 0.5rem; color: var(--accent); }
        .section { background: var(--panel); border: 1px solid var(--border); border-radius: 8px; padding: 1.5rem; margin-bottom: 2rem; }
        table { width: 100%; border-collapse: collapse; margin-top: 1rem; text-align: left; }
        th, td { padding: 0.75rem 1rem; border-bottom: 1px solid var(--border); font-size: 0.9rem; }
        th { color: var(--muted); font-weight: 600; background: rgba(0,0,0,0.2); }
        .status-success { color: var(--success); font-weight: 600; }
        .status-failed { color: var(--error); font-weight: 600; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Download Organizer Pro</h1>
        <div class="meta">Report Generated: $dateStr | Duration: $duration</div>

        <div class="grid">
            <div class="card"><div class="card-label">Files Scanned</div><div class="card-value">$scanned</div></div>
            <div class="card"><div class="card-label">Files Moved</div><div class="card-value">$moved</div></div>
            <div class="card"><div class="card-label">Failed</div><div class="card-value">$failed</div></div>
            <div class="card"><div class="card-label">Skipped / Planned / Duplicates</div><div class="card-value">$skipped / $planned / $duplicates</div></div>
            <div class="card"><div class="card-label">Total Size</div><div class="card-value">$sizeMB MB</div></div>
        </div>

        <div class="section">
            <h2>Category Distribution</h2>
            <table>
                <thead><tr><th>Category</th><th>Count</th></tr></thead>
                <tbody>$categoryRows</tbody>
            </table>
        </div>

        <div class="section">
            <h2>File Operations Detail</h2>
            <table>
                <thead><tr><th>File Name</th><th>Category</th><th>SubCategory</th><th>Status</th><th>Destination</th><th>Duplicate</th><th>SHA256</th><th>Reason</th></tr></thead>
                <tbody>$fileRows</tbody>
            </table>
        </div>
    </div>
</body>
</html>
"@

    Set-Content -LiteralPath $OutputPath -Value $html -Encoding UTF8 -ErrorAction Stop
    return $OutputPath

}

<#
.SYNOPSIS
Aggregates historical statistics across previous execution logs and reports.

.PARAMETER LogPath
Path to logs directory.

.OUTPUTS
PSCustomObject
#>
function Get-OrganizerStatistics {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath

    )

    if (-not (Test-Path -LiteralPath $LogPath)) {
        return [PSCustomObject]@{
            TotalExecutions = 0
            TotalMoved      = 0
            TotalFailed     = 0
        }
    }

    $logFiles = Get-ChildItem -LiteralPath $LogPath -Filter "*.log" -File
    $totalExecutions = 0
    $totalMoved = 0
    $totalFailed = 0

    foreach ($file in $logFiles) {
        $content = Get-Content -LiteralPath $file.FullName -Encoding UTF8 -ErrorAction Stop
        $totalExecutions += @($content | Where-Object { $_ -match '\[INFO\] Organizer Started$' }).Count
        $totalMoved += @($content | Where-Object { $_ -match "\[SUCCESS\] Moved:" }).Count
        $totalFailed += @($content | Where-Object { $_ -match "\[ERROR\] Failed:" }).Count
    }

    return [PSCustomObject]@{
        TotalExecutions = $totalExecutions
        TotalMoved      = $totalMoved
        TotalFailed     = $totalFailed
    }

}

#endregion

Export-ModuleMember `
    -Function `
        Export-OrganizerCSV,
        Export-OrganizerJSON,
        Export-OrganizerHTMLReport,
        Get-OrganizerStatistics
