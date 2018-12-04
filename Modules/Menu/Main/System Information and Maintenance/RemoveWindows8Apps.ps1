<#     
	.SYNOPSIS
		Remove Unwanted Windows 8.1 Apps (on this computer)
#>

# List of Applications that will be removed
$AppsList = "microsoft.windowscommunicationsapps","Microsoft.BingFinance",`
"Microsoft.BingMaps","Microsoft.BingWeather","Microsoft.XboxLIVEGames",`
"Microsoft.BingSports","Microsoft.BingNews","Microsoft.BingFoodAndDrink",`
"Microsoft.BingTravel","Microsoft.BingHealthAndFitness","Microsoft.Office.OneNote";

ForEach ($App in $AppsList)
{
	$Packages = Get-AppxPackage | Where-Object {$_.Name -eq $App}

	if ($Packages -ne $null)
	{
		Write-Host "Removing Appx Package: $App"

		foreach ($Package in $Packages)
		{
			Remove-AppxPackage -package $Package.PackageFullName
		}
	}


	else
	{
		Write-Host "Unable to find package: $App"
	}

	$ProvisionedPackage = Get-AppxProvisionedPackage -online | Where-Object {$_.displayName -eq $App}

	if ($ProvisionedPackage -ne $null)
	{
		Write-Host "Removing Appx Provisioned Package: $App"

		remove-AppxProvisionedPackage -online -packagename $ProvisionedPackage.PackageName
	}

	else
	{
		Write-Host "Unable to find provisioned package: $App"
	}

}
