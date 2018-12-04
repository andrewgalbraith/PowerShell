<#
	.SYNOPSIS
    Save credentials for connecting to Office 365
    .DESCRIPTION
    Collects and saves credentials for conectiong to Office 365. When the 
    Get-ExchangeOnlineCredentials function is used in a command, it will use
    these credentials by default. If not, it will prompt.
#>

$username = Read-Host "Enter your UPN (@contoso.com)"
Set-ConfigItem Automation.Username $username User
$password = Read-Host "Enter your current password" -AsSecureString
Set-ConfigItem Automation.SecurePassword (ConvertFrom-SecureString $password) User
