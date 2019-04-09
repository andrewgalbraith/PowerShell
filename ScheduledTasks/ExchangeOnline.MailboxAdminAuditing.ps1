<#
.SYNOPSIS
    Turns on mailbox auditing with a standard action set for every unaudited mailbox.

.DESCRIPTION
    Turns on mailbox auditing with a standard action set for every unaudited mailbox.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

# Establish as session with Exchange Online
Connect-ExchangeOnline

# Prepare parameters for mailbox auditing settings
$audit_admin = @("Update", "MoveToDeletedItems", "SoftDelete", "HardDelete", "SendAs", "SendOnBehalf", "Create", "UpdateFolderPermission") 
$audit_delegate = @("Update", "SoftDelete", "HardDelete", "SendAs", "Create", "UpdateFolderPermissions", "MoveToDeletedItems", "SendOnBehalf")
$audit_owner = @("UpdateFolderPermission", "MailboxLogin", "Create", "SoftDelete", "HardDelete", "Update", "MoveToDeletedItems")
$audit_params = @{
    AuditEnabled = $true
    AuditLogAgeLimit = 180
    AuditAdmin = $audit_admin
    AuditDelegate = $audit_delegate
    AuditOwner = $audit_owner
}

# Prepare filter for selecting mailboxes to enable auditing for
$filter = {
    AuditEnabled -eq $false -and `
    ( RecipientTypeDetails -eq "UserMailbox" -or `
      RecipientTypeDetails -eq "SharedMailbox" -or `
      RecipientTypeDetails -eq "RoomMailbox" -or `
      RecipientTypeDetails -eq "DiscoveryMailbox" )
}

# Select the mailboxes which don't have auditing enabled
Get-Mailbox -ResultSize Unlimited -Filter $filter |
    ForEach-Object {
        # Use the identity parameter rather than piping the mailbox in as some
        # mailboxes have the same name
        $name = $_.Name
        $audit_params.Identity = $_.Identity
        # Enable auditing for this mailbox using above parameters
        Write-Verbose "Enabling auditing for $name"
        Set-Mailbox @audit_params
    }
    
