<#
.SYNOPSIS
    Create a Managed Service Account in Active Directory
.DESCRIPTION
    Creates a Managed Service Account in Active Directory. The name of the account is the
    the AccountName parameter. It should be a the name or the computer or an alias, followed
    by an acronym for the service, eg. GBVUAPXX_SQL or ALIAS_IIS.

    The total length of the account name cannot exceed 15 characters and must be a valid
    AD principal name.

    Currently the script will only create and install a service account on the local machine,
    due to limited PowerShell remoting capabilities on Windows 2008 R2 servers.
.PARAMETER ComputerName
    The name of the computer to create the Managed Service Account for. If not provided, the
    local machine is assumed.
.PARAMETER AccountName
    A short name for the account
.EXAMPLE
    # Creates a Service account called with the local computer name and _SQL appended. For 
    # example, if the local computer name is LOCALCOMPUTER, the account will be called 
    # LOCALCOMPUTER_SQL.
    New-ServiceAccount -AccountName LOCALCOMPUTER_SQL
.EXAMPLE
    # Creates a Service account called REMOTECOMPUTER_SQL
    New-ServiceAccount -ComputerName REMOTECOMPUTER -AccountName REMOTECOMPUTER_SQL
#>
function New-ServiceAccount {
    
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$AccountName
    )
    
    if(-not (Get-Module ActiveDirectory -ListAvailable)) {
        throw "Active Directory Powershell module required. Please run 'Add-WindowsFeature RSAT-AD-PowerShell' to install"
    }
    else
    {
        Import-Module ActiveDirectory
    }

    if($AccountName.length -gt 15) {
        throw "Account name to be created was $AccountName with a length of $($AccountName.length), but maximum length is 15 characters"
    }

    $account_computername = $AccountName + "$"

    $script_block = {
        param($account_name, $account_computername)
        # Generate a new account – max length of attributed 15 chars.
        New-ADServiceAccount -SamAccountName $account_name -DisplayName $account_name -Name $account_name
        # Store the service account in a variable
        $sa = Get-ADServiceAccount $account_computername
        # Store the computer account in a variable
        $comp = Get-ADComputer $env:COMPUTERNAME
        # Add the computer to the service account
        Add-ADComputerServiceAccount -Identity $comp -ServiceAccount $sa
        # Install the service account
        Install-ADServiceAccount $account_computername
    }
    
    if($env:COMPUTERNAME -ne $ComputerName) {
        throw "Currently this command will only create a managed service account when running on the host on which it is to be installed."
        <# Invoke-Command -ComputerName $ComputerName `
            -ScriptBlock $script_block `
            -ArgumentList $AccountName,$account_computername #>
    }
    else {
        Invoke-Command -ScriptBlock $script_block `
            -ArgumentList $AccountName,$account_computername
    }

}
