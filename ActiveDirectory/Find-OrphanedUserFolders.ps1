<#
.SYNOPSIS
    Checks which home-folder names on a file share no longer match an AD account.

.DESCRIPTION
    Lists the folder names on a user-docs share, tries Get-ADUser on each, and reports
    the ones whose account no longer exists so they can be archived or removed.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

#List all the folders on the UserDocs area
$UserNameList = dir -Directory "\\contoso.com\Shares\UserDocs" -Name
#Check the folder list results from above to see the users that are still with the company and those that left
$finalResult = foreach ($usr in $UserNameList)
{
$obj = [PSCustomObject]@{
UserName = $usr
Status = ""
}
try
{
$ADUser = Get-ADUser -Identity $usr -ErrorAction continue
$obj.Status = "Exists"
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
$obj.Status = "Account doesn't Exist"
}
catch
{
$obj.Status = $_.Exception.Message
}
$obj
}
$migrate = $finalResult | where {$_.status -eq "Account doesn't Exist"} | select -ExpandProperty UserName
$migrate
