### Steps required to create a new workflow ###
# These can be found in detail where they should be changed:
# 0. Save this file as Automation.Workflow.<Workflow-Name>.ps1
# 1. Rename function
# 2. Define any variables required for the workflow
# 3. Define the "Initial" stage function.
# 4. Save the state of the workflow instance and ensure next stage is processed.
# 5. Define functions for other stages.
# 6. Ensure there is a stage which puts the workflow into the "Complete" state

# To use the new workflow:
# Just creates an instance
# > (Example-Workflow "Usage example 1")
# or, to intialise a workflow variable as well
# > (Example-Workflow "Usage Example 2").Initialse(@{"MailSent" = $true})
# or, as above, but additionally save the workflow
# > (Example-Workflow "Usage Example 3").Initialse(@{"MailSent" = $true}).Save()
# or, just create an instance and save it in its default state
# > (Example-Workflow "Usage Example 4").Save()

# --> 1. Rename this function.
# Provide a descriptive name for your workflow, for example "New-UserWithMailbox"
function NewResourceMailbox {
    param($InstanceName)
    # Create an instance of the template workflow
    # This gives us back an object with methods and properties required for the workflow.
    $workflow = Workflow-Template $InstanceName
    
    # Ensure the workflow has the correct name
    $workflow | Add-Member -MemberType NoteProperty -Name WorkflowName -Value $MyInvocation.MyCommand.ToString() -Force
    
    # --> 2. Define and initialise any workflow variables required
    $workflow.SetVariable("DisplayName","")
	$workflow.SetVariable("Requester","")
    $workflow.SetVariable("Creator","")
    $workflow.SetVariable("CountryCode","")
    $workflow.SetVariable("SiteCode","")
	$workflow.SetVariable("RequesterEmailSent",$false)
    $workflow.SetVariable("Alias","")
    $workflow.SetVariable("GroupName","")
    $workflow.SetVariable("Type","");
    $workflow.SetVariable("CallReference","")
    
    # --> 3. Define the "Initial" stage function. 
    # This is the function which is invoked when the workflow first runs
    # We are customizing the template by adding members to it, but whis existed in the 
    # template so we should use -Force to overwrite.
    $workflow | Add-Member -MemberType ScriptMethod -Name Initial -Value {
        # Determine name of shared mailbox group and the mailbox alias
        $this.Alias = $this.DisplayName -replace "#|-|\s","_"
        $this.GroupName = ("SMG_" + $this.Alias)
        # Connect to Hybrid Powershell for creating group and mailbox
        Connect-Hybrid
        # Create shared mailbox group
        $OU = Get-ConfigItem Defaults.DistributionGroups.OU
        $group = New-DistributionGroup -Type Security -OrganizationalUnit $OU -Name $this.GroupName
        if($group) { 
            Set-DistributionGroup $this.GroupName -HiddenFromAddressListsEnabled $true 
            $this.Save("GroupCreated")
        }
    } -Force

    $workflow | Add-Member -MemberType ScriptMethod -Name GroupCreated -Value {
        Connect-Hybrid
        # Determine OU for mailbox placement
        $OUName = Get-RegionSpecificData -Type OrganisationalUnit -CountryCode $this.CountryCode -SiteCode $this.SiteCode
        $OU = (Get-ConfigItem Defaults.Users.OrganisationalUnit) + $OUName

        $UPN = ($this.Alias + "@contoso.com")

        # Create mailbox
        $mailbox = $null
        switch($this.Type) {
            "Room" {
                $mailbox = New-RemoteMailbox -Name $this.DisplayName `
                    -Alias $this.Alias `
                    -OnPremisesOrganizationalUnit $OU `
                    -UserPrincipalName $UPN `
                    -Room
            }
           
            "Equipment" {
                $mailbox = New-RemoteMailbox -Name $this.DisplayName `
                    -Alias $this.Alias `
                    -OnPremisesOrganizationalUnit $OU `
                    -UserPrincipalName $UPN `
                    -Equipment
            }

            "Workspace" {
                $mailbox = New-RemoteMailbox -Name $this.DisplayName `
                    -Alias $this.Alias `
                    -OnPremisesOrganizationalUnit $OU `
                    -UserPrincipalName $UPN `
                    -Room
            }

            "Shared" {
                $mailbox = New-RemoteMailbox -Name $this.DisplayName `
                    -Alias $this.Alias `
                    -OnPremisesOrganizationalUnit $OU `
                    -UserPrincipalName $UPN `
                    -Shared
            }
        }

        if($mailbox) {
            $this.Save("MailboxRequested")
        }

        # --> 4. Ensure we save the current state of the workflow and move to the next stage
        # This saves any changes to variables and any new variables created.
        # The argument "Second" (which could be anything you like) ensures that the next
        # stage is processed next time the workflow runs, otherwise this stage would
        # continue being run forever. 
    }

    # --> 5. Define functions for other stages
    # You can have as many of these as you need. Just change the -Name property of Add-Member
    # to the name of the stage, and define the commands in the value ScriptBlock below.
    Add-Member -InputObject $workflow -MemberType ScriptMethod -Name MailboxRequested -Value {
        # See if the mailbox user account is ready to receive the mailbox
        try {
            if($this.Type -ne "Shared") 
            {
                Add-ADGroupMember "GRS_O365_RC_Mailboxes" -Members $this.Alias -ErrorAction SilentlyContinue
                Add-ADGroupMember $this.GroupName -Members "rc_service" -ErrorAction SilentlyContinue
            }
        }
        catch { 
            Write-Warning "Group membership was not updated... Assuming already done."
        }
            
        Write-Verbose "Cheking if mailbox created in ExchangeOnline"
        Connect-ExchangeOnline
        $Mailbox = Get-Mailbox $this.UserPrincipalName -ErrorAction SilentlyContinue
        if($Mailbox) {
            $this.Save("MailboxCreated")
        }
    }

    Add-Member -InputObject $workflow -MemberType ScriptMethod -Name MailboxCreated -Value {
    
        Connect-ExchangeOnline

        Add-MailboxPermission -Identity $this.Alias `
            -User $this.GroupName -AccessRights FullAccess -InheritanceType All
        
        # Grant access of mailbox to mailbox group
        # Also apply default resource configuration.   
        if($this.Type -ne "Shared")
        {
            # Configure delegates
            Set-CalendarProcessing $this.Alias -ResourceDelegates $this.GroupName
            # Set the permissions
            Set-ResourceCalendarPermissions $this.DisplayName
            # Set the configuration
            Set-ResourceDesiredConfiguration $this.DisplayName
        }

        Connect-Hybrid
        # Determine if requester email already sent
        if(-not $this.RequesterEmailSent) {
            $req = Get-User $this.Requester
            if($req)
            {
                $body = Merge-Tokens `
                    (Get-Content (Get-ConfigItem UserManagement.SharedMailboxRequesterEmailBody)) `
                    @{
                        requesterforename = $req.FirstName
                        displayname = $this.DisplayName
                    } | Out-String            
            }

            $creator_email = (Get-User $this.Creator).WindowsEmailAddress

            $subject = "New User Account for " + $this.DisplayName
            if($this.CallReference)
            {
                $subject = "[" + $this.CallReference + "] " + $subject 
            }

            Send-MailMessage `
                -From (Get-ConfigItem Defaults.SMTP.FromAddress) `
                -To $req.WindowsEmailAddress `
                -Cc $creator_email `
                -SmtpServer (Get-ConfigItem Defaults.SMTP.ServerAddress) `
                -Subject $subject `
                -Body $body `
                -BodyAsHtml `
                -ErrorVariable RequesterEmailErrors

            if(-not $RequesterEmailErrors) { 
                $this.RequesterEmailSent = $true
                $this.Save("Complete") 
            }
        }
    }

    # Return the workflow so that it can be manipulated
    $workflow
}
