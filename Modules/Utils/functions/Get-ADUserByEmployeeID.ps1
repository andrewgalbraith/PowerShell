<#
.SYNOPSIS
    Select a user from Active Directory by supplying an employee ID
.DESCRIPTION
    Given an employee ID, returns an AD user account object with the
    samAccountName that contains that ID.
.PARAMETER EmployeeID
    The 4 or 6 digit employee ID of the user to return
.PARAMETER Properties
    A list of property names to return (see the Get-ADUser Properties parameter)
.EXAMPLE
    Get-ADUserByEmployeeID -EmployeeID 123456
#>
function Get-ADUserByEmployeeID {
    param(
        [ValidateNotNullOrEmpty()]
        [String]$EmployeeID,
        [String[]]$Properties
    )

    if(-not $Properties) {
        $Properties = "*"
    }

    $filter = ("*" + $EmployeeId)
    Get-ADUser -Filter { samAccountName -like $filter } -Properties $Properties |
        Where-Object { $_.samAccountName -match "^\w\w$($EmployeeID)$" }
}
