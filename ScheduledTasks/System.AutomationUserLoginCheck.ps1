<#
.SYNOPSIS
    Emails an alert if the automation service account is not logged on to the automation host.

.DESCRIPTION
    Emails an alert if the automation service account is not logged on to the automation host.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

# Import PowerShell Community eXtensions module
Import-Module PSCX

# List terminal sessions for ops.automation and send email if none exists
if(!(Get-TerminalSession -ComputerName AUTOMATION01 | ? { $_.UserName -like "*ops.automation*" }))
{
    # Prepare paramters
    $email_params = @{
        SmtpServer = "smtp.contoso.com"
        To = (Get-ConfigItem System.AdministratorEmail)
        From = (Get-ConfigItem Automation.Username)
        Subject = "WARNING: Automation user not currently logged in"
        Body = "The ops.automation user is not currently logged into AUTOMATION01. Automated tasks will not run until this has been done"
    }

    # Splat!
    Send-MailMessage @email_params
}
