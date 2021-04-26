<#
.SYNOPSIS
    Exports a recursive membership report for an AD group to CSV.

.DESCRIPTION
    Walks the group recursively (nested groups included), looks up each user, and
    exports Name, SamAccountName, Email, Company and Office.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

Get-ADGroupMember -identity "GGP_EnableRegEdt" -Recursive | Get-ADUser -Property * | Format-Table Name, SamAccountName, Email, Company, Office -A | Export-csv -Path "$env:USERPROFILE\Desktop\regEditUsers.csv"
