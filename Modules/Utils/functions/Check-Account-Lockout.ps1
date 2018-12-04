<#
.SYNOPSIS
  Check Account Lockout Tool.
.DESCRIPTION
  Check for account lockout and grab logs for user to check and find the problem with the account lockout

.EXAMPLE
  # Get account lockout information for this user
  Check-AccountLockout -userID $username
.EXAMPLE
  # Get account lockout information and unlocks the account if locked
  Check-AccountLockout -userID $username -Unlock
.EXAMPLE
  # Get user lockout information, unlock it and run advance logs on the account lockout
  Check-AccountLockout -userID $username -Unlock -Advanced
.EXAMPLE
  # Wait for account to lockout and then get the account lockout information
  Check-AccountLockout -userID $username -WaitForLockout -Unlock -Advanced

.PARAMETER username
  User id for the account which is lockout
.PARAMETER Iterations
  number of time the account script loop throughs the AD
.PARAMETER WaitForLockout
  Wait for account lockout before running any logs
.PARAMETER Advanced
  Run EventCombMT to grab logs and copy Netlogon logs from all server
.PARAMETER Unlock
  This will unlock the account if locked

#>

function Message-Show
{
    param ( $message );
    Write-Host $message -ForegroundColor White
}

function Message-Error
{
    param ( $message );
    Write-Host $message -ForegroundColor DarkRed
}

function Message-Success
{
    param ( $message );
    Write-Host $message -ForegroundColor DarkGreen
}

function User-Input
{
    param ( $message );
    $input = Read-Host $message
    return $input;
}


function Has-Account-lockout
<#
    Check for event log with evet id 4740 with user id
#>
{
    param ( [string]$userID, [string]$serverName );
    $event = Get-WinEvent -ComputerName $serverName -FilterHashtable @{LogName='Security';Id=4740;data=$userID} -ErrorAction SilentlyContinue
    return $event;
}

function Get-Domain-Controller
<#
    Collect DC names but only the 2008 or above
    - able to ping them
    - must be 64 bit version

    Saves list for later so that it doesn't have to be genrated every time.
