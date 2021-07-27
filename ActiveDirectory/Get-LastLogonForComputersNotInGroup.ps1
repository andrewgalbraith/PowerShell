<#
.SYNOPSIS
    Finds computers missing from a security group, then pulls the last interactive logon for each.

.DESCRIPTION
    Two stages: (1) list enabled computers in the OU that are not in the target group,
    (2) for each computer in a text file, read Security event 4672 to find the last
    non-system logon and who it was. Results go to the console and a CSV.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

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




# get an array of computernames loaded from the text file
$machines = Get-Content -Path "$env:USERPROFILE\Desktop\PCs_H4B.txt"

$result = foreach ($computer in $machines) {
    # test if the compurer is on-line
    #if (!(Test-Connection -ComputerName $computer -Quiet)) {
    #    Write-Warning "Computer '$computer' is off-line."
        # skip this computer and carry on with the next iteration
    #    continue
    #}

    # search the computers eventlog and parse the username and last logon time from that
    # you can play around with other values for -MaxEvents if you feel you're missing information.
    Get-WinEvent -ComputerName $computer -FilterHashtable @{Logname='Security';ID=4672} -MaxEvents 50 | 
        Where-Object { $_.Properties[1].Value -notmatch 'SYSTEM|NETWORK SERVICE|LOCAL SERVICE' } | 
        Select-Object @{Name ='ComputerName'; Expression = {$_.MachineName}},
                      @{Name ='UserName';     Expression = {$_.Properties[1].Value}},
                      @{Name ='LastLogon';    Expression = {$_.TimeCreated}} -First 1

}

# show on screen:
$result | Format-Table -AutoSize

# save as CSV file
$result | Export-Csv -Path "$env:USERPROFILE\desktop\LastLogonInfo_2.csv" -NoTypeInformation
