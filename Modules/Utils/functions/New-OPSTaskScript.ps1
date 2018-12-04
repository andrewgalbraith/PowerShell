<# 
.DESCRIPTION 
    Creates a new OPS task script file with a header that allows it to be
    deployed using TFS. 

#> 


function New-OPSTaskScript {
    param(
        # The name of the file, not including extension
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Description
    )

    if(Test-Path tasks) {
        
        # Generate the filename
        $FileName = $Name + ".ps1"
        
        # Determine the full path to the script
        $Path = Join-Path (Get-Item tasks) $FileName

        # Create the script file with the predefined settings
        New-ScriptFileInfo -Path $Path `
            -Version 1.0 `
            -Author "Andrew Galbraith" `
            -Description $Description `
            -Guid (New-Guid).GUID `
            -CompanyName "Contoso"

    } else {

        throw "Can't find the tasks folder, make sure your current working directory is the top-level of the repository"
    
    }
}
