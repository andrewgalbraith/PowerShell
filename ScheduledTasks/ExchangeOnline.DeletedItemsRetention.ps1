<#
.SYNOPSIS
    Sets a 30-day Deleted Items retention on every user mailbox.

.DESCRIPTION
    Sets a 30-day Deleted Items retention on every user mailbox.

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
Connect-ExchangeOnline -UseDefaultStoredCredential:$true

# Run the command.
Get-Mailbox -Resultsize unlimited -Filter {(RecipientTypeDetails -eq 'UserMailbox')} | Set-Mailbox -RetainDeletedItemsFor 30
