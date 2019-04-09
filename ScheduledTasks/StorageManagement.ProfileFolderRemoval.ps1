<#
.SYNOPSIS
    Removes roaming profile folders unused for 3 months.

.DESCRIPTION
    Checks the ntuser.dat timestamp in each profile folder on the share, removes stale ones, and reports
    folders that were inaccessible or contained prf*.tmp files (a sign of profile sync problems).

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

$3_months_ago = (Get-Date).AddMonths(-3);
$profile_share  = "\\FILER01\Profiles"

$error_folders = @()
$prf_tmp = @()

$profile_folders = gci $profile_share |
Where-Object {
	$ntuser = (Get-Item ($_.FullName + "\ntuser.dat") `
		-Force -ErrorVariable +error_folders `
		-ErrorAction SilentlyContinue)
	
	if($ntuser) { $ntuser.LastWriteTime -lt $3_months_ago }
	else { $false }		
} | ForEach-Object {
		# Check for prf temporary files in the profile folder
		if((Get-Item ($_.FullName + "\prf*.tmp")).Count -gt 0)
		{
			$prf_tmp += $_
		}
		else
		{
			# Remove the item (with a barrier just in case the script goes wrong
			# somewhere and one of the folders comes back as "\\FILER01\profiles")
			if($_.FullName -ne "\\FILER01\profiles") 
			{ 
				Write-Host "Removing folder $_"
				Remove-Item $_.FullName -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable removal_error
			}
			
			if($removal_error)
			{
				Write-Host "ERROR: Could not remove some or all of profile folder ($_)"
			}
		}
	}

if($error_folders.Count -gt 1)
{
	Write-Host ""
	Write-Host @"
The following folders were either inaccessible or did not contain an
ntuser.dat file. These will need to be manually corrected or removed.
"@

	$error_folders | Foreach-Object -MemberName TargetObject
}

if($prf_tmp.Count -gt 1)
{
	Write-Host ""
	Write-Host @"
The following profile folders contained files matching prf????.tmp. This
suggests there could be a problem with synchronisation of the user's
profile.
"@
	$prf_tmp
}
