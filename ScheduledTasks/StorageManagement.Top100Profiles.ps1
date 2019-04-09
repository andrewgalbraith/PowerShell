<#
.SYNOPSIS
    Lists the largest roaming-profile folders on the profile share.

.DESCRIPTION
    Lists the largest roaming-profile folders on the profile share.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

function Get-DirectorySize() {
  param ([string]$root = $(resolve-path .))
  (gci -re $root |
    ? { -not $_.PSIsContainer } | 
    	measure-object -sum -property Length).Sum / 1mb
}

$top100 = Get-ChildItem "\\FILER01\profiles" | Select -First 10 | % { 
	[psCustomObject] @{
		"FolderName" = $_; 
		"Size" = (Get-DirectorySize $_.FullName)
	}
} | Sort "Size" -Descending | 
	Select -First 100 | 
	Ft FolderName,@{Expression = {("{0:N3}" -f $_.Size)}; Label = "Size (MB)"}
	
