function Get-RandomString {
  <#
  .SYNOPSIS
  Generates a random string of a given length. 
  .DESCRIPTION
  Getnerates a random string using characters in the range 33 - 126 of the ASCII
  table. The length of the returned string is determined by the Length
  parameter.
  .EXAMPLE
  # Defaults to 10 characters
  Get-RandomString
  .EXAMPLE
  # Get a random string with 30 characters
  Get-RandomString -Length 30
  .EXAMPLE
  # Get a random string with only alpahnumeric characters
  Get-RandomString -AlphanumericOnly
  .PARAMETER Length
  The length of the returned string
  .PARAMETER AlphanumericOnly
  Causes the returned string to only contain characters in the range A-Z, a-z or 0-9.
  #>
  
  param ( 
		[int]$Length = 10,
		[switch]$AlphanumericOnly
		)
	
  # Get an object for random number generation
  $random = New-Object System.Random
  
  # Return a string of random characters of length $Length
  -join (1..$Length | foreach { 
		
		$char = ''
		
		do {
			$char = [char]$random.Next(33,126)
		} while($AlphanumericOnly -and (-not ($char -match "[a-zA-Z0-9]")))
		
		$char
	})
}
