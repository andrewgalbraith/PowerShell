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
function Example-Workflow {
    param($InstanceName)
    # Create an instance of the template workflow
    # This gives us back an object with methods and properties required for the workflow.
    $workflow = Workflow-Template $InstanceName
    # Ensure the workflow has the correct name
    $workflow | Add-Member -MemberType NoteProperty -Name WorkflowName -Value $MyInvocation.MyCommand.ToString() -Force
    
    # --> 2. Define and initialise any workflow variables required
    $workflow.SetVariable("MailSent", $false)
    $workflow.SetVariable("SecondMailSent", $false)

    # --> 3. Define the "Initial" stage function. 
    # This is the function which is invoked when the workflow first runs
    # We are customizing the template by adding members to it, but whis existed in the 
    # template so we should use -Force to overwrite.
    $workflow | Add-Member -MemberType ScriptMethod -Name Initial -Value {
        # Do something useful
        Send-MailMessage -From firstname.lastname@contoso.com -To firstname.lastname@contoso.com -Subject "Inital stage complete"
        $this.SetVariable("MailSent", $true)
        
        # --> 4. Ensure we save the current state of the workflow and move to the next stage
        # This saves any changes to variables and any new variables created.
        # The argument "Second" (which could be anything you like) ensures that the next
        # stage is processed next time the workflow runs, otherwise this stage would
        # continue being run forever. 
        $this.Save("Second")
    } -Force

    # --> 5. Define functions for other stages
    # You can have as many of these as you need. Just change the -Name property of Add-Member
    # to the name of the stage, and define the commands in the value ScriptBlock below.
    Add-Member -InputObject $workflow -MemberType ScriptMethod -Name Second -Value {
        # Maybe do something else useful.
        Send-MailMessage -From firstname.lastname@contoso.com -To firstname.lastname@contoso.com -Subject "Second stage complete"
        $this.SetVariable("SecondMailSent", $true)

        # --> 6. Ensure there is a stage which puts the workflow into a complete state.
        # In a complete state, the workflow will not be processed.
        $this.Save("Complete")
    }

    # Return the workflow so that it can be manipulated
    $workflow
}
