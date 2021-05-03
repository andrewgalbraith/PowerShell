<#
.SYNOPSIS
    Returns the user currently logged on to a remote computer.

.DESCRIPTION
    Queries Win32_ComputerSystem on the target and returns its UserName property.
    Takes -ComputerName (alias -Computer) as a mandatory parameter.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

Param([parameter(Mandatory=$true)][alias("Computer")]$ComputerName)
 
#Get Computer Information from specified Computer
$ComputerInfo = Get-WmiObject Win32_ComputerSystem -Computer $ComputerName
$ComputerInfo.UserName
