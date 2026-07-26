Set-StrictMode -Version Latest

#region Private Functions

function Find-CategoryByExtension {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [string]$Extension,

        [Parameter(Mandatory)]
        $Categories

    )

    $extension = $Extension.TrimStart('.').ToLower()

    foreach ($category in $Categories.PSObject.Properties) {

        if ($extension -in $category.Value) {

            return $category.Name

        }

    }

    return "Others"

}

#endregion

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

    process {

        if ($PSCmdlet.ParameterSetName -eq "Pipeline") {

            $category = Find-CategoryByExtension `
                -Extension $InputObject.Extension `
                -Categories $Categories

            $InputObject.SetCategory($category)

            return $InputObject

        }

    }

    end {

        if ($PSCmdlet.ParameterSetName -eq "Array") {

            $resultList = New-Object System.Collections.Generic.List[object]

            foreach ($file in $Files) {

                $category = Find-CategoryByExtension `
                    -Extension $file.Extension `
                    -Categories $Categories

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

function Classify-Files {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [array]$Files,

        [Parameter(Mandatory)]
        $Categories

    )

    return Invoke-FileClassification `
        -Files $Files `
        -Categories $Categories

}

#endregion

Export-ModuleMember `
    -Function `
        Set-FileCategory,
        Invoke-FileClassification