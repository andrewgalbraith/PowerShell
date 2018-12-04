# Imports any function files that might be found in ./functions
# NOTE: These are not module members, just made available globally
Get-ChildItem (Join-Path $PSScriptRoot "functions") -Filter *.ps1 |
    Foreach-Object { . $_.FullName }

$global:O365Credentials = $null

#Exchange, MSOL and O365 CMDlets

function Connect-ExchangeOnline
{     
	$session = Get-PSSession -Name "ExchangeOnline" -ErrorAction SilentlyContinue

    # Remove the session if broken
    if($session -and $session.State -eq "Broken")
    {
        Get-PSSession -Name "ExchangeOnline" | Remove-PSSession
    }

    # Create a session if one does not exist
    if(-not ($session -and $session.Availability -eq "Available"))
	{
	    # Create a new remote session O365
	    New-PSSession -Name ExchangeOnline `
            -ConfigurationName Microsoft.Exchange `
            -ConnectionUri "https://outlook.office365.com/powershell-liveid/" `
            -Credential (Get-ExchangeOnlineCredentials) `
            -Authentication Basic `
            -AllowRedirection | 
        Out-Null
	}
    
    # Import the session and associated CMDlets
    try
    {    
        
        $session = Get-PSSession -Name ExchangeOnline `
            -ErrorAction Stop

        $module = Import-PSSession $session `
            -AllowClobber `
            -DisableNameChecking `
            -ErrorAction Stop `
            -Verbose:$false

        Import-Module $module -Global `
            -DisableNameChecking `
            -ErrorAction Stop

    }
    catch
    {
        Write-Error $_.Exception.Message
    }
}

function Connect-SharepointOnline
{     
	try
	{
		# Try getting some info from sharepoint admin.
		Get-SPOTenant | New-Variable SPOTenantDetails
	}
	catch 
	{
		# Create a new remote session O365
		Connect-SPOService -URL (Get-ConfigItem Defaults.SharepointOnline.TenantAdminURL) -Credential (Get-ExchangeOnlineCredentials)
	}
}

function Connect-MSOL
{
	#Import the MSOL cmdlets
    Import-Module MSONLINE -Global

	if((Get-MSOLDomain -ErrorAction SilentlyContinue))
	{
		Write-Verbose "Already connected to MSOL. Not reconnecting"
	}
    else
    {
        # Connect to the Service
        try
        {
            Connect-MsolService -credential (Get-ExchangeOnlineCredentials)
        } 
        catch
        {
            Write-Host "ERROR: Could not connect. Check connection and credentials" -ForegroundColor Red
        }
    }
}

