<#
.SYNOPSIS
    Lists members of an AD group, filtered to users whose Office is in the Americas.

.DESCRIPTION
    Resolves the group's distinguished name, then filters Get-ADUser results by Office
    (United States, Canada, Mexico, Brazil) and group membership. Output is sorted by
    company and name and exported to CSV.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

#first you get distinguished name
$dn = Get-ADGroup 'GGP_EnableRegEdt' | Select -ExpandProperty DistinguishedName
#now you perform filtering
Get-ADUser -Filter 'Office -Like "United States*" -or Office -Like "Canada*" -or Office -Like "Mexico*" -or Office -Like "Brazil*"' -Properties MemberOf, company | 
Where-Object {$_.MemberOf.Contains($dn)} | Select-Object name, userprincipalname, company | sort company, name | Export-Csv "$env:USERPROFILE\Desktop\regEditUsers.csv" -Delimiter ','
