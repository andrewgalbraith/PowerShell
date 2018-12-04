<#
.SYNOPSIS
Get basic PC information from Active Directory.
.DESCRIPTION
Lists last logon date, Operating System, what groups the PC is a member of, and the last known ipv4 address of target PC name.
#>
[string]$pcname = read-host "Enter target PC name"
write-host "Connecting to Active Directory."
try
{
get-adcomputer -identity $pcname -properties lastlogondate,operatingsystem,memberof,ipv4address | select name,enabled,lastlogondate,operatingsystem,ipv4address,memberof | fl -erroraction stop
}
catch
{
write-Warning -message "Target PC cannot be found."
}
