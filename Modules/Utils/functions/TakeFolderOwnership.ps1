function TakeFolderOwnership { 
  <#
    .SYNOPSIS
    Uses the Microsoft tool SUBINACL to recursively reclaim ownership of a folder
    and its contents.
    .DESCRIPTION
    PowerShell by design has limited ability to gain access to resources to which
    the user running the session does not have access. This function uses the 
    legacy tool SUBINACL to take ownership of and grant permission to the specified
    folder. The permission is granted per item to the user specified by the owner
    parameter. No inheritance is defined.
        
        If the path appearst to be a contoso.com DFS path (beginning \\contoso or 
        \\contoso.com), the folder is resolved to a target.
    .EXAMPLE
    # Give ownership and full access permissions to CONTOSO\jdoe on the C:\examples folder
    TakeFolderOwnership -Folder C:\example -Owner contoso\jdoe
    .PARAMETER Folder
    A string denoting the folder to be operated upon. DFS paths are not supported.
    .PARAMETER Owner
    The user to be given permissions, e.g. CONTOSO\jdoe or 
    FILER02\Administrators
    .LINK
    Download SUBINACL - http://www.microsoft.com/en-gb/download/details.aspx?id=23510
    SUBINACL Usage - http://ss64.com/nt/subinacl.html
  #>
    
    param($Folder,$Owner)
    
    # $env:path -split ";";
    
    if($Folder -match "\\\\contoso*")
    {
        $Folder = (((dfsutil diag viewdfspath $folder) -split "[<>]") -match "[\\]")[-1]
    }
    
    iex "subinacl.exe /noverbose /file '$folder' /setowner=$owner /grant=$owner=F"
    $subfolder = Join-Path $folder "*.*"
    iex "subinacl.exe /noverbose /subdirectories '$subfolder' /setowner=$owner /grant=$owner=F"
}
