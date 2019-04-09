<#
.SYNOPSIS
    Deletes automation transcripts older than one month.

.DESCRIPTION
    Deletes automation transcripts older than one month.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

# Removes any transcripts older than 1 month
Get-ChildItem (Get-ConfigItem "Automation.TranscriptDir") | ? { $_.CreationTime -lt (Get-Date).AddMonths(-1) } | Remove-Item -Verbose | Out-Default
