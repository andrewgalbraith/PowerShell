<#
.SYNOPSIS
  Search a specific host for a KB number
.DESCRIPTION
  Searches a host for an installed update.
#>

$hostname = Read-Host "Enter hostname"
$KBnumber = Read-Host "KB number"

if($KBNumber -notlike "KB*")
{
    $KBNumber = "KB" + $KBNumber    
}

Get-WMIObject -Class Win32_QuickFixEngineering `
    -ComputerName $hostname `
    -Filter "HotFixID='$KBNumber'"
