<#
.SYNOPSIS
Add IP addresses to the Relay List. (Extra Permissions Required)
.DESCRIPTION
This will allow adding of single IP addresses, or ranges to the IP relay for SMTP access.
#>

[IPAddress]$IPAddress1 = read-host "Enter First IP Address in the range, or a single IP address."
$IPAddress2 = read-host "Enter the Last IP Address in the range (Leave Blank if you only need to add a single address)"
if ($IPAddress2 -ne "") {[IPAddress]$IPAddress3 = $IPAddress2}

write-host "Connecting to Hybrid server..."

connect-hybrid

# Set the ip address
if ($IPAddress2 -eq "")
{
    try
    {
        $recvconn = get-receiveconnector "ip-based receive connector"
        $recvconn.remoteipranges += "$IPAddress1"
        set-receiveconnector "EXCH01\IP-based receive connector" -remoteipranges $recvconn.remoteipranges -erroraction stop
        Write-Host "Success!"
    }
    catch
    {
	$errormessage = $_.exception.message
	if ($errormessage -like '*is already present in the collection*') {write-host "$IPAddress1 is already in the Relay List"} 
    }
finally
{
write-host "If you entered an incorrect IP address for any reason, please speak to a member of the exchange team to have it removed."
}
}
else
{
    try
    {
        $recvconn = get-receiveconnector "ip-based receive connector"
        $recvconn.remoteipranges += "$IPAddress1"+"-"+"$IPAddress3"
        set-receiveconnector "EXCH01\IP-based receive connector" -remoteipranges $recvconn.remoteipranges -erroraction stop 
        Write-Host "Success!"        
    }
    catch
    {
	$errormessage = $_.exception.message
	if ($errormessage -like '*is already present in the collection*') {write-host "IP Range $IPAddress1-$IPAddress3 is already in the Relay List"} 
    }
finally
{
write-host "If you entered an incorrect IP address for any reason, please speak to a member of the exchange team to have it removed."
}
}
