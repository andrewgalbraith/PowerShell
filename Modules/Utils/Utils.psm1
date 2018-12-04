# Imports any function files that might be found in ./functions
# NOTE: These are not module members, just made available globally
Get-ChildItem (Join-Path $PSScriptRoot "functions") -Filter *.ps1 | % { . $_.FullName }

# Adds the bin folder to PATH for the duration of the session so that the 
# executables contained within can be used by the functions
$env:PATH += ";" + (Join-Path $PSScriptRoot "bin") + ";"

<#
 .SYNOPSIS
    Causes the AAD Sync server to perform a delta syncronisation.
 .DESCRIPTION
    Causes the AAD Sync server to perform a delta syncronisation.
 .EXAMPLE
    Invoke-AADSync 
#>
function Invoke-AADSync
{    	
    $AADSyncServer = Get-ConfigItem Defaults.Office365.AADSyncServer
    
    $command = { & "C:\Program Files\Microsoft Azure AD Sync\bin\DirectorySyncClientCmd.exe" delta }
    
    if((HOSTNAME) -eq $AADSyncServer)
	{
		Invoke-Command -ScriptBlock $command
	}
	else
	{
		Invoke-Command `
        	-ComputerName $AADSyncServer `
        	-ScriptBlock $command
	}
}

# Create and export and alias for backward compatibility
New-Alias -Name Force-Dirsync -Value Invoke-AADSync
Export-ModuleMember -Alias Force-Dirsync

# Reads an input piece of text which contains tokens in the format {tokenname}
# and a hash with the token names as keys and the value to substitute in place
# of the token name.
function Merge-Tokens($template, $tokens) {
	[regex]::Replace(
		$template, `
		'\{(?<tokenName>\w+)\}',`
		{
			param($match)
			$tokenName = $match.Groups['tokenName'].Value
			$tokens[$tokenName]
		}
	)
}

function Add-FolderPermission
{
    param($Folder, $UserID)
	
	# Prepare the new access entry for the ACL
    $permission = "CONTOSO\$UserID","FullControl","ContainerInherit,ObjectInherit","None","Allow"
    $accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $permission

    # Get the existing ACL from the folder
    $acl = Get-ACL $Folder 
    # Add the new access rule to the ACL object
    $acl.SetAccessRule($accessRule)
    # Apply the new ACL to the folder
    $acl | Set-ACL $Folder
}

