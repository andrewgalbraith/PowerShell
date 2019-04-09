<#
.SYNOPSIS
    Adds users exported by regional CRM servers to matching AD groups.

.DESCRIPTION
    Checks each regional CRM server is reachable, reads any CSV files dropped in its log share, and adds
    the listed user IDs to the AD group named after the CSV file.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

<# 

.DESCRIPTION 
This script will check each of the CRM servers are available and if a CSV is present
will add the user IDs to the corresponding group.

#>

@("CRM-EU","CRM-IN","CRM-APAC","CRM-AM") |
    ForEach-Object {
        if (Test-Connection -ComputerName $_ -Count 1) {
            Get-ChildItem -Path "\\$_\d$\PowerShellScripts\Logs" -Filter *.csv |
            ForEach-Object {
                $users = (Get-Content $_.FullName) -split "," | Get-ADUser
                Add-ADGroupMember -Identity $_.BaseName -Members $users
            }
        }
    }
 
