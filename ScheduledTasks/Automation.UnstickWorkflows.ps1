<#
.SYNOPSIS
Checks if the Mailbox workflow process is stuck.
.DESCRIPTION
Removes a lock file for the workflow process if the lock is older than 2 hours
#>
$fullpath = "\\contoso.com\global\IT\Scripts\Powershell\CustomModules\Contoso.Automation\WorkflowStorage\process-workflows.lock"

if (test-path $fullpath) {
if( ((get-item $fullpathold).lastwritetime).addhours(2) -gt (get-date))
	 {write-host "Process currently running"} 
else
 	{write-host "process stuck. Unsticking."
	remove-item $fullpath }
}
else
{
write-host "Lock File Not Found. Process does not appear to be stuck."
}
