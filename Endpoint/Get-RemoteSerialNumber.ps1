<#
.SYNOPSIS
    Grabs a remote machine's BIOS serial number and its last privileged logon.

.DESCRIPTION
    Two one-liners: Win32_Bios for the serial number, and Security event 4672 for the
    most recent user with elevated privileges.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

#Gets the serial number of a remote PC
Get-WmiObject -Class Win32_Bios -ComputerName 10.0.0.25

#Gets the last user who logged into the computer
Get-WinEvent  -Computer WORKSTATION01 -FilterHashtable @{Logname='Security';ID=4672} -MaxEvents 1|
     select @{N='User';E={$_.Properties[1].Value}}