function Connect-SfBO {

    $Session = Get-PSSession |
        Where-Object { $_.ComputerName -like "*lync.com" -and $_.State -eq "Opened" }


    if (-not $Session) {

        try {

            Import-Module SkypeOnlineConnector -ErrorAction SilentlyContinue
    
            $Session = New-CsOnlineSession -OverrideAdminDomain "contoso.onmicrosoft.com" `
                -Credential (Get-ExchangeOnlineCredentials)
   
        } catch {
    
            Write-Error "Could not connect, message given was $($_.Exception). Ensure you've saved your credentials using menu option 1."
        
        }

    }

    $module = Get-Module "tmp*" |
        Where-Object Description -like "*lync*"

    if($module) {
        
        Write-Verbose "Session already connected and module imported."

    } else {

        Import-PSSession $Session -AllowClobber |
            Import-Module -Global

    }

}


function Connect-Hybrid 
{
    param([string]$ServerName)

    # Get the default server name to connect to if the ServerName was not given
    if(-not $ServerName)
    {
        $ServerName = Get-ConfigItem Defaults.Exchange.ConnectionServer
    }
    
    $ConnectionAddress = "http://" + $ServerName + ".contoso.com/powershell/"

    # Attempt to retrieve an existing session
    if(! (Get-PSSession -Name $ServerName -ErrorAction SilentlyContinue) )
    {
        New-PSSession -Name $ServerName `
            -ConfigurationName Microsoft.Exchange `
            -ConnectionUri $ConnectionAddress `
            -AllowRedirection `
            -Authentication Kerberos `
            -ErrorAction SilentlyContinue |
        Out-Null
    }

    try
    {    

        $session = Get-PSSession -Name $ServerName `
            -ErrorAction Stop

        $module = Import-PSSession $session `
            -AllowClobber `
            -DisableNameChecking `
            -ErrorAction Stop

        Import-Module $module -Global -DisableNameChecking -ErrorAction Stop

    }
	catch
	{
	    Write-Host "ERROR: " $_.Exception.Message -ForegroundColor Red
	}	
}


function Resolve-MailboxPermissions
{
    param($identity)

    $permissions = $null;

    Write-Host "Locating mailbox on Hybrid."

    try
    {
        Connect-Hybrid
        $users = Get-MailboxPermission $identity
        $users | ? {$_.IsInherited -eq $false -and $_.User -ne "NT AUTHORITY\SELF"}
        $permissions = $users | % {Get-Recipient $_.User}
    }
    
    catch [System.Management.Automation.RemoteException]
    {
        Write-Host "Unable to find mailbox on Hybrid, searching on O365." -BackgroundColor Yellow
    }

    if($permissions.count -eq 0)
    {
        try
        {
            Connect-ExchangeOnline
            $users = Get-MailboxPermission $identity
            $users = $users | ? {$_.IsInherited -eq $false -and $_.User -ne "NT AUTHORITY\SELF"}
            $permissions = $users | % {Get-Recipient $_.User}
        }

        catch [System.Management.Automation.RemoteException]
        {
            Write-Host "Unable to find mailbox on O365 either, are you sure it exists?" -BackgroundColor Yellow
        }
    }
    
    if($permissions.count -eq 0)
    {
        Write-Host "No explicit permissions."
    }

    else
    {
        Write-Host "Permissions, as requested: " -BackgroundColor DarkGreen
        $permissions | Sort-Object Name,RecipientType | ft
    }
}

function Convert-MailboxToShared
{
    param($MailboxIdentity)
    
    $Mailbox = Get-Mailbox $MailboxIdentity

    if($Mailbox -eq $null)
    {
        Write-Error "Mailbox not found."
    }
    else
    {
        # Check if mailbox is of type user and sets to shared if so
        if($Mailbox.RecipientTypeDetails -eq "UserMailbox")
        {
            Write-Host "Converting to Shared Mailbox"
            $Mailbox | Set-Mailbox -Type Shared
        }

        # Set the mailbox size limits
        Write-Host "Setting mailbox size limits"
        $Mailbox | Set-Mailbox -IssueWarningQuota 4.5GB -ProhibitSendQuota 4.75GB -ProhibitSendReceiveQuota 5.0GB   
    }
}

function Get-DefaultExchangeOnlineCredentials
{
    if(!$global:O365Credentials)
    {
        $username = Get-ConfigItem Automation.Username
        $password = ConvertTo-SecureString (Get-ConfigItem Automation.SecurePassword) -ErrorAction SilentlyContinue
        $global:O365Credentials = New-Object System.Management.Automation.PSCredential ($username, $password) -ErrorAction SilentlyContinue
    }

    $global:O365Credentials
}

function Get-ExchangeOnlineCredentials
{
	if(!$global:O365Credentials)
	{
    # Try stored credentials
		try
		{
			$global:O365Credentials = Get-DefaultExchangeOnlineCredentials
		}
		catch
		{
			# If no stored credentials, prompt...
			$global:O365Credentials = Get-Credential
		}
		
	}
	
	$global:O365Credentials
}

function Migrate-Mailbox
{
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $EmailAddress
    )
     
	Connect-ExchangeOnline
	  
    New-MoveRequest -identity $EmailAddress `
     -Remote `
     -RemoteHostName (Get-ConfigItem Defaults.MoveRequest.RemoteHostName) `
     -TargetDeliveryDomain (Get-ConfigItem Defaults.MoveRequest.TargetDeliveryDomain) `
     -RemoteCredential (Get-ExchangeOnlineCredentials) `
     -BadItemLimit (Get-ConfigItem Defaults.MoveRequest.BadItemLimit)
}

function Set-O365UserLicense {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$UserPrincipalName,

		[Parameter(Position=1, Mandatory=$true)]
		[ValidateNotNull()]
		[System.String]
		$LicenseCode,
		
		[Parameter(Position=2, Mandatory=$true)]
		[ValidateNotNull()]
		[System.String]
		$CountryCode
	)
    
    # Set the usage location of the use, rewrite IN to GB for legal reasons
    try {

        # India voice recording legislation thing - india users need to have 
        # usage location set to GB
        if($CountryCode -eq "IN") { $CountryCode = "GB" }
        
        # Ensure a session with Azure AD is present
        Connect-MSOL

        # Update th usage location of the user in Azure AD.
        Set-MsolUser -UserPrincipalName $UserPrincipalName -UsageLocation $CountryCode

    }
    catch {

        throw "Unable to set usage location. Country code was $CountryCode. Ensure a valid usage location is supplied and that a session can be established with MSOL PowerShell (try Connect-MSOL to confirm)."

    }
        
    try {

        # Get the license SKU from the config
        (Get-ConfigItem ("Office365.Licensing." + $LicenseCode)) |
            New-Variable License
        
        # Extract the samAccountName from the UPN
        $samAccountName = ($UserPrincipalName -split '@')[0]

        # Add the user to the license group, according to the plan given.
        Add-AdGroupMember -Identity $License -Members $samAccountName -ErrorAction Stop

    }
    catch {

        throw "Could not add user to license group. Group name was $License. Ensure a valid plan name was provided and that the plan name matches a valid plan in the config. Try runing Get-Config | Where name -like `"Office365.Licensing.*`" to see the plan -> AD group mappings and update if necessary." 
   
    }
}
function Set-SharedMailboxPermissions
{
    param($mailbox, $group)

    Connect-ExchangeOnline

    # Give the SMG permissions on the mailbox
    Add-MailboxPermission $mailbox -User $group -AccessRights FullAccess -InheritanceType All
    
    # Set a resource delegate if it's a resource mailbox
    if($mailbox.RecipientTypeDetails -eq "RoomMailbox" -or $mailbox.RecipientTypeDetails -eq "EquipmentMailbox")
    {
        # Set the SMG as a delegate on the mailbox
        $delegates = (Get-CalendarProcessing $mailbox).ResourceDelegates
        $delegates.Add($group)
        Set-CalendarProcessing $mailbox -ResourceDelegates $delegates
    }
}

