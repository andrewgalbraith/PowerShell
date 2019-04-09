<#
.SYNOPSIS
    Refreshes the federated domain configuration against the ADFS server.

.DESCRIPTION
    Refreshes the federated domain configuration against the ADFS server.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

Connect-MSOL
Set-MsolADFSContext -Computer ADFS01
Update-MsolFederatedDomain -DomainName contoso.com
