Set-StrictMode -Version Latest
Import-Module "$PSScriptRoot/Utils.psm1"

function New-SmartRulePatterns {
    param($SmartRules)
    foreach ($category in $SmartRules.PSObject.Properties) {
        foreach ($sub in $category.Value.PSObject.Properties) {
            $patterns = foreach ($keyword in $sub.Value.Keywords) {
                $normalized = (Format-FileName $keyword).Trim()
                '(?<![\p{L}\p{N}])' + ([regex]::Escape($normalized) -replace '\\ ', '\s+') + '(?![\p{L}\p{N}])'
            }
            [pscustomobject]@{ Category = $category.Name; SubCategory = $sub.Name; Priority = [int]$sub.Value.Priority; Patterns = @($patterns) }
        }
    }
}
<#
.SYNOPSIS
Returns the highest-scoring filename stem rule, optionally restricted to a category.
#>
function Get-SmartCategory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FileName, [Parameter(Mandatory)]$SmartRules, [string]$Category)
    $patterns = @(New-SmartRulePatterns $SmartRules)
    Find-SmartMatch $FileName $patterns $Category
}
function Find-SmartMatch {
    param([string]$FileName, [array]$Patterns, [string]$Category)
    $name = Format-FileName ([IO.Path]::GetFileNameWithoutExtension($FileName))
    $best = $null
    $bestScore = 0
    foreach ($rule in $Patterns) {
        if ($Category -and $rule.Category -ne $Category) { continue }
        $score = 0
        foreach ($pattern in $rule.Patterns) { if ($name -match $pattern) { $score += $rule.Priority } }
        if ($score -gt $bestScore) {
            $bestScore = $score
            $best = [pscustomobject]@{ Category = $rule.Category; SubCategory = $rule.SubCategory; Score = $score }
        }
    }
    $best
}
<#
.SYNOPSIS
Applies precomputed category-scoped smart patterns to classified files.
#>
function Invoke-SmartClassification {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][array]$Files, [Parameter(Mandatory)]$SmartRules, [string]$Category)
    $patterns = @(New-SmartRulePatterns $SmartRules)
    foreach ($file in $Files) {
        $scope = if ($Category) { $Category } else { $file.Category }
        $match = Find-SmartMatch $file.Name $patterns $scope
        if ($match) { $file.SetSubCategory($match.SubCategory, $match.Score) }
        else { $file.SetSubCategory('', 0) }
    }
    return $Files
}
Export-ModuleMember -Function Get-SmartCategory, Invoke-SmartClassification
