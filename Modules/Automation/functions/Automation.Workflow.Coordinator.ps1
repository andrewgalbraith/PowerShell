function Save-WorkflowObject
{
    param([pscustomobject]$Object, [String]$WorkflowType)

    $StorageDirectory = ((Get-ConfigItem Automation.JobStorage) + "\" + $WorkflowType)
    if(-not (Test-Path $StorageDirectory))
    {
        mkdir $StorageDirectory
    }

    if($Object.InstanceName) 
    {
    
        $path = ($StorageDirectory + "\" + $Object.InstanceName + ".xml")
        
		$Object | Export-CliXML -Path $path

        if($Object.State -eq "Complete")
        {
            Write-Debug "Workflow complete, adding .archive extension"
            Rename-Item -Path $path -NewName ($path + ".archive")
        }
    }
    else
    {
        $false
    }

}

function Restore-WorkflowObjects
{
    param($WorkflowType)

    $StorageDirectory = Join-Path (Get-ConfigItem Automation.JobStorage) $WorkflowType
    if(Test-Path $StorageDirectory)
    {
        Get-ChildItem $StorageDirectory -Filter "*.xml" |
            Foreach-Object { Import-CliXML -Path ( $_.FullName ) }
    }
    else
    {
        $false
    }
}

function Process-Workflows
{
    Get-ChildItem (Get-ConfigItem Automation.JobStorage) -Directory  | 
        ForEach-Object {
            
            $workflow = $_.Name
            
            Write-Verbose ("Processing " + $workflow + " Items")
            Restore-WorkflowObjects $workflow | 
                Where-Object { $_.State -ne "Complete" } |
                ForEach-Object {
                    
                    # Capture the instance
                    $instance = $_.InstanceName
                    
                    # Exit if lockfile exists, otherwise create lockfile
                    try {
                        Write-Verbose "Start processing workflow instance: $instance"
                        
                        # Obtain a lock on the workflow (create a lockfile with <instancename>.lock)
                        Write-Verbose "Create a lock file for the workflow"
                        $lockfile_path = Join-Path -Path (Get-ConfigItem Automation.JobStorage) `
                            -ChildPath ($instance + ".lock")
                        $lockfile = New-Item $lockfile_path -Type File -ErrorAction Stop
                        
                        # Process the workflow
                        Invoke-Expression ("($workflow)" + '.Initialise($_).Process()')
                        
                    }
                    catch [System.IO.IOException]
                    {
                        Write-Warning $_.Exception.Message
                    }
                    catch {
                        Write-Warning "Workflow $instance instance encountered an error; it may need attention."
                        Write-Warning $_
                        Send-MailMessage -To "it.admin@contoso.com","it.admin2@contoso.com" `
                            -From "ops.automation@contoso.com" `
                            -Subject "Workflow ($instance) error encountered, see body for details" `
                            -Body $_ `
                            -SmtpServer "smtp.contoso.com"
                    }
                    finally
                    {
                        # Remove the lockfile
                        Write-Verbose "Remove the lock file for the instance"
                        $lockfile | Remove-Item

                        Write-Verbose "Finished processing workflow instance: $instance"
                    }
                }
        }
}

function Workflow-Status
{
    Get-ChildItem (Get-ConfigItem Automation.JobStorage) | 
		ForEach-Object {
            $workflow = $_.Name

            Write-Host $workflow

            $instances = Restore-WorkflowObjects $workflow
            if($instances.InstanceName)
            {
                $instances | ft InstanceName,State
            }
            else
            {
                $instances | ft UniqueName,State
            }
            
        }
}

# Returns an object
function Workflow-Template
{     
    param($InstanceName)

    $workflow = New-Object -TypeName PSCustomObject `
        -Property @{ "InstanceName" = $InstanceName}

    $workflow | Add-Member -MemberType ScriptMethod -Name SetVariable -Value {
        param($name, $value)
        Add-Member -InputObject $this -MemberType NoteProperty -Name $name -Value $value
    }

    $workflow | Add-Member -MemberType NoteProperty -Name State -Value "Initial"
    # Allows an object to be initialised with data from a PSCustomObject or Hash
    # e.g. data from Import-CliXML
    $workflow | Add-Member -MemberType ScriptMethod -Name Initialise -Value {
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

    $workflow | Add-Member -MemberType ScriptMethod -Name Save -Value {

        param($State = $null)

        if($State)
        {
            $this.State = $State
        }

        Save-WorkflowObject $this $this.WorkflowName
    }

    # This is the method that actually does the work, based on the current "State" of the object"
    $workflow | Add-Member -MemberType ScriptMethod -Name Process -Value {
        Invoke-Expression ('$this.' + $this.State + '()')
    }

    $workflow | Add-Member -MemberType ScriptMethod -Name Initial -Value { $this.Save("Complete") }
    #Return only the new object
    return $workflow
}


function Get-WorkflowStatus {
    param($workflowtype)

    $objects = Restore-WorkflowObjects $workflowtype

    if($workflowtype -eq "New-UserWithMailbox")
    {
        $objects | ? State -ne "Complete" | Sort State | ft Forename,Surname,EmployeeID,WelcomeEmailSent,RequesterEmailSent,State -AutoSize
    }
    else
    {
        $objects | ? State -ne "Complete" | Sort State,InstanceName | ft InstanceName,State,Creator -AutoSize
    }
}
