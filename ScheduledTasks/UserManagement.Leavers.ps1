<#
.SYNOPSIS
    Automates the leaver process: manager access, notification email, and deletion after retention.

.DESCRIPTION
    Watches the Leavers OU. New leavers get their manager granted access to their mailbox, home drive and
    profile, and the manager is emailed a templated notice. Accounts are deleted a month after leaving
    (or a month after their retain date). State is kept in a per-script config file.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

$1_month_ago = (Get-Date).AddMonths(-1)

# Read the config file
function ReadList {
	Import-ScriptConfig
	$global:leavers_list = Get-ConfigItem Leavers
}

# Save changes to leavers list
function SaveList {
	Set-ConfigItem -Key Leavers -Value $global:leavers_list -Scope "Script"
}

# Determines the logic for deciding whether a user is ready to be removed
function Process-Leaver
{
	param($leaver)
	
	if($leaver.RetainDate)
	{
		if($leaver.RetainDate -lt $1_month_ago)
		{
			Write-Host ("Retain Date expired for: " + $leaver.samAccountName)
			Remove-Leaver $leaver
		}
	}
	else
	{
		if($leaver.LeaveDate -lt $1_month_ago)
		{
			Write-Host ("Leave Date expired for: " + $leaver.samAccountName)
			Remove-Leaver $leaver
 		}
	}
}

# Remove the leaver from the list and delete the user account
function Remove-Leaver
{
	param($leaver)
	Write-Host ("Removing Leaver: " + $leaver.samAccountName)
	Remove-ADUser $leaver.samAccountName -Confirm:$false
	$global:leavers_list = $global:leavers_list | 
		Where-Object {$_.samAccountName -ne $leaver.samAccountName}
}

# Add a new leaver to the list and perform the following actions:
# - Give the manager full access to the user's mailbox
# - Give the manager permissions to the user's home drive and profile
# - Email the manager using the standard template
function New-Leaver
{
	param($user)
	
	Write-Host ("Adding New Leaver: " + $user.samAccountName)
	
	$entry = [psCustomObject]@{
		"samAccountName" = $user.samAccountName;
		"LeaveDate" = (Get-Date);
		"RetainDate" = ""
	}

	if($global:leavers_list) {
		$global:leavers_list = @($global:leavers_list) + @($entry)
	} else {
		$global:leavers_list = @($entry)
	}

    # Get the manager's details
	$manager = (Get-ADUser $user.Manager -Properties mail)
	# Give the manager permissions on the User's file storage
	Add-ManagerFilesystemPermissions -User $user -Manager $manager
 	# Establish a remote shell session with Exchange Online	
	Connect-ExchangeOnline
	# Give the manager permissions on the mailbox
	Add-MailboxPermission $user.mail -User $Manager.mail -AccessRights FullAccess -AutoMapping:$true
	# Email the notification to the manager
	Email-Manager $user
}

function Email-Manager
{
	param($user)
	
	$manager_recipient = ""
	$manager_name = ""
	
  if($user.Manager)
	{
		$manager_obj = Get-ADUser $user.Manager -Properties mail,givenName
		$manager_recipient = $manager_obj.mail
		# $manager_recipient = "it.admin@contoso.com"
		$manager_name = $manager_obj.givenName
	}
	else
	{
		$manager_recipient = (Get-ConfigItem Defaults.SMTP.FromAddress)
		# $manager_recipient = "it.admin@contoso.com"
		$manager_name = (Get-ConfigItem UserManagement.LeaverEmailName)
	}
	
  $v2path = ($user.ProfilePath + ".v2")
	$RoamingProfileText = ""

    if(Test-Path $v2path)
    {
			$RoamingProfileText = $v2path
    } 
    else
    {
			if($user.ProfilePath)
			{
				$RoamingProfileText = $user.ProfilePath
			}
			else
			{
				$RoamingProfileText = "Not Applicable"
			}
    }

    $RedirectionGroupName = ($user.MemberOf | ? { $_.Contains("FOLDER_REDIRECTION") } | Get-ADGroup).Name
    
    $MyDocsPath = (Locate-FolderRedirectionPath $RedirectionGroupName).Replace("%USERNAME%", $user.samAccountName)
    $MyDocsText = ""
    if($MyDocsPath) 
      { $MyDocsText = $MyDocsPath } 
    else
      { $MyDocsText = "Not Applicable" }

    $HomeDriveText = ""
    if($user.HomeDirectory)
      { $HomeDriveText = $user.HomeDirectory }
    else
      { $HomeDriveText = "Not Applicable" }

	$body = Merge-Tokens ((Get-Content (Get-ConfigItem UserManagement.LeaverEmailBody)) | Out-String) `
		@{
			"manager" = $manager_name;
			"leaver" = $user.GivenName;
			"HomeDrivePath" = $user.HomeDirectory;
			"RoamingProfilePath" = $RoamingProfileText;
			"MyDocsPath" = $MyDocsText;                                    
    }
	
	Send-MailMessage -To $manager_recipient `
		-From (Get-ConfigItem Defaults.SMTP.FromAddress) `
		-Subject ("URGENT: Removal of user-related data for " + $user.displayName) `
		-Body $body `
		-BodyAsHtml `
		-SmtpServer (Get-ConfigItem Defaults.SMTP.ServerAddress)
}

