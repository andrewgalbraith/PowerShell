<#
.SYNOPSIS
    Investigates AD account lockouts and emails the helpdesk a report per lockout.

.DESCRIPTION
    Reads forwarded 4740 (lockout) events from the central event collector, then for each lockout
    checks the calling workstation for RDP sessions and recent failed-login / Kerberos events for that
    user (falling back to the RADIUS server when no caller is recorded). Each lockout becomes an HTML
    email with the related events. Uses the Config module to remember the last processed time.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

Write-Debug "Start Script"


# Get all login failed events by a specific user on a given host
function GetLoginsOnHost($HostName = "localhost",[string]$Username) 
{
    Write-Debug "---- GetLoginsOnHost() -> Get logins on $HostName"

    # Get failed login events from the caller computer.
    Get-WinEvent -LogName Security `
        -ComputerName $HostName -ErrorAction SilentlyContinue `
        -FilterXPath "*[System[TimeCreated[timediff(@SystemTime) <= 1800000]]] and *[System[Keywords=`"0x8010000000000000`"]]" |
        Where-Object { ($_.Properties | Foreach-Object -MemberName Value) -like "*$Username*" } | 
        Foreach-Object {ProcessFailedLoginsOnHost $_ $HostName }

    # Get Kerberos events from the caller computer System log
    Get-WinEvent -ComputerName $HostName -ErrorAction SilentlyContinue `
        -ProviderName "Microsoft-Windows-Security-Kerberos" `
        -FilterXPath '*[System[EventID="14" and TimeCreated[timediff(@SystemTime) <= 1800000]]]' | 
        Where-Object { ($_.Properties | Foreach-Object -MemberName Value) -like "*$Username*" } | 
        Foreach-Object { ProcessFailedLoginsOnHost $_ $HostName}
}

# Extract useful information from a failed login event.
function ProcessFailedLoginsOnHost($Event,$HostName)
{
    [psCustomObject]@{ 
        "HostName" = $HostName;
        "Message" = $Event.Message;
        "EventID" = $Event.ID;
        "Time" = $Event.TimeCreated;
    }
}

# Get forwarded lockout events from AUTOMATION01
function GetForwardedEvents([DateTime]$fromTime)
{
    $time = ((Get-Date) - $fromTime).TotalMilliseconds

    $filterXML = @"
<QueryList>
    <Query Id=`"0`" Path=`"ForwardedEvents`">
        <Select Path=`"ForwardedEvents`">*[System[(EventID=4740) and TimeCreated[timediff(@SystemTime) &lt;= $time]]]</Select>
    </Query>
</QueryList>
"@

    $server = Get-ConfigItem Automation.ServerName
    if($server -eq $env:COMPUTERNAME) {
        Get-WinEvent -FilterXML $filterXML
    } else {
        Get-WinEvent -ComputerName $server -FilterXML $filterXML
    }
    
}

function ProcessForwardedEvents 
{
    $time = Get-ConfigItem LastProcessTime
    Write-Debug "ProcessForwardedEvents() -> Getting forwarded events"
    GetForwardedEvents -FromTime $time |
    Foreach-Object {
        Write-Debug "-- ProcessForwardedEvents() -> Get related info for each lockout."
        $entry = [pscustomObject] @{
            "Time" = $_.TimeCreated;
            "Username" = ExtractUsernameFromEvent $_;
            "CallerStation" = ExtractCallerStation $_;
            "RelatedEvents" = @();
            "LogonSessions" = @();
        }

        # Check if the source computer from the event is accessible
        if($entry.CallerStation) 
        {
            if(Test-Connection -ComputerName $entry.CallerStation `
                -Count 1 `
                -ErrorAction SilentlyContinue)
            {
                # Check for any RDP sessions for the locked out user on the source computer
                $entry.LogonSessions = Has-RDPLoginSession `
                    -Server $entry.CallerStation `
                    -User $entry.UserName
                
                # Comb for any login events by the user on the source computer.
                Write-Debug ("-- ProcessForwardedEvents() -> Current user " + $entry.Username)
                $entry.RelatedEvents += GetLoginsOnHost $entry.CallerStation $entry.UserName $_.TimeCreated
            }
        }
        else
        {
            # No caller station listed - look for RADIUS logins
            $entry.RelatedEvents += GetLoginsOnHost "RADIUS01" $entry.UserName $_.TimeCreated  
        }
        
        return $entry
    }
}

function ExtractUsernameFromEvent($Event) 
{
    $Event.Properties[0].Value
}

function ExtractCallerStation($Event)
{
    if($Event.Properties.Count -eq 7) {
        $Event.Properties[1].Value
    }
}

Write-Debug "Import the script config"
Import-ScriptConfig
 
Write-Debug "Getting lockout events and sorting by time"
$events = ProcessForwardedEvents | 
    Sort-Object Time -Desc

Write-Debug "Set the time in the config file"
if($events)
{
    Set-ConfigItem -Scope Script -Key LastProcessTime -Value $events[0].Time
}

Write-Debug "Email the events."
$events | Foreach-Object {

    $body  = "<h2>Lockout Time: " + $_.Time + "</h2>"
    $body += "<h2>Caller Station: " + $_.CallerStation + "</h2>";

    $body += "<hr>"

    if($_.LogonSessions)
    {
        $body += "Logon sessions:<br>" + $_.LogonSessions + '<hr>'
    }

    if($_.RelatedEvents) {
        $_.RelatedEvents | ForEach-Object {
            $body += "<table border='1'>"
            $body += "<tr><td>Host name</td><td>" + $_.HostName + "</td></tr>" 
            $body += "<tr><td>Event ID</td><td>" + $_.EventID + "</td></tr>"
            $body += "<tr><td>Event Time</td><td>" + $_.Time + "</td>"
            $body += "<tr><td colspan='2'><pre>" + $_.Message + "</pre></td></tr>" 
            $body += "</table>"
        }
    }

    $displayname = Get-ADUser $_.Username -Property DisplayName | 
        Select-Object -ExpandProperty DisplayName
        
    Send-MailMessage `
        -To "helpdesk@contoso.com" `
        -From "account.lockouts@contoso.com" `
        -SMTPServer "smtp.contoso.com" `
        -Subject ("Account lockout detected for $displayname (" + $_.Username + ") @ " + $_.Time) `
        -Body $body `
        -BodyAsHTML
}
