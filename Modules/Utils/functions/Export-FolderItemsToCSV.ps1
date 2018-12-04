<#
.SYNOPSIS
    Output results from Test-FolderItemOneDriveReadiness to a CSV file.
.DESCRIPTION
    Outputs results from Test-FolderItemOneDriveReadiness to a CSV file.
.PARAMETER FolderItem
    An item from the Test-FolderItemOneDriveReadiness command
.PARAMETER Path
    Destiantion CSV filename
.PARAMETER ErrorsOnly
    Only output items that contained errors
.EXAMPLE
    Get-FolderItem | 
        Test-FolderItemOneDriveReadiness -RootPath (Get-Location) `
            -UserName $env:UserName | 
                Export-FolderItemsToCsv -Path .\filename.csv -ErrorsOnly
#>
function Export-FolderItemsToCsv {
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [PSCustomObject[]]$FolderItem,
        [parameter(Mandatory=$true)]
        [String]$Path,
        [Switch]$ErrorsOnly
    )
    begin {
        try {
            if(Test-Path $Path) {
                Remove-Item $Path -Force
            }
        } catch {
            throw "Report file already exists and could not be removed."
            exit
        }
    }

    process {

        if(($ErrorsOnly -and $_.Errors) -or (-not $ErrorsOnly)) {
            $_ | Export-CSV -Path $Path -Append -NoTypeInformation
        }
    
        return $_
    }
}
