<#
.SYNOPSIS
    Returns unassigned SCVMM IP addresses to the pool.

.DESCRIPTION
    Returns unassigned SCVMM IP addresses to the pool.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

#requiredmodule virtualmachinemanager

Get-SCIPAddress |
    Where-Object State -EQ UnAssigned |
    Revoke-SCIPAddress -ReturnToPool $true
