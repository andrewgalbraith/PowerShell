<#
 .SYNOPSIS 
    Finds and removes user home folders that are no longer associated with a user.
 .DESCRIPTION
    Scans all the directories the config module which are defined to be associated with
    user home folders (the key ends with '.homedrive'). Subfolders of these folders are
    expected to have the same name as an existing user in Active Directory.
    
    If the folder name does not match a the username of an existing user in AD, the folder
    is added to the list. If the folder is a home folder in SiteA (it lives on
    FILER02) the folder is also removed.

    At the end of the script, a list of all folders - whether removed or not - is emailed to
    'it.admin@contoso.com'.
#>

# Get the last part of the HomeDirectory path for all users in AD
$keep_users = Get-ADUser -Filter * -Properties HomeDirectory |
	ForEach-Object {
		if($_.HomeDirectory) { $_.HomeDirectory.Split("\") | Select -Last 1 }
	}

# List HomeDrives and remove for non-existent users
$locations = Get-Config | 
	Where-Object {$_.Key -like "*.homedrive" -and $_.Value} | 
	Foreach-Object {$_.Value.ToLower()} | 
	Select-Object -Unique

# Prepare array for removal list
$remove = @();

# For each location, determine if it belongs to an existing user. If not, add it to the removal list.
$remove = $locations | 
	ForEach-Object { Get-ChildItem $_ -Directory } | 
	Where-Object { $keep_users -notcontains $_.Name }

# Send email detailing users to be removed.
$body = $remove | Out-String
Send-MailMessage -To "it.admin@contoso.com" -Subject "Global home drives for removal" -Body $body -From (Get-ConfigItem Defaults.SMTP.FromAddress) -SmtpServer (Get-ConfigItem Defaults.SMTP.ServerAddress)

# Remove only SiteA and India
$remove | 
	Where-Object { $_.FullName -like "*SiteA*" -or $_.FullName -like "*SiteB*" -or $_.FullName -like "*SiteC*" } | 
	ForEach-Object {
		
		# Write out the name of the folder to be removed
		Write-Verbose  "n`nRemoving home drive: $_" -BackgroundColor DarkBlue -ForegroundColor White
		Write-Verbose ("`t Full path is " + $_.FullName + "`n`n") -BackgroundColor DarkBlue -ForegroundColor White	
		
		# SUBINACL is not supported for DFS paths, so we need to work out the path to
		# the users folder on the filer. Since we are only removing data from SiteA, we
		# can assume the folder is on \\FILER02\users
		$path = Join-Path (Resolve-DFSPath (Split-Path $_.FullName)) $_
		# Write-Host $path
			
		Write-Verbose "- Using SUBINACL on $path to ensure it can be deleted" -BackgroundColor DarkGray -ForegroundColor White
		TakeFolderOwnership $path "contoso\drs_gb_bsd_file_access"

		# Remove the folder using rmdir
		Write-Verbose "- Removing folder" -BackgroundColor DarkGray -ForegroundColor White
		Invoke-Expression "cmd /c rmdir /s /q '$path'"

	}
