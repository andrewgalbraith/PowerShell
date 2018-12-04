<#
.SYNOPSIS
    Retrieve a list of failed ADFS logins from the ADFS server event logs
.DESCRIPTION
    Scans the Security event log of the ADFS server to determine any failed login attempts.
    The results can optionally be filtered to return only events associated with a specific 
    username.
.PARAMETER User
    The username for which ADFS server security logs should be checked.
.EXAMPLE
    Get-ADFSFailedLogins -User jdoe
#>


function Get-ADFSFailedLogins {
    param(
        [string]
        $User
    )
    
    $events = Get-EventLog -ComputerName ADFS01 -LogName Security -Message "*SVC_ADFS*" | 
        ? { $_.EventID -eq 4625} | 
        % { [psCustomObject]@{
                "Time" = $_.TimeGenerated; 
                "Username" = $_.ReplacementStrings[5]; 
                "Reason" = (get-ConfigItem Security.FailedLoginStatusMap).($_.ReplacementStrings[9]) 
            }
        }

    if($user)
    {
        $events| ? { $_.Username -like "*$user*"}
    }
    else
    {
        $events    
    }
}
