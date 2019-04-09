<#
.SYNOPSIS
    Scheduled entry point that runs pending workflow instances.

.DESCRIPTION
    One-liner wrapper around Process-Workflows from the Automation module, so the workflow engine can be
    run from a scheduled task.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

Process-Workflows
