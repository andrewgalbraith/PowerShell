<#
.SYNOPSIS
  Upgrade user license to E3
.DESCRIPTION
  Upgrade a user's Exchange license to the E3 with only the Office365 and Plan 2 
  options enabled. Any existing licenses will be removed, so this will work even
  if the mailbox already had an E3 plan.
#>


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
function UpgradeLicenseToE3 {
    param($InstanceName)
    # Create an instance of the template workflow
    # This gives us back an object with methods and properties required for the workflow.
    $workflow = Workflow-Template $InstanceName
    # Ensure the workflow has the correct name
    $workflow | Add-Member -MemberType NoteProperty -Name WorkflowName -Value $MyInvocation.MyCommand.ToString() -Force
    
    # --> 2. Define and initialise any workflow variables required
    $workflow.SetVariable("MailSent", $false)
    $workflow.SetVariable("UserPrincipalName", $null)
    $workflow.SetVariable("OfficeDeploymentRequired", $false)
    $workflow.SetVariable("Creator", $null)

    # --> 3. Define the "Initial" stage function. 
    # This is the function which is invoked when the workflow first runs
    # We are customizing the template by adding members to it, but whis existed in the 
    # template so we should use -Force to overwrite.
    $workflow | Add-Member -MemberType ScriptMethod -Name Initial -Value {
        
        Connect-MSOL

        # Remove any existing licenses
        @("CONTOSO:EXCHANGEDESKLESS", 
            "CONTOSO:EXCHANGESTANDARD",
            "CONTOSO:EXCHANGEENTERPRISE",
            "CONTOSO:ENTERPRISEPACK") |
        % {
            Set-MSOLUserLicense -UserPrincipalName $this.UserPrincipalName `
                -RemoveLicenses $_ `
                -ErrorAction SilentlyContinue
        }

        # Confirm removal of licenses
        $user = Get-MSOLUser -UserPrincipalName $this.UserPrincipalName

        # If license not removed, don't attempt to re-license
        if(-not $user.isLicensed)
        {
            # Add the E3 license
            $cc = Get-MSOLUser -UserPrincipalName $this.UserPrincipalName | 
                Select -ExpandProperty UsageLocation

            if(Set-O365UserLicense -UserPrincipalName $this.UserPrincipalName -LicenseCode "E3" -CountryCode $cc)
            {
                if($this.OfficeDeploymentRequired)
                {
                    $username = $this.UserPrincipalName -split '@' | Select -First 1
										
					try 
                    {
                        Add-ADGroupMember "GDP_SW_O365" `
                            -Members $username `
                            -ErrorAction SilentlyContinue | Out-Null
                    }
                    catch{ $_ }
                    
                    $body = Merge-Tokens `
                        (Get-Content (Get-ConfigItem UserManagement.Office365Upgrade)) `
                            @{ firstname = $user.FirstName } | 
                        Out-String
                    
                    Connect-Hybrid

                    $email = Get-Recipient $this.UserPrincipalName | Select -ExpandProperty PrimarySMTPAddress
                    $creator_email = Get-Recipient $this.Creator | Select -ExpandProperty PrimarySMTPAddress

                    Send-MailMessage `
                        -From (Get-ConfigItem Defaults.SMTP.FromAddress) `
                        -To $email `
                        -CC $creator_email,"it.admin@contoso.com" `
                        -SmtpServer (Get-ConfigItem Defaults.SMTP.ServerAddress) `
                        -Subject ("Office 365 Installation") `
                        -Body $body `
                        -BodyAsHtml `
                        -ErrorVariable EmailErrors

                    if(-not $EmailErrors)
                    {
                        $this.MailSent = $true
                        $this.Save("Complete")
                    }
                }
                else
                {
                    $this.Save("Complete")
                }
            }
        }
    } -Force

    # Return the workflow so that it can be manipulated
    $workflow
}
