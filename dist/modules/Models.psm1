Set-StrictMode -Version Latest

#region Enumerations

enum MoveStatus {
    Pending
    Moved
    Failed
    Skipped
}

#endregion

#region Models

class OrganizerFile {

    [string]$Name
    [string]$Extension
    [string]$FullPath
    [string]$Directory

    [Int64]$SizeBytes
    [double]$SizeMB

    [datetime]$Created
    [datetime]$Modified

    [string]$Category = "Others"

    [string]$SubCategory = ""

    [string]$DestinationPath = "Others"

    [int]$SmartScore = 0

    [MoveStatus]$Status = [MoveStatus]::Pending

    [string]$Destination = ""

    [string]$ErrorMessage = ""

    [string]$SHA256Hash = ""

    [bool]$IsDuplicate = $false

    OrganizerFile() {
    }

    [void] SetCategory([string]$Category) {

        $this.Category = $Category

        $this.DestinationPath = $Category

    }

    [void] SetSubCategory(
        [string]$SubCategory,
        [int]$Score
    ) {

        $this.SubCategory = $SubCategory

        $this.SmartScore = $Score

        if ([string]::IsNullOrWhiteSpace($SubCategory)) {

            $this.DestinationPath = $this.Category

        }
        else {

            $this.DestinationPath = Join-Path `
                $this.Category `
                $SubCategory

        }

    }

    [void] MarkMoved(
        [string]$Destination
    ) {

        $this.Status = [MoveStatus]::Moved

        $this.Destination = $Destination

        $this.ErrorMessage = ""

    }

    [void] MarkFailed(
        [string]$Reason
    ) {

        $this.Status = [MoveStatus]::Failed

        $this.ErrorMessage = $Reason

    }

    [void] MarkSkipped(
        [string]$Reason
    ) {

        $this.Status = [MoveStatus]::Skipped

        $this.ErrorMessage = $Reason

    }

}

class OrganizerSummary {

    [int]$TotalFiles

    [int]$Moved

    [int]$Failed

    [int]$Skipped

    [double]$TotalSizeMB

    [timespan]$Duration

    [hashtable]$Categories

    OrganizerSummary() {

        $this.Categories = @{}

    }

}

#endregion

#region Public Functions

<#
.SYNOPSIS
Creates a new OrganizerFile object from a FileInfo object.

.DESCRIPTION
Converts a System.IO.FileInfo object into a strongly typed OrganizerFile domain instance.

.PARAMETER File
The FileInfo object representing the file on disk.

.OUTPUTS
OrganizerFile

.EXAMPLE
New-OrganizerFile -File (Get-Item "C:\Downloads\file.pdf")
#>
function New-OrganizerFile {

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.IO.FileInfo]
        $File

    )

    $item = [OrganizerFile]::new()

    $item.Name = $File.Name

    $item.Extension =
        $File.Extension.TrimStart('.').ToLower()

    $item.FullPath = $File.FullName

    $item.Directory = $File.DirectoryName

    $item.SizeBytes = $File.Length

    $item.SizeMB =
        [Math]::Round(
            $File.Length / 1MB,
            2
        )

    $item.Created = $File.CreationTime

    $item.Modified = $File.LastWriteTime

    return $item

}

<#
.SYNOPSIS
Creates a new OrganizerSummary domain object.

.OUTPUTS
OrganizerSummary

.EXAMPLE
$summary = New-OrganizerSummary
#>
function New-OrganizerSummary {

    [CmdletBinding()]

    param()

    return [OrganizerSummary]::new()

}

#endregion

Export-ModuleMember `
    -Function `
        New-OrganizerFile,
        New-OrganizerSummary