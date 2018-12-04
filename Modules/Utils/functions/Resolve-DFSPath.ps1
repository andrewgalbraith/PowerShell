<#
  .SYNOPSIS
    Determines an absolute path from a DFS path 
  .DESCRIPTION
    Takes a DFS path as input and returns the absolute share path. This script 
    relies on the dfsutil.exe tool which is available on DFS sever or a Windows
    client that has the DFS management tools available.
  .EXAMPLE
    Resolve-DFSPath -Path \\contoso.com\global\Users\SiteA
  .PARAMETER Path
    A DFS path in UNC format.
#>

function Resolve-DFSPath {
	param(
        [parameter(Mandatory=$true)]
        [string]
        $path
    )
    
    $result = (((dfsutil diag viewdfspath $path) -split "[<>]") -match "[\\]")[-1]

    if(Test-Path $result)
    {
        $result
    }

}
