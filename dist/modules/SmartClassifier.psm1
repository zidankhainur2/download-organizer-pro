Set-StrictMode -Version Latest

#region Private Functions

function Get-SmartCategory {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$SmartRules

    )

    $normalizedName = Format-FileName -Name $FileName

    $matchedItems = foreach ($category in $SmartRules.PSObject.Properties) {

        if ($null -eq $category.Value) { continue }

        foreach ($subCategory in $category.Value.PSObject.Properties) {

            $rule = $subCategory.Value
            if ($null -eq $rule) { continue }

            $keywords = $rule.Keywords
            $priority = if ($null -ne $rule.Priority) { [int]$rule.Priority } else { 0 }

            if ($null -eq $keywords) { continue }

            $score = 0

            foreach ($keyword in $keywords) {

                if ($normalizedName -match [regex]::Escape($keyword.ToLower())) {

                    $score += $priority

                }

            }

            if ($score -gt 0) {

                [PSCustomObject]@{
                    Category    = $category.Name
                    SubCategory = $subCategory.Name
                    Score       = $score
                }

            }

        }

    }

    if ($null -eq $matchedItems) {

        return $null

    }

    return (
        @($matchedItems) |
            Sort-Object Score -Descending |
            Select-Object -First 1
    )

}

#endregion

#region Public Functions

<#
.SYNOPSIS
Applies Smart Rules classification to OrganizerFile objects.

.DESCRIPTION
Evaluates filename keywords against configured Smart Rules and assigns subcategories and scores.

.PARAMETER Files
Array or collection of OrganizerFile objects.

.PARAMETER SmartRules
SmartRules configuration object.

.OUTPUTS
OrganizerFile[]

.EXAMPLE
Invoke-SmartClassification -Files $files -SmartRules $config.SmartRules
#>
function Invoke-SmartClassification {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [array]$Files,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$SmartRules

    )

    foreach ($file in $Files) {

        $result = Get-SmartCategory `
            -FileName $file.Name `
            -SmartRules $SmartRules

        if ($null -ne $result) {

            $file.SetSubCategory(
                $result.SubCategory,
                $result.Score
            )

        }
        else {

            $file.SetSubCategory("", 0)

        }

    }

    return $Files

}

function Apply-SmartClassification {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [array]$Files,

        [Parameter(Mandatory)]
        $SmartRules

    )

    return Invoke-SmartClassification `
        -Files $Files `
        -SmartRules $SmartRules

}

#endregion

Export-ModuleMember `
    -Function `
        Get-SmartCategory,
        Invoke-SmartClassification