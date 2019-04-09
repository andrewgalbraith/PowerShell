<#
 .SYNOPSIS 
    When executed will refresh the SCVMM SandBox Library.
 .DESCRIPTION
    Gathers all of the library shares witin the SCVMM instance on VMM01 
    then looks for the library called "MTP Sandbox Library" and starts a refresh
    job in SCVMM.    
#>

Get-SCLibraryShare -VMMServer "VMM01.contoso.com" | 
    Where-Object { $_.Name -eq "MTP Sandbox Library" } | 
    Read-SCLibraryShare
