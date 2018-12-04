<#
.SYNOPSIS
    Remove profiles from users in a specific OU and enable MDM
.DESCRIPTION
    Given an OU Distinguished Name, removes the profile path from any user in
    that OU.
#>

# Provide OU Distinguishedname
$dn = Read-Host -Prompt 'Enter OU Distingushed name here'

# Provide File name and location on your PC in the form C:\documents\file.csv to be used to export list of users with Active Sync on 
$file = Read-Host -prompt 'Provide File name and location on your PC in the form C:\documents\file.csv to be used to export list of users with Active Sync on '

# Remove Roaming profile from all users in the OU provided above
Get-ADUser -SearchBase $dn -Properties Profilepath -LDAPFilter '(name=*)' | 
    Where-Object { $_.profilepath -ne $null } | 
    Set-ADUser -clear profilepath

# Define the group DN for ActiveSync enabled users
$ActiveSyncDN = (Get-ADGroup "GRS_Exchange_Online_ActiveSync_Allowed_Users").DistinguishedName
$OPSIntuneDN = (Get-ADGroup "GRS_OPS_INTUNE_TEST").DistinguishedName

# Finds lists of users in the OU that are not members of Active Sync group
$NoAS = Get-ADUser -SearchBase $dn `
    -Filter { (-not (memberof -eq $ActiveSyncDN)) -and (-not (memberOf -eq $OPSIntuneDN)) -and (Enabled -eq $true) } | 
        Select-Object samaccountname | 
        Sort-Object samaccountname

# Adds users who doesn't have ActiveSync on to MDM group
Add-ADGroupMember -identity "GRS_OPS_INTUNE_TEST" -Members $NoAS

# Exports list of users from teh OU provided earlier to a CSV 
Get-ADUser -LDAPFilter "(&(memberOf=$ActiveSyncDN))" -SearchBase $dn | 
    Select-Object name | 
    Sort-Object Name | 
    Export-CSV $file
