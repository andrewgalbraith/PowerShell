<#
.SYNOPSIS
    Retrieve a list of failed NPS logins from the NPS server log files
.DESCRIPTION
    Parses the NPS log files for events relating to a specific user. Relevant
    attributes of the log entries are extracted and displayed in a readable
    table, such as the reason for failed authentication.
.PARAMETER User
    The username for which NPS logs should be checked.
.PARAMETER StartDate
    The number of weeks to count back, defaults to 7 days ago.
.EXAMPLE
    Get-NPSLogins -User jdoe
.EXAMPLE 
    Get-NPSLogins -User jdoe -StartDate 01-02-15
#>

function Get-NPSLogins {

    param (
        [parameter(Mandatory=$true)]
        [string]
        $Username,
        [datetime]
        $StartDate = (Get-Date).AddDays(-7)
    )

    Get-ChildItem (Get-ConfigItem NPS.LogFileLocation) -File |
        Where-Object { $_.LastWriteTime -gt $StartDate } | 
        Get-Content | 
        Where-Object {
            $_ -like "*$Username*"
        } | Foreach-Object {
            # Split the line into its tokens (separated by a ,)
            $line_split = $_ -split ','

            # Create an empty hashtable to store the attributes and values
            $line_parsed = @{}
            
            # Process the tokens into the hashtable
            for ($i=6;$i -lt $line_split.count; $i+=2) 
            {
                $line_parsed[$line_split[$i]] = $line_split[$i+1];
            }

            # Determine the message for the failure code
            $type = (Get-ConfigItem Security.IAS.PacketTypes)[[int]$line_parsed["4136"]]
            $message = (Get-ConfigItem Security.IAS.ReasonCodes)[[int]$line_parsed["4142"]]

            # Grab the Caller station ID
            $station = $line_parsed["31"]
            
            # grab the info we want from the hashtable into a new hashtable
            # and output.
            [psCustomObject]@{
                Date = [datetime]($line_split[2] + " " + $line_split[3]);
                Username = $line_split[1];
                PacketType = $type;
                FailureReason = $message;
                Station = $station
            }
        }
}
