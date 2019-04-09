<#
.SYNOPSIS
    Deletes VSS shadow copies on all Hyper-V hosts at a site.

.DESCRIPTION
    Deletes VSS shadow copies on all Hyper-V hosts at a site.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

 Import-Module virtualmachinemanager
 
 Write-Host "Collecting host and snapshot info..."
 $hosts  = Get-SCVMHost | ? VMHostGroup -like "*GB-SiteA*"

 $host_names = $hosts | Foreach-Object -MemberName ComputerName

 $snapshots = (Get-WmiObject -Class win32_shadowcopy -ComputerName $host_names -ErrorAction SilentlyContinue)

 # Write-Warning ("Warning. About to remove all snapshots from the following hosts: " + ($host_names -join ", ").toUpper())
 # pause

 Write-Host "Removing snapshots... " -NoNewLine
 $snapshots | % { $_.Delete() }
 Write-Host "Done"
 
