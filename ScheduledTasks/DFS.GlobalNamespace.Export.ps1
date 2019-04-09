<#
.SYNOPSIS
    Exports the DFS namespace to XML as a recoverable backup.

.DESCRIPTION
    Exports the DFS namespace to XML as a recoverable backup.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

<# 

.DESCRIPTION 
 This is a script that will take an export of \\contoso.com\global and store it in XML format.
 To be used as a backup and provide the ability to recreate paths if they have been incorrectly removed. 

#> 

dfsUtil root export \\contoso.com\Global "\\contoso.com\global\IT\DFS Report\dfs_namespace_backup.xml"
