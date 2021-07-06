function Send-WelcomeEmail
{
	param($name, $emailaddress)
	
	$body = Merge-Tokens `
		(Get-Content (Get-ConfigItem UserManagement.NewStarterEmailBody)) `
		@{name = $name} | Out-String
	
	Send-MailMessage `
		-From (Get-ConfigItem Defaults.SMTP.FromAddress) `
		-To $emailaddress `
		-SmtpServer (Get-ConfigItem Defaults.SMTP.ServerAddress) `
		-Subject (Get-ConfigItem UserManagement.NewStarterEmailSubject) `
		-Body $body `
		-BodyAsHtml -ErrorVariable WelcomeEmailErrors
	
	if($WelcomeEmailErrors) { $false }
	else { $true }
}

function Send-RequesterWelcomeEmail
{
	# param($user_fullname,$user_id,$password,$requester_email,$requester_forename,$creator)
	# param($user_fullname,$user_id,$requester_email,$requester_forename,$creator)
	param($workflow, $requester)
	
	Connect-Hybrid
	$cc = @((Get-User $this.Creator).WindowsEmailAddress)
		
	$body = Merge-Tokens `
		(Get-Content (Get-ConfigItem UserManagement.NewStarterRequesterEmailBody)) `
		@{
			requesterforename = $requester.Forename;
			userfullname = $workflow.DisplayName;
			userid = $workflow.UserPrincipalName;
			password = $workflow.password
		} | Out-String
	
	$subject = "New User Account for " + $workflow.DisplayName
	if($workflow.CallReference)
	{
		$subject = "[" + $workflow.CallReference + "] " + $subject 
	}
	
	# Write-Host $requester.WindowsEmailAddress
	
	Send-MailMessage `
		-From (Get-ConfigItem Defaults.SMTP.FromAddress) `
		-To $requester.WindowsEmailAddress `
        -Cc $cc `
		-SmtpServer (Get-ConfigItem Defaults.SMTP.ServerAddress) `
		-Subject $subject `
		-Body $body `
		-BodyAsHtml `
		-ErrorVariable RequesterEmailErrors
	
	if($RequesterEmailErrors) { $false }
	else { $true }
}

function Create-UserMailbox
{
    param($object)
    
    Connect-Hybrid

    $OUName = Get-RegionSpecificData -Type OrganisationalUnit -CountryCode $object.CountryCode -SiteCode $object.SiteCode
    $OU = (Get-ConfigItem Defaults.Users.OrganisationalUnit) + $OUName
	
    $password = ConvertTo-SecureString -String $object.Password -AsPlainText -Force  
	#$password = ConvertTo-SecureString -String (Get-ConfigItem Defaults.Users.InitialPassword) -AsPlainText -Force  
	
	New-RemoteMailbox -UserPrincipalName $object.UserPrincipalName `
		-FirstName $object.Forename `
		-LastName $object.Surname `
		-Name $object.ADName `
		-DisplayName $object.DisplayName `
		-SamAccountName $object.UserId `
		-OnPremisesOrganizationalUnit $OU `
		-Alias $object.Alias `
		-Password $password `
		-ResetPasswordOnNextLogon $true `
		-ErrorAction Stop
}

function Enable-UserMailbox
{
    param($object, [switch]$SetFirstLoginInfo)
	
	Connect-Hybrid
	
	$OUName = Get-RegionSpecificData -Type OrganisationalUnit -CountryCode $object.CountryCode -SiteCode $object.SiteCode
    $OU_Identity = (Get-OrganizationalUnit((Get-ConfigItem Defaults.Users.OrganisationalUnit) + $OUName)).DistinguishedName
	$User_Identity = (Get-User $object.UserPrincipalName).DistinguishedName
	
	Import-Module ActiveDirectory
	
	if($SetFirstLoginInfo)
	{
    	# Password as Secure String
		$password = ConvertTo-SecureString -String $object.Password -AsPlainText -Force
		#$password = ConvertTo-SecureString -String (Get-ConfigItem Defaults.Users.InitialPassword) -AsPlainText -Force
		Set-ADAccountPassword -Identity $User_Identity -NewPassword $password -Reset
		# Require that a user use a password to logon
		Set-ADAccountControl -Identity $User_Identity -PasswordNotRequired $False
		# Require user to change password at first logon
		Set-ADUser -Identity $User_Identity -ChangePasswordAtLogon $true
	}

	Move-ADObject -Identity $User_Identity -TargetPath $OU_Identity
	
	$routing_address = $object.UserID + "@" + (Get-ConfigItem Defaults.MoveRequest.TargetDeliveryDomain)
	Enable-RemoteMailbox -Identity $object.UserPrincipalName `
		-Alias $object.Alias `
		-RemoteRoutingAddress $routing_address
}

function SetSfBOAttributes {

	param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$true)]
		[String]
		$samAccountName,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$true)]
		[String]
		$EmailAddress
	)

	# Prepare the properties to be set
	$properties = @{
		"msRTCSIP-PrimaryUserAddress" = "sip:$EmailAddress";
		"msRTCSIP-DeploymentLocator" = "sipfed.online.lync.com";
	}

	# Add the new property values
	Set-ADUser -Identity $samAccountName -Add $properties -ErrorAction Stop

}

function Get-NextUserNameIncrement ([String]$FirstName, [String]$Surname) {
                        
    # Find any existing users with the same name SORTED, and select the last item
    $user = Get-ADUser -Filter {GivenName -eq $FirstName -and Surname -eq $Surname} `
		-ErrorAction SilentlyContinue |
			Sort-Object Name | Select-Object -Last 1

    # If an existing user was found, calculate the next numeric value, starting 
	# from 2. Otherwise, return $null.
    if($user)
	{
		switch (([int]([regex]::match($user.Name,'\d+$').Value)))
	    {
		    0 { 2 } 
		    default { ($_ + 1) }
	    }   
    }
	else { $null }
}
