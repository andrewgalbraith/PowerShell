<#
.SYNOPSIS
    Update User photos in Office 365 and On-premise AD.

#>

# Open a session with Exchange Online
Connect-ExchangeOnline

# Import the last process time from the config file
Import-ScriptConfig
$last_processed = Get-ConfigItem LastProcessTime

# CSVs imported do not contain headers so we need to provide them to the import
# command
$headers = @("EmployeeCode","DisplayName","FirstName","KnownAsName","Surname")

# If there is no last processed date in the config file we need to set a hard
# limit on how far back to process. Arbitrarily choosing 3 months.
if(-not $last_processed) {
    $last_processed = (Get-Date).AddMonths(-3)
    Set-ConfigItem -Scope Script -Key LastProcessTime -Value $last_processed
}
Write-Verbose "Last time processed was: $lastprocessed"

# Get the list of users to process based on CSV files added since
# $last_processed. Ensure uinque and that the returned item matches employee ID
# format
Get-ChildItem "\\HRFILES01\PhotoUpdates\" |
    Where-Object LastWriteTime -gt $last_processed |
    ForEach-Object {
        Import-Csv $_.FullName -Header $headers
    } |
    Select-Object -ExpandProperty EmployeeCode -Unique |
    Where-Object { $_ -Match "^(\d{4,6})$" } | 
    Foreach-Object {
        try {
            Update-UserPhoto -EmployeeID $_
        } catch {
            Write-Error $_
        }
    }
