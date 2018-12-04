<#     
	.SYNOPSIS
		Retrieve a host's local Administrator password
#>

# Check the module is available
if(Get-Module "AdmPwd.ps" -ListAvailable)
{
	# Import the module
	Import-module "AdmPwd.ps"
	
	# Request the hostname from the user
	$name = Read-Host "Please enter the hostname (leave blank for this machine)"
	
	# If no name was given, grab the hostname of this machine
	if(-not $name)
	{
		$name = (hostname)
	}
	
	# Get the local administrator password for the host
	Get-AdmPwdPassword -ComputerName $name
}
else
{
	Write-Error "Local Administrator password tools not available!"
}
