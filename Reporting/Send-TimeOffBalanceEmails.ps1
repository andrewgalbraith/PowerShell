<#
.SYNOPSIS
    Mail-merges vacation / long-service balances from a CSV into Outlook emails.

.DESCRIPTION
    For each row in the CSV, builds an HTML email addressed to the employee with their
    manager CC'd and sends it through the local Outlook COM object.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

$DataSource = "C:\powershell\timeoff.csv"
$EmailSubject = "Outstanding VAC/LS Balance"

Import-csv $DataSource | Foreach-Object {
    $ol = New-Object -comObject Outlook.Application
    $Mail = $ol.CreateItem(0)
    #The user goes in the To field
    $Mail.Recipients.Add($_.Email)
    #Their manager will get CC
    $recip = $Mail.Recipients.Add($_.MGR_EML)
    $recip.Type = 2
    $Mail.Subject = $EmailSubject
    $Mail.HTMLBody = "<html><body>"
        $Mail.HTMLBody =  "<p>Hi $($_.FIRSTNAME),</p>"
    $Mail.HTMLBody += "<p>Please review your current outstanding vacation and long service accural time:</p>"
    $Mail.HTMLBody += "Vacation time for the Year: <b>$($_.VAC_TFY)</b><br>"
    $Mail.HTMLBody += "Vaction time used: <b>$($_.VAC_USD)</b><br>"
    $Mail.HTMLBody += "Vaction time available: <b>$($_.VAC_AVL)</b><br>"
    $Mail.HTMLBody += "LS time for year: <b>$($_.LSD_TFY)</b><br>"
    $Mail.HTMLBody += "LS time used: <b>$($_.LSD_USD)</b><br>"
    $Mail.HTMLBody += "LS time available: <b>$($_.LSD_AVL)</b><br>"
    $Mail.HTMLBody += "<p>Please be sure to coordinate your time off with HR and $($_.MGR).</p>"
    $Mail.HTMLBody += "<br>Kind Regards,"
    $Mail.HTMLBody += "<br>Personnel"
    $Mail.Send()
}
