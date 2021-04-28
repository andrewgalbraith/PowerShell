<#
.SYNOPSIS
    Prints every group under a search base along with its members.

.DESCRIPTION
    Enumerates groups beneath the given SearchBase and writes each group's name and
    Members property to the console.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

$Groups = Get-ADGroup -Properties * -Filter * -SearchBase "GGP_EnableRegEdt,OU=Security Groups (Member Groups),OU=Operations,DC=contoso,DC=com"
Foreach($G In $Groups)
{
    Write-Host $G.Name
    Write-Host "-------------"
    $G.Members
}
