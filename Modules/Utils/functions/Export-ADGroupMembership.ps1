<#
 .SYNOPSIS
 	Exports the member details of an AD group to a CSV file
 .DESCRIPTION
 	Takes a given group identity and queries AD for the members.
	The member details are then exported to a CSV file using the
	path provided.
 .PARAMETER GroupName
 	The name of the group
 .PARAMETER Path
 	The path to export the CSV to.
 .EXAMPLE
 	Export-ADGroupMembership -GroupName "Test Group" -Path "C:\test.csv"
#>

function Export-ADGroupMembership {
	param(
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$GroupName,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$Path
	)

	Get-ADGroup $GroupName -Properties Member | 
		Select-Object -ExpandProperty Member | 
		Get-ADUser |
		Select-Object samAccountname,givenName,surname | 
		Export-Csv $Path
}
