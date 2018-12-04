<#
.SYNOPSIS
    Checks a Windows host for to see if a user has a login session
.DESCRIPTION
    Given a username and server name, checks whether a terminal services
    session exists on that server with the given username.  Makes use of the
    legacy "query session" command.
.PARAMETER User
    The username for which RDP sessions should be checked
.PARAMETER Server
    The name of the server to query
.EXAMPLE
    Has-RDPLoginSession -Server servername -User username
#>
function Has-RDPLoginSession
{
    param(
        [parameter(Mandatory=$true)]
        [string]
        $Server,
        [parameter(Mandatory=$true)]
        [string]
        $User
    )

    if(Test-Connection $server -Count 1 -ErrorAction SilentlyContinue) 
    { 
        (iex ("qwinsta /server:$server")) -like "*$user*"
    }
}
