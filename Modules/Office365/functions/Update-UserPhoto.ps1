function Update-UserPhoto {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $EmployeeID
    )

    Write-Verbose "Employee ID to process is $EmployeeID"

    if($EmployeeID -NotMatch "^(\d{4,6})$") {
        throw "An invalid employee ID was specified."
    }

    # Get the defaul photo location
    $PhotoLocation = Get-ConfigItem UserManagement.PhotoLocation
    
    # Get the image relating to the employee
    $ImagePath = Get-Item (Join-Path $PhotoLocation "*_$EmployeeID.jpg") | 
        Select-Object -ExpandProperty FullName
    Write-Verbose "`t- Image path is $ImagePath"

    # Create a resized version of the photo - overwrite. We have to do this
    # every time beacuse the photos are replaced every night.
    if($ImagePath) {
        Set-ImageSize -Image $ImagePath `
            -Destination (Split-Path $ImagePath) `
            -WidthPx 96 `
            -HeightPx 96 `
            -Overwrite
    } else {
        throw "Image not found for user: $EmployeeID."
    }

    # Find the user account in AD.
    
    $User = Get-ADUserByEmployeeID -EmployeeID $EmployeeID
    Write-Verbose "`t- User Principal name is $($User.UserPrincipalName)"
    
    # Update the photo in AD
    try {
        Write-Verbose "`t- Updating photo in AD for $($User.UserPrincipalName)"
        
        # Read the picture in as a byte array.
        $picture = [byte[]](Get-Content $ImagePath -Encoding byte)

        # Update the AD object
        Set-ADUser -Identity $User.samAccountName `
            -Replace @{thumbnailPhoto=$picture} | 
                Out-Null

    } catch {
        Write-Error "`t`t- Unable to update AD photo for $($User.UserPrincipalName)"
        Write-Error "`t`t- Message given was: $($_.Exception)"
    }

    # Update the photo in Office 365
    try {
        Write-Verbose "`t- Updating photo in Office 365 for $($User.UserPrincipalName)"
        Connect-ExchangeOnline
        Set-UserPhoto -Identity $User.UserPrincipalName `
            -PictureData ([System.IO.File]::ReadAllBytes($ImagePath)) `
            -Confirm:$false
    } catch {
        Write-Error "`t`t- Unable to update Office 365 photo for $($User.UserPrincipalName)"
        Write-Error "`t`t- Message given was: $($_.Exception)"
    }
}
