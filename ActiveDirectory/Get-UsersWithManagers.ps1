<#
.SYNOPSIS
    Exports every user in an OU with their department and manager's display name.

.DESCRIPTION
    Pulls Manager and Department for all users under the SearchBase and trims the
    manager's distinguished name down to just the CN.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

$path = "C:\Inc Managers.csv"

Get-ADUser -Filter * -SearchBase "OU=US (Contoso Inc),OU=Accounts (Users),OU=Operations,DC=contoso,DC=com" -Properties Manager, Department |
Select-Object -Property Name, Department, @{label='Manager';expression={$_.manager -replace '^CN=|,.*$'}} |

Export-Csv -Path $path
