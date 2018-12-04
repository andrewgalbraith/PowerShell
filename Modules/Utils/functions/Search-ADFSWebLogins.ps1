<#
.SYNOPSIS
    Get ADFS login attempts associated with an particular user account
.DESCRIPTION
    Scans the log files of ADFS to determine any login attempts associated with
    a particular user account. A date can be given to limit the number of results
    returned. This is only useful for certain types of logins, so should not be
    relied upon as the only souce of login activity logs.

    ADFS is an HTTP-based application, so the common status codes apply:
    200 - Success
    401 - Unauthorised
    302 - Redirect
    etc...
.PARAMETER User
    The username for which ADFS logins should be checked
.PARAMETER StartDate
    The date from which the logins should be checked.
.EXAMPLE
	Search-ADFSWebLogins -User jdoe
.EXAMPLE
    Search-ADFSWebLogins -User jdoe -StartDate 13-04-15
#>

function Search-ADFSWebLogins
{
	param(
		[parameter(Mandatory=$true)]
        [string]
        $User,
        [datetime]
        $StartDate
	)

    # The standard field for this logfile format.
    $fields = @("date","time","s-ip","cs-method","cs-uri-stem","cs-uri-query","s-port","cs-username","c-ip","cs(User-Agent)","sc-status","sc-substatus","sc-win32-status","time-taken")

	# Grab the list of log files within the defined date
	Get-ConfigItem ADFS.LogFolderUNC | Get-ChildItem | ? { $_.LastWriteTime -ge $StartDate } | Set-Variable LogFiles

	# Search each log file for instances containing the username and combine them into one list
    $LogEntries = $logfiles | % { Get-Content $_.FullName } | ? { $_ -like "*$user*"}

    # Convert the log entries into filterable objects
    $LogEntries | % {
        # Prepare an empty Hashtable
        $hash = @{}; 

        # Split the entry into an array of values
        $values = $_ -split " "; 

        # Add the values to the object using the fields defined above
        for($i = 0; $i -lt $fields.Count; $i++)
        { 
            $hash[$fields[$i]] = $values[$i];
        }

        # return the object
        [psCustomObject]$hash;
    }
}	
