<#
.SYNOPSIS
    Enforces ActiveSync on/off based on membership of an allow-list group.

.DESCRIPTION
    Enforces ActiveSync on/off based on membership of an allow-list group.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

### This script has dependencies!
### It cannot just be run....
### The PS environment must contain certain comandlets fromt the modules stored at
### \\contoso.com\global\IT\Scripts\Powershell\CustomModules
### Speak to the automation owner before running.

# Connect to ExchangeOnline with credentials stored in config module
# Note: Stored Credentials can only be used in the context of the user whose credentials are stored.
Connect-ExchangeOnline 

# Run the command.
$mailboxes = Get-CASMailbox -resultSize unlimited
$asusers = Get-DistributionGroupMember -Identity 'GRS_Exchange_Online_ActiveSync_Allowed_Users' -ResultSize Unlimited
 
$asguids = @()
 foreach ($user in $asusers) {
     $asguids += $user.GUID
 }
 
foreach ($mailbox in $mailboxes) {
     if ($asguids -contains $mailbox.GUID ) {
         if ($mailbox.ActiveSyncEnabled -ne $true) {
             $mailbox | Set-CASMailbox -ActiveSyncEnabled $true
             echo "$mailbox is enabled"
         }
     }
     else {
         if ($mailbox.ActiveSyncEnabled -ne $false) {
             $mailbox | Set-CASMailbox -ActiveSyncEnabled $false
             echo "$mailbox is disabled"
         }
     }
 }
