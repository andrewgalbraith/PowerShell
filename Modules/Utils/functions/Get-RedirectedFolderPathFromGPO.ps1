<#
.SYNOPSIS
    Get the redirected My Documents path for a user
.DESCRIPTION
    Searches the folder redirection group policy for the redirected
    My Documents location associated with the folder redirection group
    which the user account is a member of. If one or more folder names are
    given, only these are returned, otherwise all redirected folders are 
    returned.
.PARAMETER Username
    The user name of the user to get the redirection group for.
.PARAMETER FolderName
    The name(s) of the redirected folders to return.
.PARAMETER GPOGuid
    The GUID of the group policy object that contains folder redirection
    settings
.EXAMPLE
    Get-RedirectedFolderPathFromGPO -Username testuser -FolderName "My Documents"
.EXAMPLE
    Get-RedirectedFolderPathFromGPO -Username testuser -FolderName "My Documents","Favorites"
.EXAMPLE
    Get-RedirectedFolderPathFromGPO -Username testuser
#>
function Get-RedirectedFolderPathFromGPO {
    param(
        [parameter(Mandatory=$true)]
        [String]$Username,
        [String[]]$FolderName,
        [GUID]$GPOGuid = "00000000-0000-0000-0000-000000000000"
    )

    $RedirectionGroups = Get-AdUser $Username -Properties MemberOf |
        Select-Object -ExpandProperty MemberOf |
        Where-Object { $_ -like "*FOLDER_REDIRECTION*" }

    $RedirectionGroupSAMs = $RedirectionGroups | 
        Foreach-Object { 
            "CONTOSO\" + ($_ -split ',')[0].Remove(0,3)
        }

    # Get folder redirection locations from GPO object
    $redirect = (Get-GPO -Guid $GPOGUID.Guid).GenerateReport("XML") | 
        Select-XML -Namespace @{redirect="http://www.microsoft.com/GroupPolicy/Settings/FolderRedirection"} `
            -XPath "//redirect:Folder"

    $folders = $redirect.Node.Location | 
        Where-Object { $RedirectionGroupSAMs -contains $_.SecurityGroup.Name."#text" } |
        Foreach-Object { $_.DestinationPath.Replace('%USERNAME%', $Username) }

    if($FolderName) {
        foreach($folder in $folders) {
            foreach($name in $FolderName) {
                if($folder -like "*$name") {
                    $folder
                }
            }
        }
    } else {
        $folders
    }    
}
