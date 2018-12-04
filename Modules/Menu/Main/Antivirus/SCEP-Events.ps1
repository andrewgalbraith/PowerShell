<#
.SYNOPSIS
Get a list of event log entries related to FEP or SCEP.
.DESCRIPTION
Shows a list of event log entries related to FEP or SCEP, between now and yesterday at 00:00. Useful for getting the results of a scan kicked off through SCCM, or to check a user has run it when requested. Just follow the command with a computer name.
#>
$computer = read-host "Enter target Computer Name"
Get-Eventlog -computer $computer -log System -after ([DateTime]::Today.AddDays(-1)) | Where-Object {(($_.eventid -like "1001") -or ($_.eventid -like "1000") -or ($_.eventid -like "2000") -or ($_.eventid -like "2002")-or ($_.eventid -like "2004") -or ($_.eventid -like "5004") -or ($_.eventid -like "5007")) -and ($_.source -like "*antimal*")} | out-gridview
