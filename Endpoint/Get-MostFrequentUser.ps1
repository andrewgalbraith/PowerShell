<#
.SYNOPSIS
    Returns the user who has logged on most often in the last N Winlogon events.

.DESCRIPTION
    Reads the newest Winlogon events from the System log, translates each SID to an
    account name, groups by user and returns the most frequent one (minus the domain).

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

function get-freq-user
{
    $newest = 20
	$ComputerName = $env:computername
	
	$UserProperty = @{ n = "User"; e = { ((New-Object System.Security.Principal.SecurityIdentifier $_.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])).ToString() } }
	$logs = Get-EventLog System -Source Microsoft-Windows-Winlogon -ComputerName $ComputerName -newest $newest | select $UserProperty
	
	$logs = $logs | Group-Object user | Sort Count | Select -First 1 | Select-Object -Property Name | Out-String
	$index = $logs.indexOf("\") + 1
	
	return $logs.substring($index)
}
