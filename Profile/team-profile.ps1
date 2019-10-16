# Lives at $PROFILE (Microsoft.PowerShell_profile.ps1) on each team machine.

# Run the user profile script from the OPS repository
# Do not remove this line
System.Profile

    


# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
