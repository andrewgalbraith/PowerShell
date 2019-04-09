<#
.SYNOPSIS
    Enables an Online Archive for migrated mailboxes that don't have one.

.DESCRIPTION
    Finds remote user mailboxes without an archive, skips anyone in an exclusion group, and enables the
    archive via the hybrid Exchange server.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

Connect-hybrid
Import-Module ActiveDirectory
#Creates a variable called $archive that contains a list of all migrated user mailboxes that do not currently have Archives. (Not shared or room mailboxes)
$archive = get-remotemailbox -resultsize unlimited -filter {(RecipientTypeDetails -eq 'RemoteUserMailbox') -and (RemoteRecipientType -eq 'ProvisionMailbox')}

if($archive.count -eq 0) {
write-host "There are currently no accounts that are eligible for an Online Archive"
exit
}
else
{
write-host "These are the accounts in the correct state to have an Online Archive:"
write-host $archive | fl
}


#Gets a list of mailboxes in the group "GRS_O365_NO_ARCHIVE" to be used for exclusion of special accounts.
$no_archive = Get-ADGroupMember GRS_O365_NO_ARCHIVE | % { $_.Name }

#Adds an "archive name" to each listing in the previously created variable.

foreach ($a in $archive) {
    
	#Ignores mailboxes in the group "GRS_O365_NO_ARCHIVE"
    if(($no_archive -contains $a.DisplayName) -eq $false) {

	    #Comment out the below line for Maintenance.
	    $a.ArchiveName.Add("Online Archive - $a")

	    #enable the below line for Maintenance.
	    #Write-Host "Enabling archive for $a"

	    #Comment out the below line for Maintenance.
	    Enable-RemoteMailbox $a.Identity -Archive -ArchiveName $a.ArchiveName | out-host
    }
    else
    {
	    Write-Host "Skipping $a because of group membership"
    }
}