#>
{
    param($OutputPath)

    Message-Show "Get list of all Domain controller within Domain"; 

    $global:DC=@()

    #$scriptpath = $MyInvocation.MyCommand.Path
    #$scriptPath = Split-Path $scriptpath

    $DC_file = "$OutputPath\DC.txt";
    
    # Checks to see if DC file exists or 7 days have passed since list was written. If so, updates it.
    if(!(Test-Path -Path $DC_file) -or `
        (Get-ChildItem $DC_file).LastWriteTime -ge (Get-Date).AddDays(7))
    {
        # Prepare array for GB and ROW servers
        $GB=@()
        $ROW=@()
        
        # Get domain controllers 2008 R2 and above. Assumes we have no 2008.
        Get-ADDomainController -Filter {OperatingSystemVersion -like "6*" } |
            % {
                # Check the domain controller is up.
                if(Ping-Machine $_.Name)
                {
                    # Add to either GB or ROW list based on hostname
                    if($_.Name.StartsWith("GB"))
                    {
                        $GB += @($_.Name)
                    }
                    else
                    {
                        $ROW += @($_.Name)
                    }
                }
            }
        # Sort lists and append ROW servers to GB server list
        $ROW = $ROW | Sort-Object
        $GB = $GB | Sort-Object
        $DC = $GB + $ROW;
        # Save the list to a local file
        $DC | Out-File -FilePath "$OutputPath\DC.txt" -Force
    }
    else
    {
        # Get the DC list from file
        $DC = Get-Content($DC_file)
    }

    Message-Success "Finish collecting DC info"
    return $DC
}

function Ping-Machine 
<#
    Ping machine to see if it is turned on
#>
{
    param ([string]$serverName="127.0.0.1");
    
    Test-Connection -ComputerName $serverName -Quiet -Count 1;
}

function Create-Folders
<#
    Check and see if the folder exist and if not then create one
#>
{
    param ( [string]$userID, $OutputPath );
    $path = "$OutputPath\$userID\";
    if( !(Test-Path $path)  ) 
        { New-Item -ItemType directory -Path $path | Out-Null }
}

Function Get-Event
<#
    The event log which was run return we need to get the information from this event log for the user id
#>
{
    # Require $event to be set and not null or empty
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $event
    )
    
    $event | 
        Select-Object -Property `
            @(
                @{
                    Label = 'User'; 
                    Expression = { $_.Properties[0].Value }
                },
                @{
                    Label = 'DomainController';
                    Expression = { $_.MachineName }
                },
                @{
                    Label = 'LockedOutTimeStamp';
                    Expression = { $_.TimeCreated }
                },
                @{
                    Label = 'Message';
                    Expression = { $_.Message }
                },
                @{
                    Label = 'Account Lockout from'; 
                    Expression = { 
                        if($_.Properties[1].Value -eq "")
                        {
                            "Account locked out by a Smart device e.g. iPhone, ipad. This smart device could be personal or company owned."
                        }
                        else 
                        {
                            $_.Properties[1].Value
                        }
                    }
                }
            )
}


function Run-EventCombMT-Log
<#
    Run the EventCombMT program to collect logs from the event logs and save into folder for later viewing

    - Run EventCombMT
    - Rename EventCombMT log file
#>
{
    param ( $userID, $serverName, $OutputPath );
    $path = "$OutputPath\$userID";
    $DateFormat = (Get-Date).ToString("d-MM-yyyy-hms")
    Message-Show "Starting eventcombMT"

    #& "$scriptpath\eventcombMT.exe" /s:$serverName /et:safa /log:sec /text:$userID /outdir:$path /evt:4740 /t:100 /start | 
    #    Wait-Process
    
    & "eventcombMT.exe" /s:$serverName /et:safa /log:sec /text:$userID /outdir:$path /evt:4740 /t:100 /start | 
        Wait-Process

    Rename-Item "$path\$serverName-Security_LOG.txt" "$serverName-$DateFormat-Security_LOG.txt"
    Message-Success "eventcomMT finish scanning and file has been renamed"
    Message-Show "Please find the logs files:  $path "
}

function Copy-Netlogon-Log
<#
    Copy netlogon logs from server
    - test netlogon path
    - copy netlogon
#>
{
    param ( $userID, $serverName, $OutputPath );
    Message-Show "Starting Netlogon copy";
    $path = "$OutputPath\$userID";
    $DateFormat = (Get-Date).ToString("d-MM-yyyy-hms");
    $netlogon = "\\$serverName\admin`$\debug\netlogon.log";
    
    # Check to see if netlogon file exisited
    if ((Test-Path -Path $netlogon) -and ((Get-Item -Path $netlogon).Length -ne $null))
    {
        # check to see if the file is not empty
        if ((Get-Content -Path $netlogon | Measure-Object -Line).lines -gt 0)
        {
            # Check if file has been written today.
            if( (Get-ChildItem $netlogon).LastWriteTime.ToString("ddMMyy") -eq [datetime]::Today.ToString("ddMMyy") )
            { 
                Create-Folders $userID $OutputPath; sleep 1;
                Copy-Item -Path $netlogon -Destination $path\$($serverName)-$DateFormat-netlogon.log 
                Message-Success "Netlogon file has been copied from $serverName"
            }
        }
    }
}

function Check-AccountLockout 
<#
    Check for account lockout
    
    - Check account in AD
    - Check to see if the account is lockout
    - If requested
        Go through each DC and see if the account lockout event existed on that DC. 
        if yes then run EventCombMT and copy netlogon log
    - if requested then unlock out
#>
{    
    param(
        $userID, 
        $Iterations = 1, 
        [switch]$WaitForLockout, 
        [switch]$Advanced,
        [switch]$Unlock,
        $OutputPath
    )

    if( !(Test-Path $OutputPath)  ) { New-Item -ItemType directory -Path $OutputPath; }

    $user = Get-ADUser -Identity $userID -Properties LockedOut -ErrorAction SilentlyContinue

    1..$Iterations | % {
        # Wait for account to lock out?
        while($WaitForLockout -and -not $user.LockedOut)
        {
            Sleep -Seconds 120;
        }

        if($user)
        {
            Get-Domain-Controller -OutputPath $OutputPath | % {
                Write-Host "Checking account on $_"
                $event = Has-Account-lockout $userID $_;
                if($event)
                {
                    Get-Event $event
                    if($Advanced)
                    {
                        Run-EventCombMT-Log $userID $_ $OutputPath;
                        Copy-Netlogon-Log $userID $_ $OutputPath;
                    }
                }
                else
                {
                    Message-Show "Account not lockout on $_"
                }
            }
        }

        if($user.LockedOut -and $Unlock)
        {
            Unlock-ADAccount -Identity $userID
            Message-Success "Account has been unlocked"
        }
    }
}
