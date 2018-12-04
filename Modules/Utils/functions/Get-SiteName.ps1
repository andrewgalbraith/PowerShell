<# 
.SYNOPSIS
    Get the AD site name of the given machine
.DESCRIPTION
    Gets the AD site name of the given machine. If the computername is not
    specified, it returns the site name of the local host. 
.PARAMETER ComputerName
    The name of the computer to get the site of.
#>
function Get-SiteName {
    param(
        [String]$ComputerName
    )

    if($ComputerName)
    {
        Get-CimInstance -CimSession $ComputerName |
            Where-Object DNSForestName |
            Select-Object -First 1 |
            Select-Object -ExpandProperty ClientSiteName
    }
    else 
    {
        Get-CimInstance -CimSession $VMMServer |
            Where-Object DNSForestName |
            Select-Object -First 1 |
            Select-Object -ExpandProperty ClientSiteName        
    }
}
