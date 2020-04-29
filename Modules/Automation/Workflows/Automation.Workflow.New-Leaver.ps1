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
# > (Example-Workflow "Usage Example 2").Initialise(@{"MailSent" = $true})
# or, as above, but additionally save the workflow
# > (Example-Workflow "Usage Example 3").Initialise(@{"MailSent" = $true}).Save()
# or, just create an instance and save it in its default state
# > (Example-Workflow "Usage Example 4").Save()

# --> 1. Rename this function.
# Provide a descriptive name for your workflow, for example "New-UserWithMailbox"

function New-Leaver {
    param($InstanceName)
    # Create an instance of the template workflow
    # This gives us back an object with methods and properties required for the workflow.
    $workflow = Workflow-Template $InstanceName
    # Ensure the workflow has the correct name
    $workflow | Add-Member -MemberType NoteProperty -Name WorkflowName -Value $MyInvocation.MyCommand.ToString() -Force
    
    # --> 2. Define and initialise any workflow variables required
	$workflow.SetVariable("UserName", $null)
    $workflow.SetVariable("DateAdded", (Get-Date))
	$workflow.SetVariable("RemovalDate", (Get-Date).AddDays(31))
    

    # --> 3. Define the "Initial" stage function. 
    # This is the function which is invoked when the workflow first runs
    # We are customizing the template by adding members to it, but whis existed in the 
    # template so we should use -Force to overwrite.
    $workflow | Add-Member -MemberType ScriptMethod -Name Initial -Value {

		# Change password of user using default from config
		try
		{
			$password = ConvertTo-SecureString (Get-ConfigItem Defaults.Users.LeaverPassword) -AsPlainText -Force
			Set-ADAccountPassword -Identity $UserName -NewPassword $password -Reset
			
			$this.Save("Process")
		}
		catch 
		{
			Write-Host "Unable to set user password. Moving to error state"
			$this.save("Error")
		}

    } -Force # Overwrite Initial() method of Workflow-Template

    # --> 5. Define functions for other stages
    # You can have as many of these as you need. Just change the -Name property of Add-Member
    # to the name of the stage, and define the commands in the value ScriptBlock below.
    Add-Member -InputObject $workflow -MemberType ScriptMethod -Name Process -Value {
		
		# Attempt to give permissions to manager for all data held by User
		try 
		{
			# Get the user
			$user = Get-ADUser $this.UserName -Properties HomeDirectory,ProfilePath
			
			# Get the manager's details
			$manager = (Get-ADUser $user.Manager -Properties mail)
			
			# Give the manager permissions on the mailbox
			Connect-ExchangeOnline
			Add-MailboxPermission $user.mail -User $manager.mail -AccessRights FullAccess -AutoMapping:$true
			
			# Give the manager permissions on the User's file storage
			$password = ConvertTo-SecureString (Get-ConfigItem Defaults.Users.LeaverPassword) -AsPlaintext -Force
			$credential = New-Object System.Management.Automation.PSCredential ($this.UserName, $password)
			
			Get-ACL $user.HomeDirectory			
			
			# Email the notification to the manager
			Email-Manager $user
		}
		catch [Exception]
		{
			$this.Log.Add($_.Message)
			$this.Save("Error")
		}
      
        $this.Save("Complete")
    }

    # Return the workflow so that it can be manipulated
    $workflow
}

function Add-ManagerFilesystemPermissions
{
	param($user, $manager, $credential)
		
	
	if($Manager)
	{
		# Give the manager permissions to the user's home drive
		if($user.HomeDirectory)
		{
			# Set-AdministratorFolderOwner $user.HomeDirectory $Manager.samAccountName
			# Grant-NTFSPermission  $user.HomeDirectory $Manager.samAccountName
            Grant-PermissionByTakingOwnership $user.HomeDirectory $Manager.samAccountName

		}
		
		# Give the manager permissions to the user's profile
		if($user.ProfilePath)
		{
            $v2path = ($user.ProfilePath + ".v2")

            if(Test-Path $user.ProfilePath)
            {
                # Set-AdministratorFolderOwner $user.ProfilePath $Manager.samAccountName
			    # Grant-NTFSPermission  $user.ProfilePath $Manager.samAccountName   
                Grant-PermissionByTakingOwnership  $user.ProfilePath $Manager.samAccountName       
            }
            if(Test-Path $v2path)
            {
                # Set-AdministratorFolderOwner $v2path $Manager.samAccountName
			    # Grant-NTFSPermission  $v2path $Manager.samAccountName
                Grant-PermissionByTakingOwnership  $v2path $Manager.samAccountName        
            }
		}
	}
}
