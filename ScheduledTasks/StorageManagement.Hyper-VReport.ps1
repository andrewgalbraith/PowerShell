<#
.SYNOPSIS
 Runs the Hyper-V report against nominated clusters
.DESCRIPTION
 Runs a report on hyper-v hosts and clusters, outputing a HTML file for each.
 The file contains information about the hosts and the VMs on it, and highlights
 any potential issues.
#>

# Specify the path to the report script
$script_path = Join-Path $PSSCriptRoot "..\third-party\HyperVReport.ps1"
# Specify the output path for reports
$output_path = $PSSCriptRoot

# Define list of clusters to run report against
$clusters = @("CLUSTER01","CLUSTER02","CLUSTER03","CLUSTER04")
# Define list of hosts to run report against
$hosts = @("HVHOST01")

# Set up hashtable for report command 
$script_parameters = @{
    "ReportFilePath" = $output_path
    "ReportFileNameTimestamp" = $false
    "ReportFileNamePrefix" = ""
}

# Set up hashtable for mail send command
$mail_parameters = @{
    "To" = @("ops.shift@contoso.com", "ops_storage_and_virtualisation_team@contoso.com")
    "From" = "ops.automation@contoso.com"
    "SmtpServer" = "smtp.contoso.com"
    "Subject" = "Cluster host and VM report"
    "Attachments" = @()
}

# Add the highlights only parameter for weekdays (and Sunday)
if((Get-Date).DayOfWeek -ne "Saturday")
{
    $script_parameters.Add("HighlightsOnly", $true)
    $mail_parameters.Subject += " - highlights only"
}

# List the clusters to run the report against, and run the report.
$clusters |
    Foreach-Object {
        # Grab the base parameter hash and add the cluster-specific details.
        $cluster_parameters = $script_parameters + @{ Cluster = $_ }
        $cluster_parameters.ReportFileNamePrefix = "$_ - Hyper-V Report"
        
        # Run the Hyper-V report script parameters hash.
        & $script_path @cluster_parameters

    }

# List the clusters to run the report against, and run the report.
$hosts |
    Foreach-Object {
        # Grab the base parameter hash and add the host-specific details.
        $host_parameters = $script_parameters + @{ VMHost = $_ }
        $host_parameters.ReportFileNamePrefix = "$_ - Hyper-V Report"
        
        # Run the Hyper-V report script parameters hash.
        & $script_path @host_parameters
    }

$mail_parameters.Attachments = Get-ChildItem $output_path -Filter "*.html" |
    Where-Object { $_.Name -Like "*Hyper-V Report*" } | 
    Select-Object -ExpandProperty FullName


# Uncomment to test
# $mail_parameters.To = "it.admin@contoso.com"
# Email the reports
Send-MailMessage @mail_parameters
