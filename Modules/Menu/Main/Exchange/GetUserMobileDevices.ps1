<#
    .SYNOPSIS
        List mobile devices associated with a mailbox
#>

$identity = Read-Host "Enter mailbox identity"

# Connect to Exchange Online Remote Service
Connect-ExchangeOnline

Write-Host @'
NOTE: This list shows all devices and apps that have connected to the mailbox.
It may be that some of these are no longer in existence.
'@ -ForegroundColor Yellow

# Get the mobile devices associated with the given mailbox, sort by last updated
# date and then output the useful attributes in a table.
Get-MobileDevice -Mailbox $identity |
    Sort-Object WhenChanged -Descending | 
    Format-Table FriendlyName,DeviceType,DeviceModel,DeviceOS,DeviceID,WhenCreated,WhenChanged
