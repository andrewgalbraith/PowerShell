<#
.SYNOPSIS
    Scan one or more home drive folders for size, quantity and OneDrive 
    readiness
.DESCRIPTION
    Accepts a list of folder paths and creates a powershell job for each of
    them. Uses the Test-FolderItemOneDriveReadiness, and Export-FolderItemsToCsv
    commands to collect information about each file and dertermine the readiness
    for OneDrive. The results are saved to a CSV file (one per home drive).
    Overall measurements are then taken for the number and volume of files and
    saved to a single CSV for all folders scanned.
.PARAMETER Username
    The username whose home drive folder should be scanned.
.PARAMETER OutputFolder
    The folder where summary and OneDrive error files should be output to. 
    Defaults to current working directory.
.PARAMETER SummaryOnly
    Do not export the individual error items to a separate CSV
.PARAMETER IncludeRedirected
    Include the redirected folders for the user in the scan
.EXAMPLE
    @("user1","user2","user3") |
        Start-FolderItemSummaryScan -OutputFolder "C:\TEMP"
.EXAMPLE
    "user1" | Start-FOlderItemSummaryScan -SummaryOnly -IncludeRedirected
#>
function Start-FolderItemSummaryScan {
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String]$Username,
        [String]$OutputFolder = (Get-Location).Path,
        [Switch]$SummaryOnly,
        [Switch]$IncludeRedirected

    )
    
    # Set up the summary file and remove it if it already exists.
    Begin {

        # Generate a path for the summary CSV
        $OutputSummaryFileName = Join-Path $OutputFolder "summary.csv"

        # Remove the summary file if it already exists
        try {
            if(Test-Path $OutputSummaryFilename) {
                Remove-Item $OutputSummaryFilename -Force
            }
        } catch {
            throw "Report file already exists and could not be removed."
        }
    }

    # Create the jobs for each of the home drives of the users in the pipeline
    # Maximum 10 jobs running concurrently.
    Process {
        # Make username available to nested scriptblocks
        $UserName = $_

        # Wait for an available slot...
        while ((Get-Job -State "Running").Count -ge 10) {
            Write-Verbose "Maximum job count reached. Waiting 10 seconds..."
            Start-Sleep -Seconds 10
        }

        # Prepare locations list for scanning
        $Locations = @()

        # Generate homedrive path from username by querying AD.
        $Locations += Get-ADUser $UserName -Properties HomeDirectory |
            Select-Object -ExpandProperty HomeDirectory

        # Get redirected folder locations also
        if($IncludeRedirected) {
            $Locations += Get-RedirectedFolderPathFromGPO -Username $UserName
        }

        # If the path is a DFS path, resolve the non-DFS path
        $Locations = $Locations | Foreach-Object {
            if(Test-Path $_) {
                if($_ -like "*contoso.com*") {
                    Resolve-DFSPath $_
                } else {
                    $_
                }
            } else {
                Write-Warning "$_ does not exist or could not be accessed."
            }
        }

        # If the home drive exists, start the scan job.
        Write-Verbose "Starting PowerShell job(s) for the following locations:"
        $Locations | Write-Verbose
        $Locations | Foreach-Object {
            Start-FolderItemSummaryScanJob -FolderPath $_  `
                -OutputFolder $OutputFolder `
                -Username $UserName `
                -SummaryOnly $SummaryOnly.IsPresent `
                -Description (Split-Path $_ -Leaf) |
            Out-Null
        }

    }

    End {
        # Receive the output of any jobs that have completed so far and export
        # it to the summary CSV file. Also remove the jobs.

        $properties = @(
            "Username"
            "Description"
            "NumberOfFiles"
            "TotalSizeOfFiles (GB)"
            "LargestFileSize (GB)"
            "OneDriveValidationErrors"
        )

        Get-Job -HasMoreData $true |
            Receive-Job -Wait -AutoRemoveJob |
            Select-Object $properties |
            Export-CSV -Path $OutputSummaryFilename `
                -Append `
                -NoTypeInformation
    }
}

function Start-FolderItemSummaryScanJob {
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [PSCustomObject]$FolderPath,
        [parameter(Mandatory=$true)]
        [String]$OutputFolder,
        [parameter(Mandatory=$true)]
        [String]$Username,
        [Boolean]$SummaryOnly = $false,
        [parameter(Mandatory=$true)]
        [String]$Description
    )

    # Create a PowerShell job to scan the contents of the given folder.
    Start-Job -ScriptBlock {
        param($FolderPath,$OutputFolder,$UserName,$SummaryOnly,$Description)

        if($Description -eq $Username) {
            $Description = "HomeDrive"
        }
        # Generate a filename for the OneDrive errors CSV
        $FileName = Join-Path $OutputFolder "$UserName-$Description.csv"

        # Scan and summarise the user's home drive folder
        if($SummaryOnly) {
            $results = $FolderPath | 
                Get-FolderItem | 
                Test-FolderItemOneDriveReadiness -RootPath $FolderPath `
                    -UserName $UserName |
                Measure-Object -Property Length,Errors -Sum -Maximum
        } else {

            # Define properties to save to CSV
            $Properties = @(
                @{ Name = "Relative File Path"; Expression={ $_.RelativePath } }
                @{ Name = "Path Length"; Expression = { $_.FullPathLength } }
                @{ Name = "Last Modified"; Expression = { $_.LastWriteTime } }
                @{ Name = "Size"; Expression = { $_.Length } }
                "Errors"
                "TooBig"
                "TooLong"
                "BadCharacters"
                "BeghinsWithSpace"
                "BadExtension"
                "BadPatterns"
            )

            $results = $FolderPath | 
                Get-FolderItem | 
                Test-FolderItemOneDriveReadiness -RootPath $FolderPath `
                    -UserName $UserName |
                Select-Object -Property $Properties  |
                Export-FolderItemsToCsv -Path $FileName -ErrorsOnly |
                Measure-Object -Property Size,Errors -Sum -Maximum
        }
        
        # Summarise the results as an object for use when receiving the job
        # output.
        if($results) {
            [psCustomObject]@{
                "Username" = $UserName
                "Description" = $Description
                "NumberOfFiles" = $results[0].Count
                "TotalSizeOfFiles (GB)" = "{0:N4}" -f ($results[0].Sum / 1GB)
                "LargestFileSize (GB)" = "{0:N4}" -f ($results[0].Maximum / 1GB)
                "OneDriveValidationErrors" = $results[1].Sum
            }
        } else {
            throw "No results for $UserName"
        }

    } -ArgumentList $FolderPath,$OutputFolder,$UserName,$SummaryOnly,$Description
}
