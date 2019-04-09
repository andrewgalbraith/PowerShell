<#
 .SYNOPSIS
    Removes any redirected MyDocuments folders that are no longer associated with a user.
 .DESCRIPTION
    Queries the Folder redirection GPO and extracts any paths that begin with \\contoso.com.
    Once this has been done, each folder containing redirected MyDocuments is 

#>

$folders = (Get-GPO -Guid 00000000-0000-0000-0000-000000000000).GenerateReport("XML") | 
	Select-XML -Namespace @{redirect="http://www.microsoft.com/GroupPolicy/Settings/FolderRedirection"} -XPath "//redirect:Folder" | 
	% { $_.Node.Location } | 
    ? DestinationPath -like "\\contoso.com\*" | # Select only the "\\contoso.com" paths
    Select -Expand DestinationPath | # Expand the attributes so we only have an array of path strings
    % { $_ -split "%" | Select -first 1 } | # Remove anything after %username%
    % { Get-ChildItem $_ | ? { -not (Get-ADUser -Filter {samAccountName -eq $_.Name}) } }

$folders | ? { $_.FullName -like "*SiteA*"} | % {
    
    # Display removal messages
    Write-Host "`n`nRemoving file/folder: $_" -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host ("`t Full DFS path is " + $_.FullName) -BackgroundColor DarkBlue -ForegroundColor White
    $referral_path = Resolve-DFSPath $_.FullName
    Write-Host ("`t Full referral path is " + $referral_path + "`n") -BackgroundColor DarkBlue -ForegroundColor White

    # Change permissions on the file/folder to ensure it can be deleted
    Write-Host "- Using SUBINACL on $referral_path to ensure it can be deleted" -BackgroundColor DarkGray -ForegroundColor White
	TakeFolderOwnership $referral_path "contoso\ops.automation"

    # Remove the folder using rmdir
	Write-Host "- Removing folder" -BackgroundColor DarkGray -ForegroundColor White
	iex "cmd /c rmdir /s /q '$referral_path'"
    
}

Send-MailMessage -From it.admin@contoso.com -To it.admin@contoso.com -SmtpServer smtp.contoso.com -Subject "Redirected MyDocuments areas for removal" -Body ($folders | Out-String)
