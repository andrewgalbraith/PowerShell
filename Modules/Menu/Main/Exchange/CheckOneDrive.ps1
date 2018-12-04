<#
.SYNOPSIS
Check for active OneDrive accounts.
#>

$o365cred = (Get-ExchangeOnlineCredentials)
cls
# Organisation name for SharePoint Online URL
$strO365OrgName = "contoso"
write-host "Checking all users. Only active OneDrive accounts will be listed. Please be patient."

try
{
Import-csv "Y:\IT Support\Scripts\Powershell\CustomModules\Task Scripts\Mailbox_report.csv" | 
    Where-Object {$_.License -eq "E3"} |
    Foreach-Object {
        
        $upn = $_.UserID

        # Determine site name from UPN (replace @ or . with _)
        $SiteString = $upn -replace "@|\.","_"
        $SiteURL = "https://" + $strO365OrgName + "-my.sharepoint.com/personal/" + $SiteString

        #Write-Host "Verifying user: $upn"

        # Set up a WebRequest object for probing the OneDrive Site
        $HTTP_Request = [System.Net.WebRequest]::Create($SiteUrl)
        $HTTP_Request.UseDefaultCredentials = $true
        $HTTP_Request.Credentials = $o365cred

        # Try connecting to the site, catch the error
        $HTTP_Response = $null
        try {
            $HTTP_Response = $HTTP_Request.GetResponse()
        }
        catch [System.Net.WebException] {
            $HTTP_Response = $_.Exception.Response
        }

        # Get HTTP status code from the error
        $HTTP_Status = $HTTP_Response.StatusCode

        # If the status code is 200 or 403, the site exists. Otherwise it doesn't
        if ($HTTP_Status -eq 200 -or $HTTP_Status -eq 403 )   { 
            Write-Host -ForegroundColor Green "OneDrive site for user $upn exists!"
        }
        else {
	# Un-Comment following line if you want a more verbose output.
	# Write-Host -ForegroundColor Yellow "The OneDrive site for user $upn does not respond, try again later or provision it again"
        }
            
    }
}
catch
{
$errormessage = $_.exception.message
if ($errormessage -like '*could not find file*') 
{
write-Warning "Mailbox_Report.csv not found."
}
}
finally
{
write-host "All accounts checked, or you pressed Ctrl+C."
}
