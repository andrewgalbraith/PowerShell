<#
.SYNOPSIS    
    Check a hashtable of file metadata for OneDrive readiness.
.DESCRIPTION
    Checks an object of file metadata from the Get-FolderItem command against
    criteria for OneDrive readiness. For each criterion it adds a property to
    the hashtable which identifies whether the test was passed. A property
    indicating whether any of the criterion weren't met is also added.
.PARAMETER FolderItem
    An object from the output of Get-FolderItem
.PARAMETER RootPath
    The root of the folder being scanned. Used to translate the path into a
    OneDrive URI.
.PARAMETER UserName
    The samAccountName of the user whose OneDrive this data will be migrated to.
.EXAMPLE
    Get-FolderItem | 
        Test-FolderItemOneDriveReadiness -RootPath (Get-Location) `
            -UserName $env:UserName
#>
function Test-FolderItemOneDriveReadiness {
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [PSCustomObject[]]$FolderItem,
        [parameter(Mandatory=$true)]
        [String]$RootPath,
        [parameter(Mandatory=$true)]
        [String]$UserName
    )
    begin {
        $RootURI = "https://contoso-my.sharepoint.com/personal/$($UserName)_contoso_com/Documents/Private/"
    }

    process {
        $PathExclRoot = $_.FullName.SubString($RootPath.Length)
        $Encoded = [System.Uri]::EscapeDataString($PathExclRoot)
        $DestinationURI = $RootURI + $Encoded
        
        # Add additional properties to file's metadata hashatable
        $_ | Add-Member -Name "RelativePath" -Membertype "NoteProperty" -Value $PathExclRoot
        $_ | Add-Member -Name "Errors" -MemberType "NoteProperty" -Value $false
        $_ | Add-Member -Name "TooBig" -MemberType "NoteProperty" -Value $false
        $_ | Add-Member -Name "TooLong" -MemberType "NoteProperty" -Value $false
        $_ | Add-Member -Name "BadCharacters" -MemberType "NoteProperty" -Value $false
        $_ | Add-Member -Name "BeginsWithSpace" -MemberType "NoteProperty" -Value $false
        $_ | Add-Member -Name "BadExtension" -MemberType "NoteProperty" -Value $false
        $_ | Add-Member -Name "BadPatterns" -MemberType "NoteProperty" -Value $false
        $_ | Add-Member -Name "DestinationURI" -Membertype "NoteProperty" -Value $DestinationURI

        # Check file path size
        if($_.DestrinationURI -gt 400) {
            $_.Errors = $true
            $_.TooLong = $true
        }

        # Check file size not greater than 2.5GB
        if($_.Length -gt 2GB) {
            $_.Errors = $true
            $_.TooBig = $true
        }

        $FileName = Split-Path $_.FullName -Leaf
        $Extension = $FileName.split('.')[-1]
        if($FileName -notmatch "\." ) {
            $BaseName = $FileName
        } elseif($FileName -match "^\.") {
            $BaseName = ""
        } else {
            $BaseName = $Filename.substring(0,($Filename.length - ($Extension.length+1)))
        }

        # Check file path characters
        foreach($token in $PathExclRoot.split('\')) {
            if($token -match '["|\*|:|\<|\>|\?|/|\\|\||#]' ) {
                $_.Errors = $true
                $_.BadCharacters = $true
            }

            # Begins with a space
            if($token -match '^\s') {
                $_.Errors = $true
                $_.BeginsWithSpace = $true
            }
        }

        # Check file path for bad extension
        if($Extension -match "as[p|m|c]x|master|xap|swf|jar|xsf|htc") {
            $_.Errors = $true
            $_.BadExtension = $true
        }
        # Check file path does not match specific patterns

        if($BaseName -match "^AUX$|^PRN$|^NUL$|^CON$|^(COM|LPT)[0-9]$|^BAT$") {
            $_.Errors = $true
            $_.BadPatterns = $true
        }

        return $_
    }
}
