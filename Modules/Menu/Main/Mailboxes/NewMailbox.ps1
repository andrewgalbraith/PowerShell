<#
.SYNOPSIS
  Create a new mailbox
.DESCRIPTION
  Requests information from the user to generate a workflow that will create a
  new mailbox
#>

# Ensure the commands are available
Import-Module Automation

# Find out type of mailbox to be created.
$types = @("User", "Shared", "Room", "Equipment")
1..$types.Count | % { Write-Host $_"." $types[$_-1]}
$type = $types[([int](Read-Host "Enter mailbox type"))-1]

Clear

function Collect-Requester
{
    Connect-Hybrid
    do 
    {
        $requester = (Read-Host "Email address of requester")
    } until(Get-Recipient $requester -ErrorAction SilentlyContinue)

    return $requester
}

# Create a variable to store the workflow
New-Variable workflow

# Get the call reference for this workflow
$callref = (Read-Host "Please enter the call reference for this workflow")

if($type -eq "User") 
{
    $userinfo = @{}

    # Start by geting the employee ID. Used to see if there's an existing user
    do
    {
        $userinfo.EmployeeId = (Read-Host "Enter Employee ID (User ID without initials, eg. 123456)")
    } until($userinfo.EmployeeID -match "^\d{4,6}$")
		
    # Try getting an existing user and using details from account
    $filter = ("*" + $userinfo.EmployeeId)
    $user = Get-ADUser -Filter { samAccountName -like $filter } -Properties Office,CanonicalName |
        Where-Object { $_.samAccountName -match "^\w\w$($userinfo.EmployeeID)$" }
        
    # Check for existing mailbox. If there is one, do not proceed.
    Connect-Hybrid      
		
		$has_mailbox = ($user -and (Get-User $user.samAccountName).RecipientTypeDetails -like "*UserMailbox")
        $has_workflow = (Restore-WorkflowObjects "New-UserWithMailbox" |
            Where-Object { $_.UserID -like $filter } -ne $null)
		
    if($has_workflow -or $has_mailbox)
    {
        Write-Host "User already has a mailbox, or creation in progress";
    }
    else
    {
        # If the user exists, use available details. Otherwise, request them
        if($user)
        {
            Write-Host "Existing user found, using existing details where possible:"
            $user | Select CanonicalName,GivenName,Surname,samAccountName,Office
                        
            # Use existing details
            $userinfo.Forename = $user.GivenName
            $userinfo.Surname = $user.Surname
            
            # Find out if the user needs a number in their email address
            if($user.name[-1] -match "\d")
            {
                $userinfo.Increment = $user.name[-1];
            }
            else
            {
                $userinfo.Increment = ""
            }
        }
        else
        {
            Write-Host "No existing user found."
            $userinfo.Forename = (Read-Host "User's firstname")
            $userinfo.Surname = (Read-Host "User's surname")
            $userinfo.Increment = Get-NextUserNameIncrement $userinfo.forename $userinfo.surname
        }
        
        $userinfo.CountryCode = (Read-Host "Country Code (eg. GB)")
        $userinfo.SiteCode = (Read-Host "Site Code (eg. NML)")
        $userinfo.LicenseCode = (Read-Host "License Code (E1, E3 or E5)")
        $userinfo.Requester = Collect-Requester
        $userinfo.CallReference = $callref
        $userinfo.Creator = $env:USERNAME -replace "a$" # Remove 'a' from end of admin username, if necessary.
        # $userinfo.Password = Get-RandomString
        
        # Create and save the workflow object
        $workflow = (New-UserWithMailbox).Initialise($userinfo)
        Save-WorkflowObject -Object $workflow -WorkflowType "New-UserWithMailbox"
    }
}
else
{
    $mailboxinfo = @{
        DisplayName = (Read-Host "DisplayName")
        CountryCode = (Read-Host "Country Code (ie. GB)")
        SiteCode = (Read-Host "Site Code (ie. NML)")
        Requester = Collect-Requester
        Creator = $env:USERNAME
        Type = $Type
        CallReference = $callref
    }

    #Create a filename frienly name for the instance
    $instancename = $mailboxinfo.DisplayName.replace(".","_");
    # Create and save the workflow object
    $workflow = (NewResourceMailbox $instancename).Initialise($mailboxinfo)      
    $workflow.Save()
}

# Notify me of newly created workflows
# Send-MailMessage -To it.admin@contoso.com `
#    -From ops.automation@contoso.com `
#    -Subject "New Workflow Created" `
#    -Body (Out-String -InputObject $workflow) `
#    -SMTPServer smtp.contoso.com