function Locate-FolderRedirectionPath
{
	param($GroupName)

	((Get-GPO -Guid 00000000-0000-0000-0000-000000000000).GenerateReport("XML") | 
		Select-XML -Namespace @{redirect="http://www.microsoft.com/GroupPolicy/Settings/FolderRedirection"} -XPath "//redirect:Folder" | 
		% { $_.Node.Location } |
		? { $_.SecurityGroup.Name."#text" -eq "CONTOSO\$GroupName" }).DestinationPath
}

function Add-ManagerFilesystemPermissions
{
	param($user, $manager)
	
	if($Manager)
	{
		# Give the manager permissions to the user's home drive
		if($user.HomeDirectory)
		{
			Write-Host "Changing permissions on Home Directory"
			Write-Host "Folder is: " $user.HomeDirectory
			
			TakeFolderOwnership $user.HomeDirectory "CONTOSO\DRS_GB_OPS_PRIVATE_FILE_OWNER"
			Add-FolderPermission $user.HomeDirectory $manager.samAccountName
		}
		
		# Give the manager permissions to the user's profile
		if($user.ProfilePath)
		{
			$v2path = ($user.ProfilePath + ".v2")

			if(Test-Path $user.ProfilePath)
			{
				Write-Host "Changing permissions on Profile"
				Write-Host "Folder is: " $user.ProfilePath

				TakeFolderOwnership $user.ProfilePath "CONTOSO\DRS_GB_OPS_PRIVATE_FILE_OWNER" 
				Add-FolderPermission $user.ProfilePath $manager.samAccountName
			}
			if(Test-Path $v2path)
			{
				Write-Host "Changing permissions on Profile V2"
				Write-Host "Folder is: " $v2path
				
				TakeFolderOwnership $v2path "CONTOSO\DRS_GB_OPS_PRIVATE_FILE_OWNER"
				Add-FolderPermission $v2path $manager.samAccountName
			}
		}
	}
}

# Monitor Leavers OU

# Get a list of users currently in the leavers OU or retained_leavers OU.
try {
	$leavers = Get-ADUser -Filter * `
		-SearchBase "OU=Leavers,OU=Accounts (Users),OU=Operations,DC=contoso,DC=com" `
		-SearchScope Subtree `
		-Properties * | ? { -not ($_.DistinguishedName -like "*Do not delete*") }

	# Import the list of already processed leavers
	ReadList
}
catch {
	throw "Could not collect required information to process users."
}

# Process leavers
$leavers | % {
	
	$existing_accounts = $global:leavers_list | 
		Foreach-Object -MemberName samAccountName
	
	# Determine if leaver already exists
	if($existing_accounts -contains $_.samAccountName)
	{	
		# Get the leaver from the CSV
		$leaver = $global:leavers_list[$existing_accounts.indexOf($_.samAccountName)]
		
		# If the leaver is retained, make sure the retain date is set
		if(($_.distinguishedName.Contains("Retained_Leavers")) -and
			(-not $leaver.RetainDate))
		{
			Write-Host ("Setting retain date for: " + $leaver.samAccountName)
			$leaver.RetainDate = (Get-Date)
		}
		
		# Process any actions for the leaver
		Process-Leaver $leaver
	}
	else
	{
		# Add the leaver to the list
		New-Leaver $_
	}

    # Clean up XML file for accounts not in $leavers e.g. ones that have been moved
    # out of scope since being processed
    $global:leavers_list = $global:leavers_list | 
        Where-Object { 
            $_.samAccountName -in ($leavers | Select -ExpandProperty samAccountName) 
        }
    
    # Save the list
	SaveList
}
