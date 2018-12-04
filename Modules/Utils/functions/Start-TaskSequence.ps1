<#
.SYNOPSIS
	Executes a task sequence
.DESCRIPTION
	Executes a task sequence that is advertised to this host.
.PARAMETER Name
    The name of the task sequence to execute
#>
Function Start-TaskSequence {
    Param (
        [parameter(Mandatory = $true)]
        [string]$Name
    )
    Try {
        Write-Host "Connecting to the SCCM client Software Center..."
        $softwareCenter = New-Object -ComObject "UIResource.UIResourceMgr"
    }
    Catch {
        Throw "Could not connect to the client Software Center."
    }
    If ($softwareCenter) {
        Write-Host "Searching for deployments for task sequence [$name]..."
        $taskSequence = $softwareCenter.GetAvailableApplications() | Where { $_.PackageName -eq "$Name" }
        If ($taskSequence) {
            $taskSequenceProgramID = $taskSequence.ID
            $taskSequencePackageID = $taskSequence.PackageID
            Write-Host "Found task sequence [$name] with package ID [$taskSequencePackageID]."
            # Execute the task sequence
            Try {
                Write-Host "Executing task sequence [$name]..."
                $softwareCenter.ExecuteProgram($taskSequenceProgramID,$taskSequencePackageID,$true)
                Write-Host "Task Sequence executed."
            }
            Catch {
                Throw "Failed to execute the task sequence [$name]"
            }
        }
    }
}
