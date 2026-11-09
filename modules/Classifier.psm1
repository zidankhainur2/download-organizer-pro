Set-StrictMode -Version Latest

#region Public Functions

<#
.SYNOPSIS
Assigns categories to OrganizerFile objects.

.DESCRIPTION
Categorizes files by matching file extensions against configured category extension lists.
Supports pipeline input or explicit parameter input.

.PARAMETER InputObject
OrganizerFile object passed via pipeline.

.PARAMETER Files
Collection of OrganizerFile objects.

.PARAMETER Categories
Category rules object loaded from configuration.

.OUTPUTS
OrganizerFile or OrganizerFile[]

.EXAMPLE
Get-DownloadFiles -Path $path | Set-FileCategory -Categories $config.Categories
#>
function Set-FileCategory {

    [CmdletBinding(DefaultParameterSetName = "Pipeline")]

    param(

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName = "Pipeline"
        )]
        [object]$InputObject,

        [Parameter(
            Mandatory,
            ParameterSetName = "Array"
        )]
        [array]$Files,

        [Parameter(Mandatory)]
        $Categories

    )

    begin {
        $lookup = @{}
        foreach ($category in $Categories.PSObject.Properties) {
            foreach ($extension in $category.Value) {
                $key = $extension.TrimStart('.').ToLowerInvariant()
                if (-not $lookup.ContainsKey($key)) { $lookup[$key] = $category.Name }
            }
        }
    }
    process {

        if ($PSCmdlet.ParameterSetName -eq "Pipeline") {

            $key = $InputObject.Extension.TrimStart('.').ToLowerInvariant()
            $category = if ($lookup.ContainsKey($key)) { $lookup[$key] } else { 'Others' }

            $InputObject.SetCategory($category)

            return $InputObject

        }

    }

    end {

        if ($PSCmdlet.ParameterSetName -eq "Array") {

            $resultList = New-Object System.Collections.Generic.List[object]

            foreach ($file in $Files) {

                $key = $file.Extension.TrimStart('.').ToLowerInvariant()
                $category = if ($lookup.ContainsKey($key)) { $lookup[$key] } else { 'Others' }

                $file.SetCategory($category)

                $resultList.Add($file)

            }

            return $resultList

        }

    }

}

<#
.SYNOPSIS
Classifies an array of files into categories.

.DESCRIPTION
Helper wrapper around Set-FileCategory for array operations using approved verb Invoke.

.PARAMETER Files
Array of OrganizerFile objects.

.PARAMETER Categories
Categories configuration mapping.

.OUTPUTS
OrganizerFile[]
#>
function Invoke-FileClassification {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [array]$Files,

        [Parameter(Mandatory)]
        $Categories

    )

    return Set-FileCategory `
        -Files $Files `
        -Categories $Categories

}

#endregion

Export-ModuleMember `
    -Function `
        Set-FileCategory,
        Invoke-FileClassification