# Deprecated
function Set-AdministratorFolderOwner
{
	param($Folder, [Array]$AdditionalUsers)

    # $AdditionalUsers.count.ToString() + " additional user(s) to add"
		
    ipmo pscx

	# NOTE: Objects of type AccessControl.* cannot re reused once applied to an
	# object.

    # Elevate the session with the correct privileges
    $p = Get-Privilege
    $p.Enable('SEBackupPrivilege')
    $p.Enable('SERestorePrivilege')
    $p.Enable('SETakeOwnershipPrivilege')
    Set-Privilege $p
	
    
    $dirPermission = "CONTOSO\DRS_GB_OPS_FILE_ACCESS","FullControl","ContainerInherit,ObjectInherit","None","Allow"
    $dirAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $dirPermission
	$directoryACL = New-Object System.Security.AccessControl.DirectorySecurity
	$directoryACL.SetOwner([System.Security.Principal.NTAccount]'CONTOSO\DRS_GB_OPS_FILE_ACCESS')
	$directoryACL.SetAccessRule($dirAccessRule)

    $AdditionalUsers | % {
        $User = ("CONTOSO\" + $_)
        $dirPermission = $User,"FullControl","ContainerInherit,ObjectInherit","None","Allow"
        # $dirPermission
        $dirAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $dirPermission
        $directoryACL.SetAccessRule($dirAccessRule)
    }

    Write-Host "Setting directory ACL on $Folder"
	(Get-Item -LiteralPath $Folder -Force).SetAccessControl($directoryACL)

	
	Get-ChildItem $Folder -File -Force | % { 
		$filePermission = "CONTOSO\DRS_GB_OPS_FILE_ACCESS","FullControl","Allow"
    	$fileAccessRule = new-object System.Security.AccessControl.FileSystemAccessRule $filePermission
		
		$fileACL = New-Object System.Security.AccessControl.FileSecurity
		$fileACL.SetOwner([System.Security.Principal.NTAccount]'CONTOSO\DRS_GB_OPS_FILE_ACCESS')
		$fileACL.SetAccessRule($fileAccessRule)

        $AdditionalUsers | % {
            $User = ("CONTOSO\" + $_)
            $filePermission = $User,"FullControl","Allow"
            # $filePermission
            $fileAccessRule = new-object System.Security.AccessControl.FileSystemAccessRule $filePermission
            $fileACL.SetAccessRule($fileAccessRule)
        }
		
        Write-Host "Setting file ACL on $_"
		$_.SetAccessControl($fileACL)
	}
	
	Get-ChildItem "$Folder" -Directory -Force | % { Set-AdministratorFolderOwner $_.FullName $AdditionalUsers }
}

function Grant-PermissionByTakingOwnership
{
    param($Folder,$UserID)

    if(Test-Path $Folder)
    {
      do
      {
          iex "takeown /F $Folder /A /R /D Y"
          $exitcode = $LASTEXITCODE

          iex "icacls $Folder /grant contoso\drs_gb_bsd_file_access:F /T /C"
          
          if($UserID)
          {
              iex "icacls $Folder /grant contoso\$UserID:F /T /C"
          }

      } 
      while ($exitcode -ne 0)
    }
    # subinacl /subdirectories $folder /setowner=contoso\drs_gb_bsd_file_access
}

#Returns a list of site codes
function Get-SiteCodes
{
  Get-Config -Namespace SiteCode
}

# Returns a list of country codes
function Get-CountryCodes
{
  Get-Config -Namespace Country
}

# Resolves the OU for user placement based on country code and site code
function Get-RegionSpecificData
{
    param([String]$Type, [String]$CountryCode, [String]$SiteCode)

    if($Type -and $CountryCode -and $SiteCode)
    {
        Get-ConfigItem -Key ($CountryCode + "." + $SiteCode + "." + $Type)
    } 
}

function Set-RoamingProfile
{
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $User,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $CountryCode,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $SiteCode
    )

	Import-Module 'ActiveDirectory'

    $ProfilePath = Get-RegionSpecificData -Type "RoamingProfile" -CountryCode $CountryCode -SiteCode $SiteCode

    if($ProfilePath)
    {
        Set-ADUser $User -ProfilePath ($ProfilePath+ "\" + $User)
    }
}

function Set-HomeDrive
{
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$User,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CountryCode,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteCode
    )
    
	Import-Module 'ActiveDirectory'
	
    $HomeDrivePath = Get-RegionSpecificData -Type "HomeDrive" -CountryCode $CountryCode -SiteCode $SiteCode

    if($HomeDrivePath)
    {
        $HomeDirectory = ($HomeDrivePath + "\" + $User)
        
        # Create the directory and apply permissions
        if(!(Test-Path $HomeDirectory))
        {
            New-Item -Path $HomeDirectory -ItemType Directory
			
			$acl = Get-ACL $HomeDirectory
	        $acl.SetAccessRuleProtection($true,$false)
	        $acl.Access | % { $acl.RemoveAccessRuleAll($_) }
	        $acl.SetOwner([System.Security.Principal.NTAccount]($User))
	        $objUser = New-Object System.Security.Principal.NTAccount(("contoso\" + $User))
	        $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule ($objUser,"FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
	        $acl.AddAccessRule($objACE);
	        Set-ACL $HomeDirectory $acl
        }
		
		# Configure the AD account with the correct path
        Set-ADUser $User -HomeDirectory $HomeDirectory -HomeDrive (Get-ConfigItem Defaults.Users.HomeDriveLetter)
    }
}

function Out-Excel
{
  param($Path = "$env:temp\$(Get-Date -Format yyyyMMddHHmmss).csv")
  $input | Export-CSV -Path $Path -UseCulture -Encoding UTF8 -NoTypeInformation
  Invoke-Item -Path $Path
}



function Reload-Modules {
    # Refresh module list, in case a new module has been added
    Get-Module -Refresh -ListAvailable | Out-Null
    # Force a re-import of the currently imported modules
    Get-Module | % { Import-Module $_ -Force }
}

Export-ModuleMember *
