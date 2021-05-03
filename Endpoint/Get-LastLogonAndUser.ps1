<#
.SYNOPSIS
    For each AD computer matching a name pattern, reports last logon time and the current user.

.DESCRIPTION
    Combines lastLogonTimestamp from AD with the logged-on user from Win32_ComputerSystem
    and appends one row per computer to a CSV.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

$computers = Get-ADComputer -Filter {Name -Like 'US0*'} -Properties OperatingSystem


foreach($computer in $computers) { 

    $pcinfo = Get-ADComputer $computer.Name -Properties lastlogontimestamp | Select-Object @{Name="Computer";Expression={$_.Name}}, 
             @{Name="Lastlogon";Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}

    $ComputerInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer.name 
    #$SecIdentifier = New-Object System.Security.Principal.SecurityIdentifier($lastuserlogoninfo.SID)
    $username = $ComputerInfo.Username
 

    # Create hashtable for properties
    $properties = @{'Computer'=$pcinfo.Computer;
                    'LastLogon'=$pcinfo.Lastlogon;
                    'User'=$username
                   } #end $properties
    write-output (New-Object -Typename PSObject -Property $properties) |
    Export-Csv "$env:USERPROFILE\Desktop\PCs.csv" -Append 
}
