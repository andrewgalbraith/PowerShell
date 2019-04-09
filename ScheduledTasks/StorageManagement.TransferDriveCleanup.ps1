<#
.SYNOPSIS
    Purges anything older than 30 days from the shared transfer folders.

.DESCRIPTION
    Purges anything older than 30 days from the shared transfer folders.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

# Get all folders in the transfer drive created more than 30 days ago and remove them

function Clean-Folder {
    param($FolderPath)
    Get-ChildItem $FolderPath -Force | 
	    Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-31)} |
	    ForEach-Object { Invoke-Expression ('cmd.exe /c rmdir "' + $_.FullName + '" /s /q') }
}

$folders = @(
    "\\contoso.com\global\common\transfer",
    "\\contoso.com\global\Engineering\TRANSFER"
) 

$folders | ForEach-Object {
    Write-Host "Cleaning folder $_" 
    Clean-Folder $_
}