function Has-SharedMailboxGroup
{
    param($mailbox)

    Connect-ExchangeOnline

    [bool](Get-MailboxPermission $mailbox.Identity | ? {$_.User -like "*SMG_*" })
}

function Set-ResourceCalendarPermissions 
{ 
    param($ResourceCP)

    # Generate identity for calendar folder
    $calendar = ($ResourceCP + ":\Calendar")

    # Set Calendar permissions for Default and Anonymous permission entries
    Set-MailboxFolderPermission -Identity $calendar -User Default -AccessRights LimitedDetails
    Set-MailboxFolderPermission -Identity $calendar -User Anonymous -AccessRights None

    # Ensure all delegates are Calendar owners
    $ResourceCP.ResourceDelegates | 
        Foreach-Object {
            # One or the other will work, depending on whether ther is already an existing permission entry
            Set-MailboxFolderPermission -Identity $calendar -User $_ -AccessRights Editor -WarningAction SilentlyContinue
            Add-MailboxFolderPermission -Identity $calendar -User $_ -AccessRights Editor -WarningAction SilentlyContinue
        } 
}

function Set-ResourceDesiredConfiguration
{
    param($ResourceCP)
    <# 
        Notes: 
         - AllBookInPolicy defaults to $true (general preference), so any set to 
            $false are like that for a reason.
         - AllRequestOutOfPolicy as above, but defaults to $false.
         - If BookingWindow is still at default (180), then it will be set to 365.
    #>
    $resource_settings = @{
        Identity = $ResourceCP
        AutomateProcessing = "AutoAccept"
        RemovePrivateProperty = $true
        AddOrganizerToSubject = $true
        DeleteSubject = $true
        DeleteAttachments = $true
        ForwardRequestsToDelegates = $true
        OrganizerInfo = $true
        RemoveForwardedMeetingNotifications = $true
        RemoveOldMeetingMessages = $true
        TentativePendingApproval = $true
        AddNewRequestsTentatively = $true
        AllRequestInPolicy = $true
        MaximumConflictInstances = 5
        ConflictPercentageAllowed = 100
    }
    # Set BookingWindow to 365 days only if it is currently at default of 180
    if($ResourceCP.BookingWindowInDays -eq 180) 
    {
       $resource_settings["BookingWindowInDays"] = 365; 
    }

    # Apply the standard property configuration
    Set-CalendarProcessing @resource_settings

}

Export-ModuleMember -Function *
