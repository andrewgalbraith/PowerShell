. ($PSScriptRoot + "\Automation.Workflow.New-UserWithMailbox.Commands.ps1")

function New-UserWithMailbox
{     
    # Create a new object with the required properties
    $object = New-Object -TypeName PSCustomObject -Property @{ `
        "State" = "Initial";
        "Forename" = "";
        "Surname" = "";
        "EmployeeID" = "";
        "CountryCode" = "";
        "SiteCode" = "";
		"Requester" = "";
        "Creator" = "";
		"Increment" = "";
		"LicenseCode" = "";
		"WelcomeEmailSent" = $false;
		"RequesterEmailSent" = $false;
        "AccountDisabled" = $false;
		"Password" = "";
		"LoggedIn" = $false;
        "CallReference" = "";
    }

    # Adds a UserID property which is dynamically generated from NoteProperties
    $object | Add-Member -MemberType ScriptProperty -Name UserID -Value `
    {
        ($this.Forename[0] + $this.Surname[0] + $this.EmployeeID).ToLower()
    }

    # Adds a DisplayName property which is dynamically generated from NoteProperties
    $object | Add-Member -MemberType ScriptProperty -Name DisplayName -Value `
    {
        ($this.Forename + " " + $this.Surname)
    }
    
	# Adds a ADName property which is dynamically generated from NoteProperties
    $object | Add-Member -MemberType ScriptProperty -Name ADName -Value `
    {	
		($this.Forename + " " + $this.Surname + $this.increment)
    }
    
    # Adds an alias property which is dynamically generated from NoteProperties
    $object | Add-Member -MemberType ScriptProperty -Name Alias -Value `
    {    
		$surname = $this.surname.replace(" ","").replace("'","")
        $firstname = $this.forename.replace(" ","")
		
		($firstname + "." + $surname + $this.increment)
    }

    # Adds a UPN property which is dynamically generated from NoteProperties
    $object | Add-Member -MemberType ScriptProperty -Name UserPrincipalName -Value `
    {
        ($this.UserID + "@" + (Get-ConfigItem Defaults.Mailbox.UPNSuffix))
    }
	
	# Adds an EmailAddress attribute which is dynamically generated from other 
	# properties
	$object | Add-Member -MemberType ScriptProperty -Name EmailAddress -Value `
    {
        ($this.Alias + "@" + (Get-ConfigItem Defaults.Mailbox.UPNSuffix))
    }

    # Adds a unique property definition
    $object | Add-Member -MemberType ScriptProperty -Name UniqueName -Value `
    {
        $this.UserID
    }

        $object | Add-Member -MemberType ScriptProperty -Name InstanceName -Value `
    {
        $this.UserID
    }

    # Allows an object to be initialised with data from a PSCustomObject or Hash
    # e.g. data from Import-CliXML
    $object | Add-Member -MemberType ScriptMethod -Name Initialise -Value {
        param([psCustomObject]$Properties)
        $this.psobject.properties | 
            Where-Object {$_.MemberType -eq "NoteProperty"} | 
            ForEach-Object `
            {    
                if($Properties.($_.Name))
                {
                    $_.Value = $Properties.($_.Name)
                }
            }
        return $this
    }

    $object | Add-Member -MemberType ScriptMethod -Name Process -Value `
    {

	    Write-Verbose ("Processing user: " + $this.DisplayName + " ("  + $this.UserID + ")")
	    Write-Verbose ("State this iteration: " + $this.State)

        switch($this.State)
        {
            ("Initial")
            {
                Connect-Hybrid
			    $mailbox = $null
			    $user = Get-User $this.UserPrincipalName
			
			    if($user.RecipientTypeDetails -eq "User" -or $user.RecipientTypeDetails -eq "DisabledUser")
			    {
				    if($user.OrganizationalUnit -match "Staging$")
				    {
					    Write-Verbose "Enabling mailbox for staged user"
					    $mailbox = Enable-UserMailbox $this -SetFirstLoginInfo
				    }
				    else
				    {
					    Write-Verbose "Enabling mailbox for existing user"
					    $this.LoggedIn = $true;
						$mailbox = Enable-UserMailbox $this
				    }
			    }
			    else
			    {
				    Write-Verbose "Creating mailbox for new user"
				    $mailbox = Create-UserMailbox $this
			    }
			
			    if($mailbox)
			    {
                    
                    # Pause briefly to await local AD replication
                    Start-Sleep -Seconds 30

                    # Update Skype for Business attributes
                    SetSfBOAttributes -samAccountName $this.UserID `
                        -EmailAddress $this.EmailAddress
                    
                    # License the user
                    Write-Verbose "Licensing User"
                    Set-O365UserLicense -UserPrincipalName $this.UserPrincipalName `
                        -LicenseCode $this.LicenseCode `
                        -CountryCode $this.CountryCode
    
				    $this.State = "MailboxRequested"
			    }
                continue            
            }

            ("MailboxRequested")
            {		
                Write-Verbose "Mailbox Created, preparing account"
				
                # Set up the new user's home drive
			    Set-HomeDrive -User $this.UserID -CountryCode $this.CountryCode -SiteCode $this.SiteCode
                
			    # Set up the new user's profile - NO LONGER USING ROAMING PROFILES
                # Set-RoamingProfile -User $this.UserID -CountryCode $this.CountryCode -SiteCode $this.SiteCode
                
                # Set the user's login script path
			    Set-ADUser $this.UserID -ScriptPath "login.bat"
                
                # Add the basic internet access group
                try {
                    Add-ADGroupMember "GRS_INTERNET_ACCESS_ZSCALER_BASIC_INTERNET_ACCESS_PRIVILEGES" `
                        -Members $this.UserID `
                        -ErrorAction Stop
                } catch {
                    if(-not ($_.Exception -like "*already a member*"))
                    {
                        throw $_
                    }
                }
                
                
                # Add the MDM group
                try {
                    Add-ADGroupMember "GRS_OPS_INTUNE_USERS" `
                        -Members $this.UserID `
                        -ErrorAction Stop
                } catch {
                    if(-not ($_.Exception -like "*already a member*"))
                    {
                        throw $_
                    }
                }

                # Add the MFA group  
                try {
                    Add-ADGroupMember "GRS_OPS_MFA_Register" `
                        -Members $this.UserID `
                        -ErrorAction Stop
                } catch {
                    if(-not ($_.Exception -like "*already a member*"))
                    {
                        throw $_
                    }
                }

                # Add the OneDrive group
                try {
                    Add-ADGroupMember "GGP_OneDrive_test" `
                        -Members $this.UserID `
                        -ErrorAction Stop
                } catch {
                    if(-not ($_.Exception -like "*already a member*"))
                    {
                        throw $_
                    }
                }
			    
                # Disable the account if this is a new user (never logged in)
			    if(!(Get-ADUser $this.UserID -Properties lastLogonTimestamp).lastLogonTimestamp) { 
                    Disable-ADAccount $this.UserID
                    $this.AccountDisabled = $true
                }
    		
                # See if the user has been synchronised to the cloud
                Connect-ExchangeOnline
                $User = Get-User $this.UserPrincipalName -ErrorAction SilentlyContinue
            
				# If it has, move to the next stage
                if($User.RecipientTypeDetails -eq "UserMailbox")
                {
					$this.State = "MailboxCreated"
			    }
			    else
			    {
				    Write-Verbose "Not ready to move to next stage"
			    }

                continue
            }
		
            ("MailboxCreated")
            {

                # Send welcome email to the user
			    if(!$this.WelcomeEmailSent)
			    {
				    $result = Send-WelcomeEmail $this.Forename $this.EmailAddress
				    if($result) { $this.WelcomeEmailSent = $true }
			    }

			    # Send email to person who requested account
			    if(!$this.RequesterEmailSent) {
				    Write-Verbose "Emailing Requester"
                    
                    Connect-Hybrid

				    $requester = Get-User $this.Requester
                    $result = Send-RequesterWelcomeEmail $this $requester
				    Write-Verbose "Send requester email result is $result"	
				    if($result) { 
                        $this.RequesterEmailSent = $true 
                        $this.State = "Complete"
                    }
			    }
			    continue
            }
        }

        # Save any changes to the workflow object.
        Save-WorkflowObject $this "New-UserWithMailbox"
    }

    #Return only the new object
    $object
}
