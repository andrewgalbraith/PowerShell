<#
.SYNOPSIS
    Finds enabled computer objects in an OU that are NOT members of a given security group.

.DESCRIPTION
    Used to find workstations that had not yet been added to the Windows Hello for
    Business rollout group. Earlier iterations are kept in the commented block at the top.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

#$OU = Get-ADOrganizationalUnit -Filter {Name -eq 'OU=Desktop PCs,OU=US (Contoso Inc),OU=Resources (PCs\, Servers\, Printers etc),OU=Operations,DC=contoso,DC=com'}
<#
$ComputerReport = "$env:USERPROFILE\Desktop\PCs_H4B.csv"

Remove-Item $ComputerReport -ErrorAction SilentlyContinue

$STR = "Computer Name"

Add-Content $ComputerReport $STR

$computers = Get-ADComputer -Filter * -Properties MemberOf -SearchBase "OU=US (Contoso Inc),OU=Resources (PCs\, Servers\, Printers etc),OU=Operations,DC=contoso,DC=com" | Where-Object {$_.MemberOf -NotContains "GGP_Hello_For_Business"} 

ForEach ($computer in $computers)

{

$NameOfPC = $computer.Name

IF ($computers.MemberOf -notcontains "GGP_Hello_For_Business")

{

$STRNew = $NameofPC

Add-Content $ComputerReport $STRNew

}

} 
#>
#Get-ADComputer -Filter * -Properties MemberOf -SearchBase "OU=US (Contoso Inc),OU=Resources (PCs\, Servers\, Printers etc),OU=Operations,DC=contoso,DC=com" | Where-Object {$_.MemberOf -NotContains "GGP_Hello_For_Business"} | 
#Sort-Object -Descending | Format-Table -Property Name

#Grab the computer names from the first security group
$group = Get-ADGroup -Identity "GGP_Hello_For_Business"
$members = Get-ADGroupMember -Identity $group | select -Expand Name

#grab all computer obejects that are servers from AD and list the names not found in either security group
Get-ADComputer `
    -Filter *  `
    -Properties MemberOf `
    -SearchBase "OU=US (Contoso Inc),OU=Resources (PCs\, Servers\, Printers etc),OU=Operations,DC=contoso,DC=com" |
Where-Object {
    ( $_.MemberOf -notcontains $group.DistinguishedName ) -and
    ( $_.Enabled -eq "True" ) 
} |
Select-Object -ExpandProperty Name | Sort-Object -Descending | Format-Table -Prop Name >> "$env:USERPROFILE\Desktop\PCs_H4B.csv"
