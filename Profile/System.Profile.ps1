<#
.SYNOPSIS
    Shared profile script: welcome banner plus weekly module/script update check against an internal PSGallery repository.

.DESCRIPTION
    Loaded from every team member's PowerShell profile. Once a week it compares installed modules and
    scripts against the internal repository and installs/uninstalls to match, handling the PowerShellGet v2
    prerequisite. The last check time is stored with the Config module.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

#Requires -Modules Config

@"
********************************************************************************
***               Welcome to the OPS PowerShell environment.                 ***
********************************************************************************
***                                                                          ***
*** If this is the first time you are running this, or you've rebuilt your   ***
*** PC, please run the menu command (type menu and <Enter>) and then enter   ***
*** option 1. to save your credentials.                                      ***
***                                                                          ***
********************************************************************************
"@

# Check for updates only if not checked for a week.
$last_check = Get-ConfigItem System.LastUpdateCheck
$date = Get-Date

if((-not $last_check) -or ($last_check -lt $date.AddDays(-7))) {

# Display update message
@"
Last update check was longer than a week ago. Checking for updates now.
NOTE: If you have installed modules and scripts from the PSGallery or other 
untrusted repository, you will be prompted to confirm you want to update.
"@

    $RepositoryName = "OPSAutomation"

    # Ensure PowerShellGet v2 is available
    $providers = Get-PackageProvider -Name PowerShellGet -ListAvailable |
        Where-Object { $_.Version.Major -eq 2}

    if(-not $providers) {

        try {
            Write-Verbose "An update to the PowerShellGet module is required"
            Find-Module -Name "PackageManagement","PowerShellGet" `
                -Repository $RepositoryName -ErrorAction Stop |
                Install-Module -Scope CurrentUser `
                    -Force -AllowClobber -ErrorAction Stop

            Write-Warning "An update has been installed that requires PowerShell to be restarted"
            Read-Host 'Press Enter to close...'
            exit

        } catch {
            Write-Error -Message "Unable to update PowerShellGet module. Some modules or scripts may not work correctly."
        }

    }

    # Compare local copies with remote
    $available,$installed = @()
    $available = Find-Module -Repository $RepositoryName
    $installed = Get-InstalledModule |
        Where-Object Repository -eq $RepositoryName
    $differences = Compare-Object `
        -ReferenceObject @($installed) `
        -DifferenceObject @($available) `
        -Property "Name","Version","Repository"
    
    Write-Output "Installing new modules"
    $differences | 
        Where-Object Sideindicator -eq "=>" |
        Foreach-Object {
            
            Install-Module -Name $_.Name `
                -Scope CurrentUser `
                -Repository $_.Repository `
                -RequiredVersion $_.Version `
                -AllowClobber `
                -AcceptLicense

        }

    Write-Output "Uninstalling redundant modules"
    $differences | 
        Where-Object Sideindicator -eq "<=" |
        Foreach-Object {
            
            Uninstall-Module -Name $_.Name `
                -RequiredVersion $_.Version `
                -Force

        }

    # Update scripts from all sources
    $available = Find-Script -Repository $RepositoryName
    $installed = Get-InstalledScript |
        Where-Object Repository -eq $RepositoryName
    $differences = Compare-Object `
        -ReferenceObject @($installed) `
        -DifferenceObject @($available) `
        -Property "Name","Version","Repository"
    
    Write-Output "Installing new scripts"
    $differences | 
        Where-Object Sideindicator -eq "=>" |
        Foreach-Object {
            
            Install-Script -Name $_.Name `
                -Scope CurrentUser `
                -Repository $_.Repository `
                -RequiredVersion $_.Version `
                -AcceptLicense `
                -Force

        }

    Write-Output "Uninstalling redundant scripts"
    $differences | 
        Where-Object Sideindicator -eq "<=" |
        Foreach-Object {
            
            Uninstall-Script -Name $_.Name `
                -RequiredVersion $_.Version `
                -Force

        }
    # Change the last update check date
    Set-ConfigItem -Key System.LastUpdateCheck -Value $date -Scope User
}
