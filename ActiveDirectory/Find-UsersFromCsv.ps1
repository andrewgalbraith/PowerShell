<#
.SYNOPSIS
    Looks up AD users from a CSV of first name / last name / username.

.DESCRIPTION
    Reads a CSV with FirstName, LastName and Username columns and queries AD for each
    row. Useful for reconciling a spreadsheet from HR against the directory.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

$Users = Import-Csv -Path "$env:USERPROFILE\desktop\Americas_Reg_users.csv"
$OU = 'ou=GGP_EnableRegEdt,ou=Security Groups (Member Groups),ou=Operations,dc=contoso,dc=com'

foreach ($User in $Users)
{
    Get-ADUser -Path $OU -GivenName $User.FirstName -Surname $User.LastName -SamAccountName $User.Username 
}
